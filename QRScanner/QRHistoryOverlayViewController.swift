//
//  QRHistoryOverlayViewController.swift
//  QRScanner
//
//  Created by Charles Thierry on 10/07/15.
//  Copyright (c) 2015 Weemo, Inc. All rights reserved.
//

import UIKit

class QRHistoryOverlayViewController: UIViewController {
	@IBOutlet var qrstring: UILabel!
	@IBOutlet var image: UIImageView!
	@IBOutlet var favorite: UIButton!
	@IBOutlet var launch: UIButton!
	
	var historyToDisplay: HistoryEntry!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		qrstring.userInteractionEnabled = false
		self.configureDisplay()
		self.favorite.selected = history.isAlreadySaved(self.historyToDisplay)
		// Do any additional setup after loading the view.
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func iOS7Mode() {
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			self.qrstring.backgroundColor = UIColor(white: 0.22, alpha: 0.6)
			self.launch.backgroundColor = UIColor(white: 0.22, alpha: 0.6)
			self.view.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
		})
	}
	
	func iOS8Mode() {
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			if !UIAccessibilityIsReduceTransparencyEnabled() {
				self.view.backgroundColor = UIColor.clearColor()
				let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
				let blurEffectView = UIVisualEffectView(effect: blurEffect)
			
				//always fill the view
				blurEffectView.frame = self.view.bounds
				blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
				
				self.view.addSubview(blurEffectView)
				self.view.sendSubviewToBack(blurEffectView)

			} else {
				self.view.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
			}
			
			self.qrstring.backgroundColor = UIColor(white: 1.0, alpha: 0.0)
			self.launch.backgroundColor = UIColor(white: 1.0, alpha: 0.0)
			
		})
	}
	
	func configureDisplay() {
		if NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion.init(majorVersion: 8, minorVersion: 0, patchVersion: 0)) {
			self.iOS8Mode()
		} else {
			self.iOS7Mode()
		}
		
		if self.historyToDisplay == nil { return }
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			
			self.qrstring.text = self.historyToDisplay.string
			var image = CIImage.createQRForString(self.historyToDisplay.string)
			let width = image.extent.width
			let height = image.extent.height
			let transform = CGAffineTransformMakeScale(100/width, 100/height)
			image = image.imageByApplyingTransform(transform)
			self.image.image = UIImage(CIImage: image)
		})
	}
	
	@IBAction func cancel() {
		(self.parentViewController! as! QRViewController).removeOverlay(self, openURL:nil)
	}
	
	@IBAction func validate() {
		(self.parentViewController! as! QRViewController).removeOverlay(self, openURL:qrstring.text)
	}
	
	@IBAction func updateHistory(sender : UIButton) {
		if (history.isAlreadySaved(self.historyToDisplay)) {
			return
		}
		sender.tintColor = UIColor.blueColor()
		history.saveInfo([self.historyToDisplay!])
		let currentcolor = self.view.backgroundColor
		self.view.backgroundColor = UIColor.whiteColor()
		UIView.animateWithDuration(0.3, animations: { () -> Void in
			self.view.backgroundColor = currentcolor
		})
	}
	
}
