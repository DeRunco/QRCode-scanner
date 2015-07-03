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
		for c:CALayer in self.layer.sublayers as! [CALayer] {
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
	var isReading: Bool = false
	var corners :[QRCorners] = [QRCorners]()
	var historyController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("HistoryController") as! HistoryController

	@IBOutlet var preview: UIView!

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		var error:NSErrorPointer = NSErrorPointer()
		// Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
		// as the media type parameter.
		if (AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) == nil ) {
			println("No capture device available - are we on Simulator? WTH, man?")
			return
		}
		var captureDevice:AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
		// Get an instance of the AVCaptureDeviceInput class using the previous device object.
		var input:AVCaptureDeviceInput! = AVCaptureDeviceInput.deviceInputWithDevice(captureDevice, error: error) as! AVCaptureDeviceInput?
		if (input == nil) {
			// If any error occurs, simply log the description of it and don't continue any more.
			NSLog("Could not get capture")
			return
		}
		// Initialize the captureSession object.
		captureSession = AVCaptureSession()
		// Set the input device on the capture session.
		captureSession.addInput(input)

		var CaptureOutputQueue : dispatch_queue_t = dispatch_queue_create("CaptureOutputQueue", nil)
		captureOutput.setSampleBufferDelegate(self, queue: CaptureOutputQueue)
		captureSession.addOutput(captureOutput)
		// Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
		var captureMetadataOutput : AVCaptureMetadataOutput = AVCaptureMetadataOutput()
		captureSession.addOutput(captureMetadataOutput)
		// Create a new serial dispatch queue.

		var dispatchQueue : dispatch_queue_t = dispatch_queue_create("CaptureMetadataQueue", nil)
		captureMetadataOutput.setMetadataObjectsDelegate(self, queue:dispatchQueue)
		captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
		// Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.

		videoPreviewLayer  = AVCaptureVideoPreviewLayer(session: captureSession)
		videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
		videoPreviewLayer.contentsGravity = kCAGravityResizeAspectFill;
		preview.layer.addSublayer(videoPreviewLayer)
		preview.layer.borderColor = UIColor.orangeColor().CGColor
		preview.layer.borderWidth = 1
		preview.clipsToBounds = false
		captureSession.startRunning()
		if (videoPreviewLayer == nil) {println("Running on the simulator"); return}
	}

	//the video orientation is bound to the interface orientation
	func updateViewDisplayAccordingToOrientation(orientation: UIInterfaceOrientation) {
		if captureOutput.connectionWithMediaType(AVMediaTypeVideo) == nil {println("No video connection for \(captureOutput)"); return}
		captureOutput.connectionWithMediaType(AVMediaTypeVideo)!.videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue)!

		var angle: CGFloat = 0.0;
		switch (orientation) {
		case .Portrait:
			angle = 0
		case .PortraitUpsideDown:
			angle = CGFloat(M_PI)
		case .LandscapeLeft:
			angle = CGFloat(M_PI_2)
		case .LandscapeRight:
			angle = CGFloat(M_PI+M_PI_2)
		default:
			break;
		}

		var trans = CATransform3DConcat(CATransform3DIdentity, CATransform3DMakeRotation(angle, 0, 0, -1))
		videoPreviewLayer.transform = trans
	}

	override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
		var toOrientation = UIInterfaceOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)
		if (toOrientation == nil) {toOrientation = UIInterfaceOrientation.Unknown}
		if toOrientation == UIInterfaceOrientation.LandscapeRight {toOrientation = UIInterfaceOrientation.LandscapeLeft}
		else if toOrientation == UIInterfaceOrientation.LandscapeLeft { toOrientation = UIInterfaceOrientation.LandscapeRight}

		coordinator.animateAlongsideTransition({ (_) -> Void in
			self.willAnimateRotationToInterfaceOrientation(toOrientation!, duration: 0.3)
		}, completion: { (_) -> Void in
			self.didRotateFromInterfaceOrientation(toOrientation!)
		})
	}
	override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
		self.updateViewDisplayAccordingToOrientation(toInterfaceOrientation)
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		if (videoPreviewLayer == nil) {return}//we are on simulator

		videoPreviewLayer.frame = preview.layer.bounds
		self.updateViewDisplayAccordingToOrientation(self.interfaceOrientation)
	}

	override func shouldAutorotate() -> Bool {
		return (self.view.bounds.width > self.view.bounds.height)
	}

	override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
		return UIInterfaceOrientation.Portrait
	}

	override func supportedInterfaceOrientations() -> Int {
		return Int(UIInterfaceOrientationMask.Portrait.rawValue)
	}

	override func viewDidDisappear(animated: Bool) {
		for var i = self.corners.count - 1 ; i >= 0; --i {
			self.corners[i].removeFromParentViewController()
			self.corners[i].view.removeFromSuperview()
		}
		corners = [QRCorners]()
	}

	func isSameOrientation(videoOrientation: AVCaptureVideoOrientation, interfaceOrientation: UIInterfaceOrientation) -> Bool{
		let isInterfaceLandscape = UIInterfaceOrientationIsLandscape(interfaceOrientation)
		let isPictureLandscape = (videoOrientation == AVCaptureVideoOrientation.LandscapeLeft || videoOrientation == AVCaptureVideoOrientation.LandscapeRight)
		return isInterfaceLandscape == isPictureLandscape
	}

	func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
		if metadataObjects == nil { return }
		if metadataObjects.count ==  0 { return }
		var i : Int = 0
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			for ; i < metadataObjects.count ; i++ {
				var object = metadataObjects[i] as! AVMetadataMachineReadableCodeObject
				if (object.type == nil ) {continue}
				if (object.type! != AVMetadataObjectTypeQRCode ) {continue}

				var index :QRCorners
				if self.corners.count <= i {
					index = QRCorners(nibName: nil, bundle: nil)
					self.addChildViewController(index)
					self.preview.addSubview(index.view)
					self.corners.append(index)
				} else {
					index = self.corners[i]
				}
				let hasSameOrientation = self.isSameOrientation(connection.videoOrientation, interfaceOrientation: self.interfaceOrientation)
				index.qrstring = object.stringValue//.stringByRemovingPercentEncoding!
				index.setCorners(object.corners as! [CFDictionary], withOrientation:hasSameOrientation, fromPreview:self.preview)
			}
		})
	}

	func displayMessage(mess: String!) {
		var label = UILabel()
		label.text = mess
		label.numberOfLines = 0
		label.font = UIFont.systemFontOfSize(24);
		label.backgroundColor = UIColor.redColor()
		label.textColor = UIColor.whiteColor()
		let size = label.sizeThatFits(CGSizeMake(self.view.bounds.size.width, 200))
		label.frame = CGRectMake(self.view.bounds.size.width/2 - size.width/2, self.preview.frame.origin.y, size.width, size.height)
		self.view.addSubview(label)
		NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: Selector("hideError:"), userInfo:["view":label], repeats: false)
	}

	func hideError(timer: NSTimer) {
		(timer.userInfo!["view"]! as! UILabel).removeFromSuperview()
	}

	override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) -> (){
		var thatOneTouch = touches.first as! UITouch!
		if thatOneTouch == nil { return }
		var touchLocation = thatOneTouch.locationInView(preview)
		var touchedView = preview.hitTest(touchLocation, withEvent: event)
		if  touchedView == nil { return }
		var string = String()
		for qrv:QRCorners in corners {
			if touchedView == qrv.view {
				//TODO: Send command and historize?
				UIApplication.sharedApplication().openURL(NSURL(string: qrv.qrstring)!);
			}
		}
	}

	@IBAction func showHistory() {
		self.presentViewController(self.historyController, animated: true, completion: nil)
	}
}

