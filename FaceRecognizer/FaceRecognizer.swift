//
//  FaceRecognizer.swift
//  FaceRecognizer
//
//  Created by Lokesh on 18/03/24.
//

import UIKit

class FaceRecognizer{
    private var mIsInferenceQueueBusy = false
    private let mInferenceQueue = DispatchQueue(label: "org.tensorflow.lite.inferencequeue")
    private let mFaceDetector = MLKitFaceDetector()
    private let mImageRecognizer: ImageRecognizable
    private let onError: (String) -> Void
    private let onIdentified: (String) -> Void
    
    init?(onError: @escaping (String) -> Void, onIdentified: @escaping (String) -> Void){
        if let recognizer = ImageRecognizer(){
            mImageRecognizer = recognizer
        }else{
            return nil
        }
        self.onError = onError
        self.onIdentified = onIdentified
    }
    
    func registerFace(name: String, image: UIImage, onRegisted:@escaping (Bool) -> Void){
        mIsInferenceQueueBusy = true
        self.resizeImage(with: image){ resized in
            self.mFaceDetector.detectFace(resized) {[weak self] faces, pickedImage in
                guard let self = self else{return}
                if let face = faces.first{
                    onRegisted(self.mImageRecognizer.register(name: name, image: face))
                }
                mIsInferenceQueueBusy = false
            }
        }
    }
    
    func detectFacesContinuosly(with pixelBuffer: CVPixelBuffer){
        guard let actualImage = UIImage(pixelBuffer: pixelBuffer) else{return}
        self.detectFace(with: actualImage)
    }
    
    func detectFace(with image: UIImage){
        self.mIsInferenceQueueBusy = true
        mInferenceQueue.async {
            self.resizeImage(with: image){ resized in
                self.mFaceDetector.detectFace(resized) {[weak self] faces, pickedImage in
                    guard let self = self else {return}
                    if let face = faces.first{
                        let (name, distance) = self.mImageRecognizer.recognize(image: face)
                        if let distance = distance{
                            if distance < 0.75{
                                self.onIdentified(name)
                            }else{
                                self.onError("unknown")
                            }
                        }else{
                            self.onError(name)
                        }
                    }else{
                        self.onError("face not detected.")
                    }
                    self.mIsInferenceQueueBusy = false
                }
            }
        }
    }
    
    
    /// Updates the image view with a scaled version of the given image.
    private func resizeImage(with image: UIImage, completion:@escaping (UIImage) -> Void) {
        DispatchQueue.main.async{
            var scaledImageWidth: CGFloat = 0.0
            var scaledImageHeight: CGFloat = 0.0
            let isPortrait = UIApplication.shared.windows
                .first?
                .windowScene?
                .interfaceOrientation
                .isPortrait ?? false
            if isPortrait{
                scaledImageWidth = image.size.width//mLiveImage.bounds.size.width
                scaledImageHeight = image.size.height * scaledImageWidth / image.size.width
            }else{
                scaledImageWidth = image.size.width * scaledImageHeight / image.size.height
                scaledImageHeight = image.size.height//mLiveImage.bounds.size.height
            }
            DispatchQueue.global(qos: .userInitiated).async {
                // Scale image while maintaining aspect ratio so it displays better in the UIImageView.
                var scaledImage = image.scaledImage(
                    with: CGSize(width: scaledImageWidth, height: scaledImageHeight)
                )
                scaledImage = scaledImage ?? image
                completion(scaledImage!)
            }
        }
    }
}
