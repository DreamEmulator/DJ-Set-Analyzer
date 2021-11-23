    //
    //  AudioConverter.swift
    //  DJ Set Analyzer
    //
    //  Created by Sebastiaan Hols on 23/11/2021.
    //

import Foundation
import AVFoundation

func data_AudioFile_ReadProc(_ inClientData: UnsafeMutableRawPointer, _ inPosition: Int64, _ requestCount: UInt32, _ buffer: UnsafeMutableRawPointer, _ actualCount: UnsafeMutablePointer<UInt32>) -> OSStatus {
    let data = inClientData.assumingMemoryBound(to: Data.self).pointee
    let bufferPointer = UnsafeMutableRawBufferPointer(start: buffer, count: Int(requestCount))
    let copied = data.copyBytes(to: bufferPointer, from: Int(inPosition) ..< Int(inPosition) + Int(requestCount))
    actualCount.pointee = UInt32(copied)
    return noErr
}

func data_AudioFile_GetSizeProc(_ inClientData: UnsafeMutableRawPointer) -> Int64 {
    let data = inClientData.assumingMemoryBound(to: Data.self).pointee
    return Int64(data.count)
}

extension Data {
    func convertedTo(_ format: AVAudioFormat) -> AVAudioPCMBuffer? {
        var data = self
        
        var af: AudioFileID? = nil
        var status = AudioFileOpenWithCallbacks(&data, data_AudioFile_ReadProc, nil, data_AudioFile_GetSizeProc(_:), nil, 0, &af)
        guard status == noErr, af != nil else {
            return nil
        }
        
        defer {
            AudioFileClose(af!)
        }
        
        var eaf: ExtAudioFileRef? = nil
        status = ExtAudioFileWrapAudioFileID(af!, false, &eaf)
        guard status == noErr, eaf != nil else {
            return nil
        }
        
        defer {
            ExtAudioFileDispose(eaf!)
        }
        
        var clientFormat = format.streamDescription.pointee
        status = ExtAudioFileSetProperty(eaf!, kExtAudioFileProperty_ClientDataFormat, UInt32(MemoryLayout.size(ofValue: clientFormat)), &clientFormat)
        guard status == noErr else {
            return nil
        }
        
        if let channelLayout = format.channelLayout {
            var clientChannelLayout = channelLayout.layout.pointee
            status = ExtAudioFileSetProperty(eaf!, kExtAudioFileProperty_ClientChannelLayout, UInt32(MemoryLayout.size(ofValue: clientChannelLayout)), &clientChannelLayout)
            guard status == noErr else {
                return nil
            }
        }
        
        var frameLength: Int64 = 0
        var propertySize: UInt32 = UInt32(MemoryLayout.size(ofValue: frameLength))
        status = ExtAudioFileGetProperty(eaf!, kExtAudioFileProperty_FileLengthFrames, &propertySize, &frameLength)
        guard status == noErr else {
            return nil
        }
        
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameLength)) else {
            return nil
        }
        
        let bufferSizeFrames = 512
        let bufferSizeBytes = Int(format.streamDescription.pointee.mBytesPerFrame) * bufferSizeFrames
        let numBuffers = format.isInterleaved ? 1 : Int(format.channelCount)
        let numInterleavedChannels = format.isInterleaved ? Int(format.channelCount) : 1
        let audioBufferList = AudioBufferList.allocate(maximumBuffers: numBuffers)
        for i in 0 ..< numBuffers {
            audioBufferList[i] = AudioBuffer(mNumberChannels: UInt32(numInterleavedChannels), mDataByteSize: UInt32(bufferSizeBytes), mData: malloc(bufferSizeBytes))
        }
        
        defer {
            for buffer in audioBufferList {
                free(buffer.mData)
            }
            free(audioBufferList.unsafeMutablePointer)
        }
        
        while true {
            var frameCount: UInt32 = UInt32(bufferSizeFrames)
            status = ExtAudioFileRead(eaf!, &frameCount, audioBufferList.unsafeMutablePointer)
            guard status == noErr else {
                return nil
            }
            
            if frameCount == 0 {
                break
            }
            
            let src = audioBufferList
            let dst = UnsafeMutableAudioBufferListPointer(pcmBuffer.mutableAudioBufferList)
            
            if src.count != dst.count {
                return nil
            }
            
            for i in 0 ..< src.count {
                let srcBuf = src[i]
                let dstBuf = dst[i]
                memcpy(dstBuf.mData?.advanced(by: Int(dstBuf.mDataByteSize)), srcBuf.mData, Int(srcBuf.mDataByteSize))
            }
            
            pcmBuffer.frameLength += frameCount
        }
        
        return pcmBuffer
    }
}
