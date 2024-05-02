//
//  ImageClassifiier.swift
//  FaceRecognizer
//
//  Created by Lokesh on 14/03/24.
//

import Foundation
import TensorFlowLite
import Accelerate
protocol ImageRecognizable{
    func register(name: String, image: UIImage) -> Bool
    func register(name: String, buffer: CVPixelBuffer) -> Bool
    func recognize(image: UIImage) -> (String,Float?)
    func recognize(buffer: CVPixelBuffer) -> (String,Float?)
}

class ImageRecognizer{
    
    private let mInterpreter: Interpreter
    private let mIsQuantized = false
    private var registered : [String: FlatArray<Float32>] = [:]
    private let INPUT_HEIGHT = 112
    
    init?(){
        // Getting model path
        guard
            let modelPath = Bundle.main.path(forResource: "mobile_face_net", ofType: "tflite")
        else {
            print("Failed to load the model.")
            return nil
        }
        
        do {
            // Initialize an interpreter with the model.
            mInterpreter = try Interpreter(modelPath: modelPath)
            
        } catch  {
            print("Error initializing")
            print(error)
            return nil
        }
    }
}
extension ImageRecognizer: ImageRecognizable{
    func register(name: String, image: UIImage) -> Bool{
        if let pixelBuffer = image.pixelBuffer(){
            return register(name: name, buffer: pixelBuffer)
        }
        return false
    }
    
    func register(name: String, buffer: CVPixelBuffer) -> Bool{
        if let embedding = interpretEmbeddings(buffer: buffer){
            registered[name] = embedding
            return true
        }
        return false
    }
    func recognize(image: UIImage) -> (String,Float?){
        if let pixelBuffer = image.pixelBuffer(){
            return recognize(buffer: pixelBuffer)
        }
        return ("unable to convert to pixel buffer.", nil)
    }
    func recognize(buffer: CVPixelBuffer) -> (String,Float?){
        if let embedding = interpretEmbeddings(buffer: buffer){
            if let (name, distance) = findNearest(to: embedding){
                return (name,distance)
            }
            return ("unknown",nil)
        }
        return ("Failed to construct embeddings",nil)
    }
}
// MARK: Recognizing logic
extension ImageRecognizer{
    
    private func findNearest(to matchEmbedding: FlatArray<Float32>) -> (String, Float)?{
        var nearest: (name: String, distance: Float)?
        for (name, knownEmbedding) in registered{
            var distance: Float = 0
            for i in 0..<matchEmbedding.count{
                let diff = matchEmbedding[i] - knownEmbedding[i]
                distance += diff * diff
            }
            let calculatedDistance = sqrt(distance)
            if nearest == nil || calculatedDistance < nearest!.distance{
                nearest = (name, calculatedDistance)
            }
        }
        return nearest
        
        
    }
    
    /// Preprocesses given rectangle image to be `Data` of desired size by cropping and resizing it.
      ///
      /// - Parameters:
      ///   - of: Input image to crop and resize.
      ///   - from: Target area to be cropped and resized.
      /// - Returns: The cropped and resized image. `nil` if it can not be processed.
      private func preprocess(of pixelBuffer: CVPixelBuffer, from targetSquare: CGRect) -> Data? {
        let sourcePixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        assert(sourcePixelFormat == kCVPixelFormatType_32BGRA)

        // Resize `targetSquare` of input image to `modelSize`.
        let modelSize = CGSize(width: INPUT_HEIGHT, height: INPUT_HEIGHT)
        guard let thumbnail = pixelBuffer.resize(from: targetSquare, to: modelSize)
        else {
          return nil
        }

        // Remove the alpha component from the image buffer to get the initialized `Data`.
        guard let inputData = thumbnail.rgbData(isModelQuantized: mIsQuantized)
        else {
          os_log("Failed to convert the image buffer to RGB data.", type: .error)
          return nil
        }

        return inputData
      }
    
    private func interpretEmbeddings(buffer: CVPixelBuffer) -> FlatArray<Float32>?{
        do {
            guard let inputData = preprocess(of: buffer, from: CGRect(x: 0, y: 0, width: buffer.size.width, height: buffer.size.height)) else {
                print("Input data conversion error")
                return nil
            }
            // Allocate memory for the model's input `Tensor`s.
            try mInterpreter.allocateTensors()
            
            // Copy the input data to the input `Tensor`.
            try self.mInterpreter.copy(inputData, toInputAt: 0)
            
            // Run inference by invoking the `Interpreter`.
            try self.mInterpreter.invoke()
            
            // Get the output `Tensor`
            let outputTensor = try self.mInterpreter.output(at: 0)
            return FlatArray<Float32>(tensor: outputTensor)
        } catch  {
            print("Error interpretting")
            print(error)
            return nil
        }
    }
    
    
}
