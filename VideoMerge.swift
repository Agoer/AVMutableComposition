//
//  VideoMerge.swift
//  MyAVMutableComposition
//
//  Created by knax on 11/16/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//


import AVFoundation
import Photos



class VideoMerge: NSObject {
    
    var videoAsset: AVAsset?
    var videoAssetURL: URL?
    var avAssetArray = [AVAsset]()
    
    
    let VIDEO_HEIGHT = 200.0
    let VIDEO_WIDTH = 300.0
    
    func mergeVideo(_ assetsArray:[AVAsset]){
        
        let mainComposition = AVMutableVideoComposition()
        let mixComposition = AVMutableComposition()
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        var allVideoInstruction = [AVMutableVideoCompositionLayerInstruction]()
        
        var startDuration: CMTime = kCMTimeZero
        //var copyOfAssetsArray = assetsArray
        
        for i in 0..<assetsArray.count {
            let currentAsset:AVAsset = assetsArray[i]
            
            guard let currentTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                    preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
                else {   return  }
            
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
                        print("is landscape")
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
        //mainComposition.renderSize = CGSize(width: 300.0, height: 300.0)
          mainComposition.renderSize = CGSize(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
        
        //mainComposition.renderSize = CGSize(width: VIDEO_WIDTH, height: VIDEO_HEIGHT)
        
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
    
    
    func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        
        return instruction
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
        
            videoAssetURL = outputURL
            
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
                self.avAssetArray.removeAll()
                
                }
            )}
        }
}
