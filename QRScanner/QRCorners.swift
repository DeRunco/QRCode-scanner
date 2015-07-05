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

class QRView: UIView {
	var qrString: String = ""
	var points: [CGPoint]!
	
	func updateLocation(frame: CGRect, corners: [CGPoint]) {
		self.frame = frame
		self.points = corners
	}
}
