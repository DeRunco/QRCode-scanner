//
//  QRCorners.swift
//  Barcode
//
//  Created by Charles Thierry on 21/02/15.
//  Copyright (c) 2015 Charles Thierry. All rights reserved.
//

import UIKit

func angleOffset() -> CGFloat
{
	var angle:CGFloat = 0;
	switch (UIDevice.currentDevice().orientation) {
	case .Portrait:
		angle = 0;
	case .PortraitUpsideDown:
		angle = CGFloat(M_PI);
	case .LandscapeRight:
		angle = CGFloat(M_PI+M_PI_2);
	case .LandscapeLeft:
		angle = CGFloat(M_PI_2);
	default:
		break;
	}
	return angle;
}


let QRWidth:CGFloat = 100
let QRCornerRadius:CGFloat = 10

class QRCorners: UIViewController {
	var timer = NSTimer()

	var qrstring : String {
		get {
			if label.text == nil {
				return ""
			}
			return label.text!
		}
		set(newValue){
			label.text = newValue
		}
	}
	var label = UILabel()
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		self.view.clipsToBounds = true
		self.view.layer.cornerRadius = QRCornerRadius
		label.numberOfLines = 0
		label.textAlignment = NSTextAlignment.Center
		label.font = UIFont.systemFontOfSize(10)
		label.backgroundColor = UIColor(white: 1.0, alpha: 1)
		label.lineBreakMode = NSLineBreakMode.ByCharWrapping
		self.view.addSubview(label)


	}

	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func setCorners(dictionaries: [CFDictionary], withOrientation orientation:Bool, fromPreview view:UIView) {
		var po0 = CGPoint()
		var po1 = CGPoint()
		var po2 = CGPoint()
		var po3 = CGPoint()
		CGPointMakeWithDictionaryRepresentation(dictionaries[0] as CFDictionary, &po0)
		CGPointMakeWithDictionaryRepresentation(dictionaries[1] as CFDictionary, &po1)
		CGPointMakeWithDictionaryRepresentation(dictionaries[2] as CFDictionary, &po2)
		CGPointMakeWithDictionaryRepresentation(dictionaries[3] as CFDictionary, &po3)
		var point = CGPoint()


		//put the view at the center of the QR
		var teX = min(min(po0.x, po1.x), min(po2.x, po3.x))
		var teY = max(max(po0.y, po1.y), max(po2.y, po3.y))
		var tfX = max(max(po0.x, po1.x), max(po2.x, po3.x))
		var tfY = min(min(po0.y, po1.y), min(po2.y, po3.y))

		var center = CGPointZero
		var minX, maxX, minY, maxY: CGFloat
		if (!orientation) {
			minX = (1 - teY) * view.bounds.width
			maxX = (1 - tfY) * view.bounds.width

			minY = teX * view.bounds.height
			maxY = tfX * view.bounds.height
		} else {
			minX = (1 - teX) * view.bounds.height
			maxX = (1 - tfX) * view.bounds.height

			minY = (1 - teY) * view.bounds.width
			maxY = (1 - tfY) * view.bounds.width
		}

		center = CGPointMake((minX + maxX)/2, (minY + maxY)/2)


		self.view.frame = CGRectMake(0, 0, maxX - minX, maxY - minY)
		self.view.center = center
		self.view.alpha = 0.75

		label.frame = self.view.bounds
		label.transform = CGAffineTransformRotate(CGAffineTransformIdentity, angleOffset())

		timer.invalidate()
		timer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: Selector("hideView:"), userInfo: nil, repeats: false)

	}
	@objc func hideView(timer: NSTimer) {
		UIView.animateWithDuration(0.3, animations: { () -> Void in
			self.view.alpha = 0
		})
	}

	func isPointInside(point: CGPoint) -> Bool {
		return false
	}
}