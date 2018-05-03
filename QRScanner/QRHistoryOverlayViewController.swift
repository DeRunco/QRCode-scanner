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
	@IBOutlet var qrstring: UITextView!
	@IBOutlet var image: UIImageView!
	@IBOutlet var favorite: UIBarButtonItem!
	@IBOutlet var launch: UIButton!
    @IBOutlet var textHeight: NSLayoutConstraint!
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
			image = image.transformed(by: transform)
			self.image.image = UIImage(ciImage: image)
		}
	}
	
	override func viewDidLoad() {
		selectedTintColor = self.view.tintColor
		super.viewDidLoad()
		self.configureDisplay()
		// Do any additional setup after loading the view.
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.updateFavoriteStatus()
        self.title = self.historyToDisplay.string
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		NotificationCenter.default.removeObserver(self)
	}
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator .animate(alongsideTransition: { (context) in
            self.updateTextSize()
        }) { (context) in
            
        }
    }
    
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func configureDisplay() {
		if self.historyToDisplay == nil { return }
		self.updateContent()
		self.updateFavoriteStatus()
        self.updateTextSize()
	}
	
    func updateTextSize() {
        DispatchQueue.main.async {
            let fixedWidth = self.qrstring.frame.size.width
            let newSize = self.qrstring.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
            self.textHeight.constant = newSize.height
        }
    }
    
	func updateContent() {
		DispatchQueue.main.async {
			self.qrstring.text = self.historyToDisplay.string
			var image = CIImage.createQRForString(qrString: self.historyToDisplay.string)
			let width = image.extent.width
			let height = image.extent.height
			let transform = CGAffineTransform(scaleX: 100/width, y: 100/height)
			image = image.transformed(by: transform)
			self.image.image = UIImage(ciImage: image)
		}
	}
	
	func updateFavoriteStatus () {
		DispatchQueue.main.async {
			self.favorite.tintColor = history.isAlreadySaved(his: self.historyToDisplay) ? selectedTintColor : unselectedTintColor
		}
	}
	
	@objc func favoriteUpdate(n: NSNotification) {
		self.updateFavoriteStatus()
	}
	
    @IBAction func share(sender: UIBarButtonItem) {
        let activity = UIActivityViewController(activityItems: [self.historyToDisplay.string], applicationActivities: nil)
        self.present(activity, animated: true) {
            
        }
    }
    
	@IBAction func updateHistory(sender : UIBarButtonItem) {
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
