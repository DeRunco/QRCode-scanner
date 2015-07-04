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

class QRView: UIView {
	var qrString: String = ""
	
}
