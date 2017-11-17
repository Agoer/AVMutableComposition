//
//  VideoPlayerVCEx.swift
//  MyAVMutableComposition
//
//  Created by knax on 11/16/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//

import AVFoundation
import UIKit
import MobileCoreServices

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
            videoMerge.videoAsset = AVAsset(url: info[UIImagePickerControllerMediaURL] as! URL)
            
            //add to array
            guard let videoAsset = videoMerge.videoAsset else {
                return
            }
            videoMerge.avAssetArray.append(videoAsset)
            
            videoMerge.videoAssetURL = extractVideoURLFromAsset(videoAsset)
            print("avAssetArray.count", videoMerge.avAssetArray.count)
            
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

