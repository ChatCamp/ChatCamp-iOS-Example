//
//  ImagePreviewViewController.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 16/05/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit

class ImagePreviewViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var image: UIImage!
    
    override func viewDidLoad() {
        scrollView.maximumZoomScale = 2.0
        scrollView.contentSize = imageView.frame.size
        scrollView.delegate = self
        imageView.image = image
    }
}

extension ImagePreviewViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        
    }
}
