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
	var points: [CGPoint]!
	var timer: NSTimer!
	/// This field tells the layer that the currently selected QR has the same textfield as the QR covered by this layer.
	var lowerColors = false
	var isSelectable = false

	func updateLocation(frame: CGRect, corners: [CGPoint]) {
		self.frame = frame
		self.points = corners
		self.frame = self.bounds
		self.fillColor = lowerColors ? UIColor(red: 0.15, green: 0.15, blue: 0.65, alpha: 0.55).CGColor : UIColor(red: 0, green: 1, blue: 0, alpha: 0.75).CGColor
		var path = CGPathCreateMutable()
		CGPathMoveToPoint(path, nil, corners[0].x - self.frame.origin.x, corners[0].y - self.frame.origin.y)
		CGPathAddLineToPoint(path, nil, corners[1].x - self.frame.origin.x, corners[1].y - self.frame.origin.y)
		CGPathAddLineToPoint(path, nil, corners[2].x - self.frame.origin.x, corners[2].y - self.frame.origin.y)
		CGPathAddLineToPoint(path, nil, corners[3].x - self.frame.origin.x, corners[3].y - self.frame.origin.y)
		CGPathCloseSubpath(path)
		self.path = path
		self.fillRule = kCAFillRuleEvenOdd
		self.timer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: "timeout:", userInfo: nil, repeats: false)
	}
	
	@objc func timeout(timer: NSTimer) {
		if timer != self.timer {
			return
		}
		self.fillColor = UIColor.clearColor().CGColor
	}
}
