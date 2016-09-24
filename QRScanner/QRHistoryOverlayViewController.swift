//
//  QRHistoryOverlayViewController.swift
//  QRScanner
//
//  Created by Charles Thierry on 10/07/15.
//  Copyright (c) 2015 Weemo, Inc. All rights reserved.
//

import UIKit

var selectedTintColor = UIColor.blue
let unselectedTintColor = UIColor.black

class QRHistoryOverlayViewController: UIViewController {
	@IBOutlet var qrstring: UILabel!
	@IBOutlet var image: UIImageView!
	@IBOutlet var favorite: UIButton!
	@IBOutlet var launch: UIButton!
	var mainVC: QRViewController!
	
	var historyToDisplay: HistoryEntry! {
		didSet {
			NotificationCenter.default.removeObserver(self)
			if (self.qrstring == nil) { return }
			NotificationCenter.default.addObserver(self, selector: #selector(favoriteUpdate(n:)),
			                                       name: Notification.Name(kHistoryEntryUpdate), object:nil)
			self.qrstring.text = self.historyToDisplay.string
			var image = CIImage.createQRForString(qrString: self.historyToDisplay!.string!)
			let width = image.extent.width
			let height = image.extent.height
			let transform = CGAffineTransform(scaleX: 100/width, y: 100/height)
			image = image.applying(transform)
			self.image.image = UIImage(ciImage: image)
		}
	}
	
	override func viewDidLoad() {
		selectedTintColor = self.view.tintColor
		super.viewDidLoad()
		qrstring.isUserInteractionEnabled = false
		self.configureDisplay()
		// Do any additional setup after loading the view.
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.updateFavoriteStatus()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		NotificationCenter.default.removeObserver(self)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	


	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		var touchIsIn = false
		for touch in touches {
			if (self.image.frame.contains(touch.location(in:self.view))) {
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
		DispatchQueue.main.async {
			self.qrstring.text = self.historyToDisplay.string
			var image = CIImage.createQRForString(qrString: self.historyToDisplay.string)
			let width = image.extent.width
			let height = image.extent.height
			let transform = CGAffineTransform(scaleX: 100/width, y: 100/height)
			image = image.applying(transform)
			self.image.image = UIImage(ciImage: image)
		}
	}
	
	func updateFavoriteStatus () {
		DispatchQueue.main.async {
			self.favorite.tintColor = history.isAlreadySaved(his: self.historyToDisplay) ? selectedTintColor : unselectedTintColor
		}
	}
	
	func updateBackground() {
		DispatchQueue.main.async {
			if !UIAccessibilityIsReduceTransparencyEnabled() {
				self.view.backgroundColor = UIColor.clear
				let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
				let blurEffectView = UIVisualEffectView(effect: blurEffect)
				
				//always fill the view
				blurEffectView.frame = self.view.bounds
				blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
				
				self.view.addSubview(blurEffectView)
				self.view.sendSubview(toBack: blurEffectView)
				
			} else {
				self.view.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
			}
		}
	}
	
	func favoriteUpdate(n: NSNotification) {
		self.updateFavoriteStatus()
	}
	
	func cancel() {
		guard self.presentingViewController != nil else {
			return
		}
		self.presentingViewController!.dismiss(animated: true, completion: nil)
	}
	
	@IBAction func validate() {
		guard self.presentingViewController != nil else {
			return
		}
		self.presentingViewController!.dismiss(animated: true, completion: nil)
		self.mainVC!.openQR(openURL: qrstring.text)
	}
	
	@IBAction func updateHistory(sender : UIButton) {
		let currentcolor = self.view.backgroundColor
		self.view.backgroundColor = UIColor.white
		UIView.animate(withDuration: 0.3) { 
			self.view.backgroundColor = currentcolor
		}

		if (history.isAlreadySaved(his:self.historyToDisplay)) {
			history.removeHistory(historyDescription:self.historyToDisplay)
		} else {
			history.saveInfo(entries:[self.historyToDisplay!])
		}
		self.updateFavoriteStatus()
	}
}
