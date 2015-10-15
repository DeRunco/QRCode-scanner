//
//  ViewController.swift
//  barcode_scanner
//
//  Created by Charles Thierry on 16/01/15.
//  Copyright (c) 2015 Charles Thierry. All rights reserved.
//

import UIKit
import AVFoundation



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
		let bob = NSErrorPointer()
		do {
			try captureDevice.lockForConfiguration()
		} catch let error as NSError {
			bob.memory = error
		}
		captureDevice.focusMode = AVCaptureFocusMode.ContinuousAutoFocus
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
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "displayOverlayFromHistory:", name: kEntrySelectedFromHistoryNotification, object: nil)
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

		//prevent rotation if no rotation is needed
		if shouldRotate {
//			UIView.setAnimationsEnabled(false)
			videoPreviewLayer.transform = CATransform3DConcat(CATransform3DIdentity, CATransform3DMakeRotation(angle, 0, 0, 1));
//			UIView.setAnimationsEnabled(true)
		}
	}

	override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		if #available(iOS 8.0, *) {
		    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
		} else {
		    // Fallback on earlier versions
		}
		var toOrientation = UIInterfaceOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)
		if (toOrientation == nil) {toOrientation = UIInterfaceOrientation.Unknown}
		if toOrientation == UIInterfaceOrientation.LandscapeRight {toOrientation = UIInterfaceOrientation.LandscapeLeft}
		else if toOrientation == UIInterfaceOrientation.LandscapeLeft { toOrientation = UIInterfaceOrientation.LandscapeRight}
//		var fromIO = UIApplication.sharedApplication().statusBarOrientation
		coordinator.animateAlongsideTransition({ (_) -> Void in
			self.willAnimateRotationToInterfaceOrientation(toOrientation!, duration: 0.3)
			}, completion:nil	)
	}

	override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
		super.willAnimateRotationToInterfaceOrientation(toInterfaceOrientation, duration: duration)
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
		for var i = self.layers.count - 1 ; i >= 0; --i {
			self.layers[i].removeFromSuperlayer()
		}
		layers = [QRLayer]()
	}

	func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
		if !isScanning { return }
		if metadataObjects == nil { return }
		if metadataObjects.count ==  0 { return }
		var i : Int = 0
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			for ; i < metadataObjects.count ; i++ {
				var object = metadataObjects[i] as! AVMetadataMachineReadableCodeObject
				if let type = object.type {
					if type != AVMetadataObjectTypeQRCode {
						return
					}
					object = self.videoPreviewLayer.transformedMetadataObjectForMetadataObject(object) as! AVMetadataMachineReadableCodeObject
					var index: QRLayer
					if self.layers.count <= i {
						index = QRLayer()
						self.preview.layer.addSublayer(index)
						self.layers.append(index)
					} else {
						index = self.layers[i]
					}
					var arrayOfPoints = [CGPoint]()
					for var j = 0; j < object.corners.count; j++ {
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
		NSTimer.scheduledTimerWithTimeInterval(time, target: self, selector: Selector("hideMessage:"), userInfo:["view":message], repeats: false)
	}

	func hideMessage(timer: NSTimer) {
		(timer.userInfo!["view"]! as! UILabel).alpha = 0
	}

	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if self.qrOverlay != nil{
			self.removeOverlay(self.qrOverlay, openURL: nil);
		}
		for touch in touches {
			let touchPoint = touch.locationInView(self.view)
			for layer in self.preview.layer.sublayers as [CALayer]! {
				let convertedPoint = self.view.layer.convertPoint(touchPoint, toLayer: layer)

				if !(layer is QRLayer) {continue}
				if CGPathContainsPoint((layer as! QRLayer).path, nil, convertedPoint, true) {
					let url = NSURL(string: (layer as! QRLayer).qrString)
					if (url == nil) {
						self.displayMessage("No URL", time: 1)
						continue
					}
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

//	func updateSelectedLayer() {
//		if let selectLayer = self.selectedLayer {
//			for layer in self.layers {
//
//			}
//		}
//	}

	func displayOverlayFromHistory(notification: NSNotification) {
		self.navigationController!.popViewControllerAnimated(true)
		if let userInfo = notification.userInfo as? [String:HistoryEntry] {
			if let entry = userInfo[kEntryUserInfo] {
				self.displayOverlay(entry)
			}
		}
	}

	func displayOverlay(newHistory: HistoryEntry) {
		if let _ = self.qrOverlay {
			return
		}
		self.qrOverlay = self.storyboard!.instantiateViewControllerWithIdentifier("QRHistoryOverlayViewController") as! QRHistoryOverlayViewController
		self.qrOverlay.historyToDisplay = newHistory
		self.addChildViewController(self.qrOverlay)
		self.qrOverlay.view.frame = self.preview.frame
		self.qrOverlay.view.frame.origin.y = self.qrOverlay.view.frame.size.height
		self.view.addSubview(self.qrOverlay.view)
		UIView.animateWithDuration(0.3, animations: { () -> Void in
			self.qrOverlay.view.frame = self.preview.frame
		})
	}

	func removeOverlay(vc: QRHistoryOverlayViewController, openURL: String!) {
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
			if openURL != nil {
				let url = NSURL(string: openURL!)
				UIApplication.sharedApplication().openURL(url!)
			}
		}
	}
}

