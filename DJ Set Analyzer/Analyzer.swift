//
//  Analyzer.swift
//  DJ Set Analyzer
//
//  Created by Sebastiaan Hols on 23/11/2021.
//

import Foundation
import ShazamKit


class Analyzer : NSObject, SHSessionDelegate {
        // Set up the session.
    let session = SHSession()
    
    override init (){
        super.init()
        session.delegate = self
    }
    
        // Create a signature from the captured audio buffer.
    let signatureGenerator = SHSignatureGenerator()
    
    func analyze (_ buffer: AVAudioPCMBuffer){
        try! signatureGenerator.append(buffer, at: nil)
        let signature = signatureGenerator.signature()
        
            // Check for a match.
        session.match(signature)
    }
    
        // The delegate method that the session calls when matching a reference item.
    func session(_ session: SHSession, didFind match: SHMatch) {
            // Do something with the matched results.
    }
    
        // The delegate method that the session calls when there is no match.
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
            // No match found.
    }
}
