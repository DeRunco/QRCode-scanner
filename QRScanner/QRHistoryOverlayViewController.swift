//
//  QRHistoryOverlayViewController.swift
//  QRScanner
//
//  Created by Charles Thierry on 10/07/15.
//  Copyright (c) 2015 Weemo, Inc. All rights reserved.
//

import UIKit

var selectedTintColor = UIColor.blueColor()
let unselectedTintColor = UIColor.blackColor()

class QRHistoryOverlayViewController: UIViewController {
	@IBOutlet var qrstring: UILabel!
	@IBOutlet var image: UIImageView!
	@IBOutlet var favorite: UIButton!
	@IBOutlet var launch: UIButton!
	
	var historyToDisplay: HistoryEntry! {
		didSet {
			NSNotificationCenter.defaultCenter().removeObserver(self)
			if (self.qrstring == nil) { return }
			NSNotificationCenter.defaultCenter().addObserver(self, selector: "favoriteUpdate:", name: kHistoryEntryUpdate, object: self.historyToDisplay)
			self.qrstring.text = self.historyToDisplay.string
			var image = CIImage.createQRForString(self.historyToDisplay.string)
			let width = image.extent.width
			let height = image.extent.height
			let transform = CGAffineTransformMakeScale(100/width, 100/height)
			image = image.imageByApplyingTransform(transform)
			self.image.image = UIImage(CIImage: image)
		}
	}
	
	override func viewDidLoad() {
		selectedTintColor = self.view.tintColor
		super.viewDidLoad()
		qrstring.userInteractionEnabled = false
		self.configureDisplay()
		// Do any additional setup after loading the view.
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.updateFavoriteStatus()
	}
	
	override func viewWillDisappear(animated: Bool) {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	


	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		var touchIsIn = false
		for touch in touches {
			if (CGRectContainsPoint(self.image.frame, touch.locationInView(self.view))) {
				touchIsIn = true
				self.validate()
			}
		}
		if !touchIsIn {
			self.cancel()
		}
	}

	func configureDisplay() {
		if self.historyToDisplay == nil { return }
		self.updateBackground()
		self.updateContent()
		self.updateFavoriteStatus()
	}
	
	func updateContent() {
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
	
	func updateFavoriteStatus () {
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			self.favorite.tintColor = history.isAlreadySaved(self.historyToDisplay) ? selectedTintColor : unselectedTintColor
		})
	}
	
	func updateBackground() {
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
			
		})
	}
	
	func favoriteUpdate(n: NSNotification) {
		self.updateFavoriteStatus()
	}
	
	func cancel() {
		(self.parentViewController! as! QRViewController).removeOverlay(self)
	}
	
	@IBAction func validate() {
		(self.parentViewController! as! QRViewController).openQR(qrstring.text)
	}
	
	@IBAction func updateHistory(sender : UIButton) {
		let currentcolor = self.view.backgroundColor
		self.view.backgroundColor = UIColor.whiteColor()
		UIView.animateWithDuration(0.3, animations: { () -> Void in
			self.view.backgroundColor = currentcolor
		})
		
		if (history.isAlreadySaved(self.historyToDisplay)) {
			history.removeHistory(self.historyToDisplay)
		} else {
			history.saveInfo([self.historyToDisplay!])
		}
		self.updateFavoriteStatus()
	}
}
