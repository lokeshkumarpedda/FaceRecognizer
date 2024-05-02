
<div align="center">

# Face Recognition

</div>

## Problem Statement
Detect faces without using any pre-trained models.
1. Register multiple faces.
2. Detect a face and recognize it with pre-registered faces.

## Solution
According to this [article](https://medium.com/@estebanuri/real-time-face-recognition-with-android-tensorflow-lite-14e9c6cc53a5), We have to detect the face from given input and crop it then process it for image recognition<br>
Problem statement can be divided into 3 stages
### Stage 1: Detect a Face and crop it
For detecting a face using apple vision framework is a way to go but croping has an open issue.<br>
Mentioned in this stack overflow [post](https://stackoverflow.com/questions/58288763/how-to-convert-boundingbox-from-vnrequest-to-cvpixelbuffer-coordinate).<br>
So to avoid this problem i used GoogleMLKit/FaceDetection to detect face.


### Stage 2: Register the cropped face

Once we get the face i used tensorflow model to create FlatArray for comparision as mention in this [article](https://medium.com/@estebanuri/real-time-face-recognition-with-android-tensorflow-lite-14e9c6cc53a5).<br>
Storing this Flat Array with respective user so it can be used for comparision in the future

### Stage 3: Detect the face from Registered faces

With new faces we detect i will create flat array for new faces and compare them with existing dataset of flat array.<br>
Using below logic calculate nearest distance between 2 images using L2 Normalization, if distance < 0.75 then considering its a match.
```swift
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
```
## Environment
Xcode 15.0<br>
Swift <br>
[GoogleMLKit/FaceDetection](https://developers.google.com/ml-kit/vision/face-detection/ios) <br>
[TensorFlowLiteSwift](https://cocoapods.org/pods/TensorFlowLiteSwift)
