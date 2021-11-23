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
        // Set up the session.
    let session = SHSession()
    let generator = SHSignatureGenerator()
    
    override init (){
        super.init()
        session.delegate = self
    }
    
    
    func analyze (_ url: URL){
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
    
        // The delegate method that the session calls when matching a reference item.
    func session(_ session: SHSession, didFind match: SHMatch) {
            // Do something with the matched results.
        match.mediaItems.forEach { item in
            item.songs.forEach { song in
                print(song)
            }
        }
    
    }
    
        // The delegate method that the session calls when there is no match.
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
            // No match found.
        print("Did not find match")
    }
}
