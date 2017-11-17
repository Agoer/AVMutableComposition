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

    let videoMerge = VideoMerge()

    var avPlayer: AVPlayer?
    var avPlayerViewController = AVPlayerViewController()
    

    
    @IBAction func getVideo(_ sender: Any) {
        getVideo()
    }
    
    
    @IBAction func playVideo(_ sender: Any) {
        playVideo()
    }
    
    @IBAction func mergeVideoAction(_ sender: Any) {
        
        videoMerge.mergeVideo(videoMerge.avAssetArray)
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
    
    
    //playback the video using AVPlayer
    func playVideo(){
        
        guard let videoAssetURL = videoMerge.videoAssetURL else {
            return
        }
        avPlayer = AVPlayer(url: videoAssetURL)
        avPlayerViewController.player = self.avPlayer
      
        present(avPlayerViewController,animated: true) { () -> Void in
            
            self.avPlayerViewController.player?.play()
        }
    }
    //set imagepicker source type & save its target as an asset
    func imagePickerFromVC(_ viewController: UIViewController, usingDelegate delegate: UINavigationControllerDelegate & UIImagePickerControllerDelegate){
        //check equipment
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) == false {
            
            let alert = UIAlertController(title: "ERROR", message: "Source type not available", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            present(alert,animated: true,completion: nil)
        }
        
        let imagePicker = UIImagePickerController()
        //set the source so image picker knows what system device interface to display
        imagePicker.sourceType = .savedPhotosAlbum
        
        //set the mediaType so image picker knows which media interface to display
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        
        imagePicker.allowsEditing = true
        
        //implement delegate protocols
        imagePicker.delegate = delegate
        
        //display system default imagePicker to the user
        present(imagePicker,animated: true, completion: nil)
    }
    
    func extractVideoURLFromAsset(_ videoAsset: AVAsset?)-> URL {
        let videoURL = videoAsset?.value(forKey: "URL")
        return videoURL as! URL
    }
  
    
}

 
