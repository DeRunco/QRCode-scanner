//
//  ViewController.swift
//  barcode_scanner
//
//  Created by Charles Thierry on 16/01/15.
//  Copyright (c) 2015 Charles Thierry. All rights reserved.
//

import UIKit
import AVFoundation


extension CIImage {
	
	class func createQRForString(qrString: NSString) ->CIImage {
		let stringData = qrString.dataUsingEncoding(NSISOLatin1StringEncoding)
		let qrFilter = CIFilter(name:"CIQRCodeGenerator")
		qrFilter!.setValue(stringData, forKey: "inputMessage")
		return qrFilter!.outputImage!
	}
}


class UIViewResize: UIView {
	
	override func layoutSubviews() {
		if ( self.layer.sublayers == nil ){
			return
		}
		for c:CALayer in self.layer.sublayers as [CALayer]! {
			if c.isKindOfClass(AVCaptureVideoPreviewLayer) {
				c.frame = self.bounds
			}
		}
	}
}

class QRViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UIAlertViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

	var captureSession : AVCaptureSession!
	let captureOutput = AVCaptureVideoDataOutput()
	var videoPreviewLayer : AVCaptureVideoPreviewLayer!
	var currentLayerRotation : CATransform3D = CATransform3DIdentity
	@IBOutlet weak var historyButton: UIBarButtonItem!
	weak var selectedLayer : QRLayer?
	var layers : [QRLayer] = [QRLayer]()
	var message = UILabel()
	@IBOutlet weak var preview : UIView!
	var isScanning = true
	var qrOverlay : QRHistoryOverlayViewController!

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		message.alpha = 0
		self.view.addSubview(message)
		// Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
		// as the media type parameter.
		if (AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) == nil ) {
			print("No capture device available - are we on Simulator? WTH, man?")
			return
		}
		let captureDevice:AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
		do {
			try captureDevice.lockForConfiguration()
		} catch let error as NSError {
			print("An error occured: \(error)")
		}
		if (captureDevice.isFocusModeSupported(AVCaptureFocusMode.ContinuousAutoFocus)) {
			captureDevice.focusMode = AVCaptureFocusMode.ContinuousAutoFocus
		}
		captureDevice.unlockForConfiguration()
		// Get an instance of the AVCaptureDeviceInput class using the previous device object.
