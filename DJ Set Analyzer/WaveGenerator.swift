//
//  WaveGenerator.swift
//  DJ Set Analyzer
//
//  Created by Sebastiaan Hols on 28/11/2021.
//

import AVFoundation
import CoreGraphics
import Foundation
import UIKit

class WaveGenerator {
    private func readBuffer(_ audioUrl: URL) -> UnsafeBufferPointer<Float> {
        let file = try! AVAudioFile(forReading: audioUrl)
        
        let audioFormat = file.processingFormat
        let audioFrameCount = UInt32(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)
        else { return UnsafeBufferPointer<Float>(_empty: ()) }
        do {
            try file.read(into: buffer)
        } catch {
            print(error)
        }
        
        let floatArray = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength))
        
        return floatArray
    }
    
    private func generateWaveImage(
        _ samples: UnsafeBufferPointer<Float>,
        _ imageSize: CGSize,
        _ strokeColor: UIColor,
        _ backgroundColor: UIColor
    ) -> UIImage? {
        let drawingRect = CGRect(origin: .zero, size: imageSize)
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        
        let middleY = imageSize.height / 2
        
        guard let context: CGContext = UIGraphicsGetCurrentContext() else { return nil }
        
        context.setFillColor(backgroundColor.cgColor)
        context.setAlpha(1.0)
        context.fill(drawingRect)
        context.setLineWidth(0.25)
        
        let max: CGFloat = CGFloat(samples.max() ?? 0)
        let heightNormalizationFactor = imageSize.height / max / 2
        let widthNormalizationFactor = imageSize.width / CGFloat(samples.count)
        for index in 0 ..< samples.count {
            let pixel = CGFloat(samples[index]) * heightNormalizationFactor
            
            let x = CGFloat(index) * widthNormalizationFactor
            
            context.move(to: CGPoint(x: x, y: middleY - pixel))
            context.addLine(to: CGPoint(x: x, y: middleY + pixel))
            
            context.setStrokeColor(strokeColor.cgColor)
            context.strokePath()
        }
        guard let soundWaveImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        
        UIGraphicsEndImageContext()
        return soundWaveImage
    }
    
    func generateWaveImage(from audioUrl: URL, in imageSize: CGSize) -> UIImage? {
        let samples = readBuffer(audioUrl)
        let img = generateWaveImage(samples, imageSize, UIColor.blue, UIColor.white)
        return img
    }
}
