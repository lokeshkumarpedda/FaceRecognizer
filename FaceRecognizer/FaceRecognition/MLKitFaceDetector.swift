//
//  MLKitFaceDetector.swift
//  FaceRecognizer
//
//  Created by Lokesh on 13/03/24.
//

import Foundation
import MLKitVision
import MLKitFaceDetection
import AVFoundation
import CoreMedia

class MLKitFaceDetector {
    private var faceDetector: FaceDetector?
    
    
    func setupFaceDetection() {
        let options = FaceDetectorOptions()
        options.performanceMode = .accurate
        options.landmarkMode = .all
        options.classificationMode = .all

        // Real-time contour detection of multiple faces
         options.contourMode = .all
        
        self.faceDetector = FaceDetector.faceDetector(options: options)
    }
    
    func detectFace(using pixelBuffer: CVPixelBuffer, completion: @escaping(_ faces: [UIImage],_ pickedImage: UIImage) -> Void) {
        let ciimage: CIImage = CIImage(cvImageBuffer: pixelBuffer)
        let ciContext = CIContext()
        guard let cgImage: CGImage = ciContext.createCGImage(ciimage, from: ciimage.extent) else {
            // end of measure
            return
        }
        let uiImage: UIImage = UIImage(cgImage: cgImage)
        // predict!
        self.detectFace(uiImage) { face, pickedImage in
            completion(face, pickedImage)
        }
    }
    
    func detectFace(_ pickedImage: UIImage, completion: @escaping(_ faces: [UIImage],_ pickedImage: UIImage) -> Void) {
        setupFaceDetection()
        let visionImage = VisionImage (image: pickedImage)
        visionImage.orientation = pickedImage.imageOrientation
        self.faceDetector?.process (visionImage) { faces, error in
            
            guard let faces = faces,
                  !faces.isEmpty,
                  faces.count >= 1
            else {
                completion([], pickedImage)
                return
            }
            print(faces.count)
            var faceImages = [UIImage]()
            for face in faces{
                guard let cgImage = pickedImage.cgImage?.cropping(to: face.frame) else {
                    continue
                }
                faceImages.append(UIImage(cgImage: cgImage))
            }
            completion(faceImages, pickedImage)
        }
    }
    
}
