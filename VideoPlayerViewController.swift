//
//  VideoPlayerViewController.swift
//  MyAVMutableComposition
//
//  Created by knax on 11/3/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import AssetsLibrary
import Photos
import MobileCoreServices


class VideoPlayerViewController: UIViewController {


    var videoAsset: AVAsset?
    var videoAssetURL: URL?
    
    var avPlayer: AVPlayer?
    var avPlayerViewController = AVPlayerViewController()
    
    var avAssetArray = [AVAsset]()
    //request auth for library
    
    let VIDEO_HEIGHT = 480.0
    let VIDEO_WIDTH = 640.0
    
    
    @IBAction func getVideo(_ sender: Any) {
        getVideo()
    }
    
    
    @IBAction func playVideo(_ sender: Any) {
        playVideo()
    }
    
    @IBAction func mergeVideoAction(_ sender: Any) {
        
        mergeVideo(avAssetArray)
    }
    
    
    //playback the video using AVPlayer
    func playVideo(){
        
        guard let videoAssetURL = videoAssetURL else {
            return
        }
        avPlayer = AVPlayer(url: videoAssetURL)
        avPlayerViewController.player = self.avPlayer
      
        present(avPlayerViewController,animated: true) { () -> Void in
            
            self.avPlayerViewController.player?.play()
        }
    }
    
    func getVideo(){
        
        //check for auth
        PHPhotoLibrary.requestAuthorization({(status: PHAuthorizationStatus)-> Void in
            
            if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
                self.imagePickerFromVC(self, usingDelegate: self)
                
            } else {
                let alert = UIAlertController(title: "Unauthorized", message: "user authorized required for action", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                self.present(alert,animated: true,completion: nil)
            }
        })
    }
    
    
    //set imagepicker & save the video to video asset
    func imagePickerFromVC(_ viewController: UIViewController, usingDelegate delegate: (UINavigationControllerDelegate & UIImagePickerControllerDelegate)!){
        //check equipment
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) == false {
            let alert = UIAlertController(title: "ERROR", message: "Source type not available", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            present(alert,animated: true,completion: nil)
        }
        
        let imagePicker = UIImagePickerController()
        //set the source so image picker knows what system device interface to display
        imagePicker.sourceType = .savedPhotosAlbum
        
        //set the mediaType so image picker knows what type of media interface to display
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        
        imagePicker.delegate = delegate
        
        //display imagePicker to the user
        present(imagePicker,animated: true, completion: nil)
    }
    
    func extractVideoURLFromAsset(_ videoAsset: AVAsset?)-> URL {
        let videoURL = videoAsset?.value(forKey: "URL")
        return videoURL as! URL
    }
    
