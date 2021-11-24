    //
    //  Document.swift
    //  DJ Set Analyzer
    //
    //  Created by Sebastiaan Hols on 22/11/2021.
    //

import UIKit
import AVFoundation
import ShazamKit

class Document: UIDocument {
    let analyzer = Analyzer()
    
    override func contents(forType typeName: String) throws -> Any {
            // Encode your document with an instance of NSData or NSFileWrapper
        return Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
            // Load your document from contents
        print("Opened file: \(fileURL)")
        analyzer.split(fileURL)
        analyzer.analyze(fileURL)
    }
    
}

