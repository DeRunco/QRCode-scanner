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
	/// This field tells the layer that the currently selected QR has the same textfield as the QR covered by this layer.
	var lowerColors = false
	var isSelectable = false

	func updateLocation(frame: CGRect, corners: [CGPoint]) {
		self.frame = frame
		self.frame = self.bounds
		self.fillColor = lowerColors ? UIColor(red: 0.15, green: 0.15, blue: 0.65, alpha: 0.55).cgColor : UIColor(red: 0, green: 1, blue: 0, alpha: 0.75).cgColor
//        let path = CGMutablePath()
//        path.move(to: CGPoint(x:corners[0].x - self.frame.origin.x,
//                              y:corners[0].y - self.frame.origin.y))
//        path.addLine(to: CGPoint(x:corners[1].x - self.frame.origin.x,
//                                 y:corners[1].y - self.frame.origin.y))
//        path.addLine(to: CGPoint(x:corners[2].x - self.frame.origin.x,
//                                 y:corners[2].y - self.frame.origin.y))
//        path.addLine(to: CGPoint(x:corners[3].x - self.frame.origin.x,
//                                 y:corners[3].y - self.frame.origin.y))
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
