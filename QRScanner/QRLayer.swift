//
//  QRCorners.swift
//  Barcode
//
//  Created by Charles Thierry on 21/02/15.
//  Copyright (c) 2015 Charles Thierry. All rights reserved.
//

import UIKit

let QRWidth:CGFloat = 100
let QRCornerRadius:CGFloat = 10

class QRLayer: CAShapeLayer {
	var qrString: String = ""
	var timer: Timer!

	func updateLocation(frame: CGRect) {
		self.frame = frame
		self.frame = self.bounds
		self.fillColor = UIColor(red: 0.15, green: 0.15, blue: 0.65, alpha: 0.55).cgColor
        let path = CGPath(rect: frame, transform: nil)
        
		self.path = path
		self.fillRule = kCAFillRuleEvenOdd
		self.timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(timeout(timer:)), userInfo: nil, repeats: false)
	}
	
	@objc func timeout(timer: Timer) {
		if timer != self.timer {
			return
		}
		self.fillColor = UIColor.clear.cgColor
	}
}