    func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        
        return instruction
    }
    
    

    
    func mergeVideo(_ assetsArray:[AVAsset]){
        let mainComposition = AVMutableVideoComposition()
        let mixComposition = AVMutableComposition()
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        var allVideoInstruction = [AVMutableVideoCompositionLayerInstruction]()
        
        var startDuration: CMTime = kCMTimeZero
        var copyOfAssetsArray = assetsArray
        
        for i in 0..<copyOfAssetsArray.count {
            let currentAsset:AVAsset = copyOfAssetsArray[i]
            
            guard let currentTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                              preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
                else {
                    return
            }
            
            do {
                try currentTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, currentAsset.duration),
                                                 of: currentAsset.tracks(withMediaType: AVMediaType.video)[0],
                                                 at: startDuration)
                let currentInstruction = videoCompositionInstructionForTrack(track: currentTrack, asset: currentAsset)
                currentInstruction.setOpacityRamp(fromStartOpacity: 0.0, toEndOpacity: 1.0,
                                              timeRange: CMTimeRangeMake(startDuration, CMTimeMake(1, 1)))
                
                if i != assetsArray.count - 1 {
                    
                    currentInstruction.setOpacityRamp(fromStartOpacity: 1.0,
                                                      toEndOpacity: 0.0,
                                                      timeRange: CMTimeRangeMake(CMTimeSubtract(CMTimeAdd(currentAsset.duration, startDuration),
                                                                                                CMTimeMake(1,1)), CMTimeMake(2,1)))
                }
                let transform = currentTrack.preferredTransform
                
                if orientationFromTransform(transform: transform).isPortrait {
                    let outputSize = CGSize(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
                    let horizontalRatio = CGFloat(outputSize.width) / currentTrack.naturalSize.width
                    
                    let verticalRatio = CGFloat(outputSize.height) / currentTrack.naturalSize.height
                    let scaleToFitRatio = max(horizontalRatio,verticalRatio)
                    let FirstAssetScaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
                    
                    if currentAsset.g_orientation == .landscapeLeft {
                        let rotation = CGAffineTransform(rotationAngle: .pi)
                        let translateToCenter = CGAffineTransform(translationX: CGFloat(VIDEO_WIDTH), y: CGFloat(VIDEO_HEIGHT))
                        let mixedTransform = rotation.concatenating(translateToCenter)
                        
                        currentInstruction.setTransform(currentTrack.preferredTransform.concatenating(FirstAssetScaleFactor).concatenating(mixedTransform), at: kCMTimeZero)
                        
                    } else {
                        currentInstruction.setTransform(currentTrack.preferredTransform.concatenating(FirstAssetScaleFactor), at: kCMTimeZero)
                    }
                }
                allVideoInstruction.append(currentInstruction)
                startDuration = CMTimeAdd(startDuration,currentAsset.duration)
                
            }
            catch {  }
            
        }
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero,startDuration)
        mainInstruction.layerInstructions = allVideoInstruction
        
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(1, 30)
        mainComposition.renderSize = CGSize(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
        
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: Date())
        
        let savePath = (documentDirectory as NSString).appendingPathComponent("mergeVideo-\(date).mp4")
        
        let url = NSURL(fileURLWithPath: savePath)
        
        
        guard let assetExporter = AVAssetExportSession(asset: mixComposition,presetName: AVAssetExportPresetHighestQuality) else { return }
        
        assetExporter.outputURL = url as URL
        assetExporter.outputFileType = AVFileType.mov
        assetExporter.shouldOptimizeForNetworkUse = true
        assetExporter.videoComposition = mainComposition
        
        //do the export
        assetExporter.exportAsynchronously {
            DispatchQueue.main.async {
                print("exporting")
                self.exportDidFinish(session: assetExporter)
                }
            }
        }
    
        
        
        func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool){
            var assetOrientation = UIImageOrientation.up

            var isPortrait = false
            if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
                assetOrientation = .right

                isPortrait = true
            } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
                assetOrientation = .left

                isPortrait = true
            } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
                assetOrientation = .up

            } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
                assetOrientation = .down
            }
            return (assetOrientation, isPortrait)
        }
    
    
    func exportDidFinish(session: AVAssetExportSession) {
        print("running exportDidFinish")
        if session.status == AVAssetExportSessionStatus.completed {
            guard let outputURL = session.outputURL else {
                print("could not set outputURL")
                return
            }
            
            
            //MARK: let library = ALAssetsLibrary()
            PHPhotoLibrary.shared().performChanges({
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = false
                
                //MARK: Create video file
                
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .video, fileURL:  outputURL, options: options)
                print("save to PhotoLib")
            }, completionHandler: { (success, error) in
                if !success {
                    print("Could not save video to photo library: ",error?.localizedDescription ?? "error code not found: SaveToPhotoLibrary")
                    return
                }
                print("Ⓜ️save video to PhotosAlbum")
                
            }
            )}
        
    }
    
}
    
    
    
    

    
    //set delegate
extension AVAsset {
    var g_size: CGSize {
        return tracks(withMediaType: AVMediaType.video).first?.naturalSize ?? .zero
    }
    var g_orientation: UIInterfaceOrientation {
        guard let transform = tracks(withMediaType: AVMediaType.video).first?.preferredTransform else {
            return .portrait
        }
        switch (transform.tx,transform.ty) {
        case (0,0):
            return .landscapeRight
        case (g_size.width, g_size.height):
            return .landscapeLeft
        case (0, g_size.width):
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
}

extension VideoPlayerViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]){
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        if mediaType == kUTTypeMovie {
            
            //create the asset from URL and assign to videoAsset property
            videoAsset = AVAsset(url: info[UIImagePickerControllerMediaURL] as! URL)
            
            //add to array
            guard let videoAsset = videoAsset else {
                return
            }
            avAssetArray.append(videoAsset)
          
            videoAssetURL = extractVideoURLFromAsset(videoAsset)
              print("avAssetArray.count", avAssetArray.count)
            
            dismiss(animated: true, completion: nil)
            let alert = UIAlertController(title: "Done", message: "asset loaded", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
        } else {
            dismiss(animated: true, completion: nil)
            let alert = UIAlertController(title: "failed", message: "asset not loaded", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            present(alert, animated: true, completion: nil)
        }
    }
}
extension VideoPlayerViewController: UINavigationControllerDelegate {
    
}

