    //
    //  Analyzer.swift
    //  DJ Set Analyzer
    //
    //  Created by Sebastiaan Hols on 23/11/2021.
    //

import Foundation
import ShazamKit
import AVFoundation
import UIKit

class Analyzer : NSObject, SHSessionDelegate {
    
    var urls = [URL]()
    
    var trackSegments = 0
    
    var active = true
    
    var refreshTable : ()->Void = {}
    var updateProgress : (_ : Progress)->Void = { _ in }
    
    var hits = [SHMatchedMediaItem]()
    
    func reset () {
        urls = [URL]()
        active = false
        hits = [SHMatchedMediaItem]()
        trackSegments = 0
    }
    
    func run (_ url: URL) {
        
        let asset = AVAsset(url: url)
        print("file:\(url)")
        let duration = CMTimeGetSeconds(asset.duration)
        print("duration:\(duration)")
        trackSegments = (Int(duration) - (Int(duration) % 180)) / 180
        print("segments:\(trackSegments)")
        
        guard trackSegments > 1 else {
            print("Could not get segments")
            return
        }
        
        for index in 0...trackSegments {
            guard active else {
                break
            }
            splitAudio(asset: asset, segment: index)
        }
        
        func splitAudio(asset: AVAsset, segment: Int) {
                // Create a new AVAssetExportSession
            let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)!
                // Set the output file type to m4a
            exporter.outputFileType = AVFileType.m4a
                // Create our time range for exporting
            let startTime = CMTimeMake(value: Int64(5 * 60 * segment), timescale: 1)
            let endTime = CMTimeMake(value: Int64(5 * 60 * (segment+1)), timescale: 1)
                // Set the time range for our export session
            exporter.timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
                // Set the output file path
            let outputFileName = NSUUID().uuidString
            let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("m4a")!)
            let outputUrl = URL(fileURLWithPath: outputFilePath)
            
            exporter.outputURL = outputUrl
                // Do the actual exporting
            exporter.exportAsynchronously(completionHandler: { [self] in
                switch exporter.status {
                    case AVAssetExportSession.Status.failed:
                        print("Export failed.")
                    case AVAssetExportSession.Status.completed:
                        print("Export complete.")
                        urls.append(outputUrl)
                        DispatchQueue.main.async {
                            self.updateProgress(Progress(state: .splitting, amount: Float(urls.count) / Float(trackSegments)))
                        }
                    default:
                        print("Export in progress")
                }
                if trackSegments == urls.count {
                    self.analyzeAudioSegments()
                }
            })
            return
        }
    }

    func analyze (_ url: URL){
            // Set up the session.
        let session = SHSession()
        session.delegate = self
        let generator = SHSignatureGenerator()
            // Create a signature from the captured audio buffer.
        guard let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else {
            return
        }
        
        do {
            
            let audioFile = try AVAudioFile(forReading: url)
            
            guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: 44100 * 10),
                  let outputBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: 44100 * 10) else {
                      return
                  }
                // Read file into buffer
            let inputBlock : AVAudioConverterInputBlock = { inNumPackets, outStatus in
                do {
                    try audioFile.read(into: inputBuffer)
                    outStatus.pointee = .haveData
                    return inputBuffer
                } catch {
                    if audioFile.framePosition >= audioFile.length {
                        outStatus.pointee = .endOfStream
                        return nil
                    } else {
                        outStatus.pointee = .noDataNow
                        return nil
                    }
                }
            }
            
            guard let converter = AVAudioConverter(from: audioFile.processingFormat, to: audioFormat) else {
                return
            }
            
            let status = converter.convert(to: outputBuffer, error: nil, withInputFrom: inputBlock)
            
            if status == .error || status == .endOfStream {
                return
            }
            
            try generator.append(outputBuffer, at: nil)
            
            if status == .inputRanDry {
                return
            }
            
        } catch {
            print(error)
        }
        
            // create signature
        let signature = generator.signature()
            // try to match
        session.match(signature)
    }
    
    func analyzeAudioSegments (){
        guard !urls.isEmpty else {
            DispatchQueue.main.async {
                self.updateProgress(Progress(state: .done, amount: 0.0))
            }
            return
        }
        analyze(urls.removeFirst())
        DispatchQueue.main.async {
            self.updateProgress(Progress(state: .analyzing, amount: 1 - Float(self.urls.count) / Float(self.trackSegments)))
        }
    }
    
    // The delegate method that the session calls when matching a reference item.
    func session(_ session: SHSession, didFind match: SHMatch) {
            // Do something with the matched results.
        match.mediaItems.forEach { item in
            hits.append(item)
            print(item.title!)
            print("@\(item.matchOffset)")
            DispatchQueue.main.async {
                self.refreshTable()
            }
        }
        self.analyzeAudioSegments()
    }
    
        // The delegate method that the session calls when there is no match.
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
            // No match found.
        print("No match")
        self.analyzeAudioSegments()
    }
}
