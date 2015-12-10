//
//  QRNavigationController.swift
//  QRScanner
//
//  Created by Charles Thierry on 09/12/15.
//  Copyright © 2015 Weemo, Inc. All rights reserved.
//

import UIKit

class QRNavigationController: UINavigationController, UINavigationControllerDelegate {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.delegate = self
		// Do any additional setup after loading the view.
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
		if (viewController is QRViewController),
			let _=(viewController as! QRViewController).qrOverlay {
				(viewController as! QRViewController).displayOverlay((viewController as! QRViewController).qrOverlay.historyToDisplay)
		}
	}
	@IBAction func unwindToNavigation(seg: UIStoryboardSegue)
	{
		
	}
	
}
