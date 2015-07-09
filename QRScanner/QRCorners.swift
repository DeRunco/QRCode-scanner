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
	
	func updateLocation(frame: CGRect, corners: [CGPoint]) {
		self.frame = frame
		self.points = corners
		self.frame = self.bounds
		self.fillColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.75).CGColor
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
	
//	override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
//		return CGPathContainsPoint(self.mask.path, nil, point, true)
//	}

	
	//could be moved to the touchesWhatever of each subviews
//	override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) -> (){
//		var entry = HistoryEntry()
//		entry.date = NSDate()
//		entry.string = self.qrString
//		history.saveInfo([entry])
//		UIApplication.sharedApplication().openURL(NSURL(string: self.qrString)!)
//	}
}
