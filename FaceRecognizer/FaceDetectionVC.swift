//
//  ViewController.swift
//  FaceRecognizer
//
//  Created by Lokesh on 13/03/24.
//

import UIKit
import Vision
import VideoToolbox

class FaceDetectionVC: UIViewController {

    @IBOutlet weak var mVideoPreview: PreviewView!
    @IBOutlet weak var mDetectedFace: UIImageView!
    @IBOutlet weak var mLiveImage: UIImageView!
    @IBOutlet weak var mMatchLabel: UILabel!
    
    var mSquareLayer = CALayer()
    let label = UILabel()
    var takeInitialReference = false
    var startDetecting = false
    private var mPreviousInferenceTimeMs = Date.distantPast.timeIntervalSince1970 * 1000
    private let mDelayBetweenInferencesMs = 1000.0
    private var mFaceDrawings: [CAShapeLayer] = []
    private var mCropedDrawings: [CAShapeLayer] = []
    private var mRegisteredUserCount = 0
    
    
    private lazy var cameraFeedManager = CameraFeedManager(previewView: mVideoPreview)
    private lazy var mRecognizer = FaceRecognizer(onError: updateUI, onIdentified: updateUI)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraFeedManager.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      cameraFeedManager.checkCameraConfigurationAndStartSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)

      cameraFeedManager.stopSession()
    }

    @IBAction func onTapOfAddImage(_ sender: UIButton) {
        self.takeInitialReference = true
    }
    
    @IBAction func onTapOfDetect(_ sender: UIButton) {
        self.startDetecting = true
    }
    
    /// Updates the image view with a scaled version of the given image.
    private func updateImageView(with image: UIImage) {
//        let orientation = UIApplication.shared.statusBarOrientation
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
        weak var weakSelf = self
        DispatchQueue.global(qos: .userInitiated).async {
            // Scale image while maintaining aspect ratio so it displays better in the UIImageView.
            var scaledImage = image.scaledImage(
                with: CGSize(width: scaledImageWidth, height: scaledImageHeight)
            )
            scaledImage = scaledImage ?? image
            guard let finalImage = scaledImage else { return }
            DispatchQueue.main.async {
                weakSelf?.mLiveImage.image = finalImage
            }
        }
    }
    
    func updateUI(_ msg: String){
        mMatchLabel.text = msg
    }
    
}


// MARK: CameraFeedManagerDelegate Methods
extension FaceDetectionVC: CameraFeedManagerDelegate {
    
    func didOutput(pixelBuffer: CVPixelBuffer) {
        // Make sure the model will not run too often, making the results changing quickly and hard to
        // read.

        let currentTimeMs = Date().timeIntervalSince1970 * 1000
        guard (currentTimeMs - mPreviousInferenceTimeMs) >= mDelayBetweenInferencesMs else { return }
        mPreviousInferenceTimeMs = currentTimeMs
        guard let actualImage = UIImage(pixelBuffer: pixelBuffer) else{return}
        DispatchQueue.main.async{
            self.mLiveImage.image = actualImage
        }
        if takeInitialReference{
            self.mRegisteredUserCount += 1
            mRecognizer?.registerFace(name: "User \(self.mRegisteredUserCount)", image: actualImage, onRegisted: { registed in
                self.mDetectedFace.image = actualImage
                self.updateUI("Registered")
            })
            takeInitialReference = false
        }else{
//            if startDetecting{
                mRecognizer?.detectFacesContinuosly(with: pixelBuffer)
//                startDetecting = false
//            }
        }
    }
    
    // MARK: Session Handling Alerts
    func sessionRunTimeErrorOccurred() {
        // Handles session run time error by updating the UI and providing a button if session can be manually resumed.
//        self.resumeButton.isHidden = false
    }
    
    func sessionWasInterrupted(canResumeManually resumeManually: Bool) {
        // Updates the UI when session is interrupted.
//        if resumeManually {
//            self.resumeButton.isHidden = false
//        } else {
//            self.cameraUnavailableLabel.isHidden = false
//        }
    }
    
    func sessionInterruptionEnded() {
        // Updates UI once session interruption has ended.
//        if !self.cameraUnavailableLabel.isHidden {
//            self.cameraUnavailableLabel.isHidden = true
//        }
//        
//        if !self.resumeButton.isHidden {
//            self.resumeButton.isHidden = true
//        }
    }
    
    func presentVideoConfigurationErrorAlert() {
        let alertController = UIAlertController(
            title: "Configuration Failed", message: "Configuration of camera has failed.",
            preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func presentCameraPermissionsDeniedAlert() {
        let alertController = UIAlertController(
            title: "Camera Permissions Denied",
            message:
                "Camera permissions have been denied for this app. You can change this by going to Settings",
            preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
            
            UIApplication.shared.open(
                URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        
        present(alertController, animated: true, completion: nil)
        
    }
}