//		let input:AVCaptureDeviceInput! = AVCaptureDeviceInput.deviceInputWithDevice(captureDevice) as AVCaptureDeviceInput?
		let input:AVCaptureDeviceInput!
		do {
			try input = AVCaptureDeviceInput(device:captureDevice)
			if (input == nil) {
				// If any error occurs, simply log the description of it and don't continue any more.
				NSLog("Could not get capture")
				return
			}
		} catch {
			NSLog("Error while trying to init the captureDevice")
			return
		}
		// Initialize the captureSession object.
		captureSession = AVCaptureSession()
		// Set the input device on the capture session.
		captureSession.addInput(input)

		let CaptureOutputQueue : dispatch_queue_t = dispatch_queue_create("CaptureOutputQueue", nil)
		captureOutput.setSampleBufferDelegate(self, queue: CaptureOutputQueue)
		captureSession.addOutput(captureOutput)
		// Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
		let captureMetadataOutput : AVCaptureMetadataOutput = AVCaptureMetadataOutput()
		captureSession.addOutput(captureMetadataOutput)
		// Create a new serial dispatch queue.

		let dispatchQueue : dispatch_queue_t = dispatch_queue_create("CaptureMetadataQueue", nil)
		captureMetadataOutput.setMetadataObjectsDelegate(self, queue:dispatchQueue)
		captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
		// Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
		videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
		videoPreviewLayer.contentsGravity = kCAGravityResizeAspectFill
		//setup the view displaying the preview layer
		preview.layer.addSublayer(videoPreviewLayer)
		preview.layer.borderColor = UIColor.orangeColor().CGColor
		preview.layer.borderWidth = 1
		preview.clipsToBounds = false
		captureSession.startRunning()
		if (videoPreviewLayer == nil) {print("Running on the simulator"); return}
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(QRViewController.displayOverlayFromHistory(_:)), name: kEntrySelectedFromHistoryNotification, object: nil)
	}

	//the video orientation is bound to the interface orientation
	func updateViewDisplayAccordingToOrientation(orientation: UIInterfaceOrientation) {
		if captureOutput.connectionWithMediaType(AVMediaTypeVideo) == nil {print("No video connection for \(captureOutput)"); return}
		var videoOrientation :AVCaptureVideoOrientation
		switch (orientation) {
		case .Portrait: videoOrientation = AVCaptureVideoOrientation.Portrait
		case .LandscapeLeft: videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
		case .LandscapeRight: videoOrientation = AVCaptureVideoOrientation.LandscapeRight
		case .PortraitUpsideDown : videoOrientation = AVCaptureVideoOrientation.PortraitUpsideDown
		case .Unknown: videoOrientation = captureOutput.connectionWithMediaType(AVMediaTypeVideo)!.videoOrientation
		}
		//pretty sure the connection rotation is not needed since we are not actually using the content.
		captureOutput.connectionWithMediaType(AVMediaTypeVideo)!.videoOrientation = videoOrientation

		var angle: CGFloat = 0.0
		var shouldRotate = true
		switch (orientation) {
		case .Portrait: angle = 0
		case .PortraitUpsideDown: angle = CGFloat(M_PI)
		case .LandscapeRight: angle = ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) ? CGFloat(-M_PI_2) : CGFloat(M_PI_2))
		case .LandscapeLeft: angle = ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) ? CGFloat(M_PI_2) : CGFloat(-M_PI_2))
		case .Unknown: shouldRotate = false
		}

		if shouldRotate {
			videoPreviewLayer.transform = CATransform3DConcat(CATransform3DIdentity, CATransform3DMakeRotation(angle, 0, 0, 1));
		}
	}

	override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
	    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
		var toOrientation = UIInterfaceOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)
		if (toOrientation == nil) {toOrientation = UIInterfaceOrientation.Unknown}
		if toOrientation == UIInterfaceOrientation.LandscapeRight {toOrientation = UIInterfaceOrientation.LandscapeLeft}
		else if toOrientation == UIInterfaceOrientation.LandscapeLeft { toOrientation = UIInterfaceOrientation.LandscapeRight}
		coordinator.animateAlongsideTransition({ (_) -> Void in
			self.willAnimateRotationToInterfaceOrientation(toOrientation!, duration: 0.3)
			}, completion:nil	)
	}

	override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
		self.updateViewDisplayAccordingToOrientation(toInterfaceOrientation)
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		if (videoPreviewLayer == nil) {return}
		videoPreviewLayer.frame = preview.layer.bounds

	}

	override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
		return UIInterfaceOrientation.Portrait
	}

	override func viewDidDisappear(animated: Bool) {
		for layer in self.layers {
			layer.removeFromSuperlayer()
		}
		layers = [QRLayer]()
	}

	func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
		guard isScanning else { return }
		guard metadataObjects != nil else { return }
		guard metadataObjects.count != 0 else { return }
		
		let mObj = metadataObjects?.filter { $0 is AVMetadataMachineReadableCodeObject }.filter {
			($0 as! AVMetadataMachineReadableCodeObject).type == AVMetadataObjectTypeQRCode } as! [AVMetadataMachineReadableCodeObject]

		var counter: Int = 0
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			for obj in mObj{
				let object = self.videoPreviewLayer.transformedMetadataObjectForMetadataObject(obj) as! AVMetadataMachineReadableCodeObject
				var index: QRLayer
				
				if self.layers.count <= counter {
					index = QRLayer()
					self.preview.layer.addSublayer(index)
					self.layers.append(index)
				} else {
					index = self.layers[counter]
				}
				// because ++ are only used in C-style for loops, and are are signs of Evil and Cute-But-Difficult-to-Understand Code. Also Chris Lattner doesn't like them.
				// https://stackoverflow.com/questions/35158422/the-and-operators-have-been-deprecated-xcode-7-3
				counter += 1
				
				var arrayOfPoints = [CGPoint]()

				// this range syntax pleases Chris Lattner because it is clear.
				// for j in object.corners.indices { // to be fair it is better in swift 3
				for j in 0 ..< object.corners.count {
					var newPoint = CGPointZero
					let pointDict = object.corners[j] as? NSDictionary
					CGPointMakeWithDictionaryRepresentation(pointDict!, &newPoint)
					newPoint = self.videoPreviewLayer.superlayer!.convertPoint(newPoint, fromLayer: self.videoPreviewLayer)
					arrayOfPoints.append(newPoint)
				}
				
				index.qrString = object.stringValue

				let newRect = self.videoPreviewLayer.superlayer!.convertRect(object.bounds, fromLayer: self.videoPreviewLayer)
				index.updateLocation(newRect, corners: arrayOfPoints)
//					self.updateSelectedLayer()
				index.lowerColors = (self.qrOverlay != nil)
			}
		})
	}

	func displayMessage(mess: String!, time: NSTimeInterval) {
		message.text = mess
		message.numberOfLines = 0
		message.alpha = 1
		message.font = UIFont.systemFontOfSize(24)
		message.backgroundColor = UIColor.redColor()
		message.textColor = UIColor.whiteColor()
		let size = message.sizeThatFits(CGSizeMake(self.view.bounds.size.width, 200))
		message.frame = CGRectMake(self.view.bounds.size.width/2 - size.width/2, self.preview.frame.origin.y, size.width, size.height)
		NSTimer.scheduledTimerWithTimeInterval(time, target: self, selector: #selector(QRViewController.hideMessage(_:)), userInfo:["view":message], repeats: false)
	}

	func hideMessage(timer: NSTimer) {
		(timer.userInfo!["view"]! as! UILabel).alpha = 0
	}
	
	@IBAction func backFromHistory(button: UIBarButtonItem) {
		
	}

	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if let _ = self.qrOverlay {
			super.touchesEnded(touches, withEvent: event)
			return
		}
		
		for touch in touches {
			let touchPoint = touch.locationInView(self.view)
			for layer in self.preview.layer.sublayers as [CALayer]! {
				let convertedPoint = self.view.layer.convertPoint(touchPoint, toLayer: layer)
				if !(layer is QRLayer) {continue}
				if CGPathContainsPoint((layer as! QRLayer).path!, nil, convertedPoint, true) {
					self.selectedLayer = (layer as! QRLayer)

					let newHistory = HistoryEntry()
					newHistory.string = (layer as! QRLayer).qrString
					newHistory.date = NSDate()

					self.displayOverlay(newHistory)
					//TODO add the history entry
					return //no need to continue parsing throught the available QR
				}
			}
		}

	}
	


	func displayOverlayFromHistory(notification: NSNotification) {
		self.navigationController!.popToRootViewControllerAnimated(true)
		dispatch_async(dispatch_get_main_queue()) { () -> Void in
			if let userInfo = notification.userInfo as? [String:HistoryEntry] {
				if let entry = userInfo[kEntryUserInfo] {
					self.displayOverlay(entry)
				}
			}
		}
	}
	
	func displayOverlay(newHistory: HistoryEntry) {
		if let _ = self.qrOverlay {
//			self.qrOverlay.view.removeFromSuperview()
//			self.qrOverlay.removeFromParentViewController()
//			self.qrOverlay = nil
		} else {
			self.qrOverlay = self.storyboard!.instantiateViewControllerWithIdentifier("QRHistoryOverlayViewController") as! QRHistoryOverlayViewController
		}
		self.qrOverlay.historyToDisplay = newHistory
		
		self.qrOverlay.view.frame = CGRectMake(0, 0, 15, 15)
		self.qrOverlay.view.center = self.view.center
		self.qrOverlay.view.translatesAutoresizingMaskIntoConstraints = false
		self.addChildViewController(self.qrOverlay)
		self.view.addSubview(self.qrOverlay.view)
	
		let a = NSLayoutConstraint.constraintsWithVisualFormat("V:[navView]-0-[overlay]-0-|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil,
			views: ["navView":self.navigationController!.navigationBar, "overlay":self.qrOverlay.view!])
		let b = NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[overlay]-0-|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["overlay":self.qrOverlay.view])
		self.parentViewController!.view.addConstraints(a)
		self.parentViewController!.view.addConstraints(b)
	}
	
	
	func openQR(openURL: String!) {
		if openURL != nil {
			let url = NSURL(string: openURL!)
			UIApplication.sharedApplication().openURL(url!)
		}
	}
	
	func removeOverlay(vc: QRHistoryOverlayViewController) {
		//check if it is posible to open the URL?
		
		if self.qrOverlay == vc {
			self.qrOverlay = nil
			self.selectedLayer = nil
		}
//		self.updateSelectedLayer()
		UIView.animateWithDuration(0.3, animations: { () -> Void in
			vc.view.frame.origin.y = vc.view.frame.size.height
		}) { (_) -> Void in
			vc.removeFromParentViewController()
			vc.view.removeFromSuperview()
		}
	}
	
}

