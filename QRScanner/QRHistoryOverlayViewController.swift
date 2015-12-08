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
	
	var historyToDisplay: HistoryEntry!

	override func viewDidLoad() {
		super.viewDidLoad()
		qrstring.userInteractionEnabled = false
		self.configureDisplay()
		// Do any additional setup after loading the view.

	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func configureDisplay(){
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
		history.saveInfo([self.historyToDisplay!]);
		let currentcolor = self.view.backgroundColor
		self.view.backgroundColor = UIColor.whiteColor()
		UIView.animateWithDuration(0.3, animations: { () -> Void in
			self.view.backgroundColor = currentcolor
		})
	}

}
