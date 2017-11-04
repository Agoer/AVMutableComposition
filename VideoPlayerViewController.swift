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
    //request auth for library
    
    
    
    @IBAction func getVideo(_ sender: Any) {
        getVideo()
    }
    
    
    @IBAction func playVideo(_ sender: Any) {
        playVideo()
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
                self.imagePickerFromVC(self,usingDelegate:self)
                
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
        
 }
    
    //set delegate




extension VideoPlayerViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]){
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        if mediaType == kUTTypeMovie {
            
            //create the asset from URL and assign to videoAsset property
            videoAsset = AVAsset(url: info[UIImagePickerControllerMediaURL] as! URL)
            
            videoAssetURL = extractVideoURLFromAsset(videoAsset)
            
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











