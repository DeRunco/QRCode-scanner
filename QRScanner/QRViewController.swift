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
	
	class func createQRForString(qrString: String) ->CIImage {
		let stringData = qrString.data(using: String.Encoding.utf8)
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
			if c is AVCaptureVideoPreviewLayer {
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
		if (AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) == nil ) {
			print("No capture device available - are we on Simulator? WTH, man?")
			return
		}
		let captureDevice:AVCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType:AVMediaTypeVideo)
		do {
			try captureDevice.lockForConfiguration()
		} catch let error as NSError {
			print("An error occured: \(error)")
		}
		if (captureDevice.isFocusModeSupported(AVCaptureFocusMode.continuousAutoFocus)) {
			captureDevice.focusPointOfInterest = CGPoint(x:0.5, y:0.5)
			captureDevice.focusMode = AVCaptureFocusMode.continuousAutoFocus
		}
		captureDevice.unlockForConfiguration()
		// Get an instance of the AVCaptureDeviceInput class using the previous device object.
//		let input:AVCaptureDeviceInput! = AVCaptureDeviceInput.deviceInputWithDevice(captureDevice) as AVCaptureDeviceInput?
		let input:AVCaptureDeviceInput!
		do {
			try input = AVCaptureDeviceInput(device:captureDevice)
			guard input != nil else {
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

		let captureOutputQueue : DispatchQueue = DispatchQueue(label: "CaptureOutputQueue")
		captureOutput.setSampleBufferDelegate(self, queue: captureOutputQueue)
		captureSession.addOutput(captureOutput)
		// Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
		let captureMetadataOutput : AVCaptureMetadataOutput = AVCaptureMetadataOutput()
		captureSession.addOutput(captureMetadataOutput)
		// Create a new serial dispatch queue.

		let dispatchQueue : DispatchQueue = DispatchQueue(label: "CaptureOutputQueue")
		captureMetadataOutput.setMetadataObjectsDelegate(self, queue:dispatchQueue)
		captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
		// Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
		videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
		videoPreviewLayer.contentsGravity = kCAGravityResizeAspectFill
		//setup the view displaying the preview layer
		preview.layer.addSublayer(videoPreviewLayer)
		preview.layer.borderColor = UIColor.orange.cgColor
		preview.layer.borderWidth = 1
		preview.clipsToBounds = false
		captureSession.startRunning()
		if (videoPreviewLayer == nil) {print("Running on the simulator"); return}
		NotificationCenter.default.addObserver(self, selector: #selector(self.displayOverlayFromHistory(notification:)),
		                                       name: Notification.Name(kEntrySelectedFromHistoryNotification), object: nil)
	}

	//the video orientation is bound to the interface orientation
	func updateViewDisplayAccording(toOrientation: UIInterfaceOrientation) {
		if captureOutput.connection(withMediaType:AVMediaTypeVideo) == nil {print("No video connection for \(captureOutput)"); return}
		var videoOrientation :AVCaptureVideoOrientation
		switch (toOrientation) {
		case .portrait: videoOrientation = AVCaptureVideoOrientation.portrait
		case .landscapeLeft: videoOrientation = AVCaptureVideoOrientation.landscapeLeft
		case .landscapeRight: videoOrientation = AVCaptureVideoOrientation.landscapeRight
		case .portraitUpsideDown : videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
		case .unknown: videoOrientation = captureOutput.connection(withMediaType:AVMediaTypeVideo)!.videoOrientation
		}
		//pretty sure the connection rotation is not needed since we are not actually using the content.
		captureOutput.connection(withMediaType:AVMediaTypeVideo)!.videoOrientation = videoOrientation

		var angle: CGFloat = 0.0
		var shouldRotate = true
		switch (toOrientation) {
		case .portrait: angle = 0
		case .portraitUpsideDown: angle = CGFloat(M_PI)
		case .landscapeRight: angle = CGFloat(M_PI_2)
		case .landscapeLeft: angle = CGFloat(-M_PI_2)
		case .unknown: shouldRotate = false
		}

		if shouldRotate {
			videoPreviewLayer.transform = CATransform3DConcat(CATransform3DIdentity, CATransform3DMakeRotation(angle, 0, 0, 1));
		}
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		var toOrientation = UIInterfaceOrientation(rawValue: UIDevice.current.orientation.rawValue)
		if (toOrientation == nil) {toOrientation = UIInterfaceOrientation.unknown}
		if toOrientation == UIInterfaceOrientation.landscapeRight {toOrientation = UIInterfaceOrientation.landscapeLeft}
		else if toOrientation == UIInterfaceOrientation.landscapeLeft { toOrientation = UIInterfaceOrientation.landscapeRight}
		coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
			self.updateViewDisplayAccording(toOrientation: toOrientation!)
			})
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if (videoPreviewLayer == nil) {return}
		videoPreviewLayer.frame = preview.layer.bounds

	}

//	override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
//		return UIInterfaceOrientation.Portrait
//	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		for layer in self.layers {
			layer.removeFromSuperlayer()
		}
		layers = [QRLayer]()
	}

	func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
		guard isScanning else { return }
		guard metadataObjects != nil else { return }
		guard metadataObjects.count != 0 else { return }
		
		let mObj = metadataObjects?.filter { $0 is AVMetadataMachineReadableCodeObject }.filter {
			($0 as! AVMetadataMachineReadableCodeObject).type == AVMetadataObjectTypeQRCode } as! [AVMetadataMachineReadableCodeObject]

		DispatchQueue.main.async {
			for i in mObj.indices {
				let index: QRLayer
				let obj = mObj[i]
				let object = self.videoPreviewLayer.transformedMetadataObject(for:obj) as! AVMetadataMachineReadableCodeObject
				
				if self.layers.count <= i {
					index = QRLayer()
					self.preview.layer.addSublayer(index)
					self.layers.append(index)
				} else {
					index = self.layers[i]
				}
				var arrayOfPoints = [CGPoint]()
				for j in object.corners {
					var newPoint = CGPoint(dictionaryRepresentation: j as! CFDictionary)
					guard newPoint != nil else { continue }
					newPoint = self.videoPreviewLayer.superlayer!.convert(newPoint!, from: self.videoPreviewLayer)
					arrayOfPoints.append(newPoint!)
				}
				index.qrString = object.stringValue
				
				let newRect = self.videoPreviewLayer.superlayer!.convert(object.bounds, from: self.videoPreviewLayer)
				index.updateLocation(frame: newRect, corners: arrayOfPoints)
				index.lowerColors = (self.qrOverlay != nil)
			}
		}
	}

	func displayMessage(mess: String!, time: TimeInterval) {
		message.text = mess
		message.numberOfLines = 0
		message.alpha = 1
		message.font = UIFont.systemFont(ofSize:24)
		message.backgroundColor = UIColor.red
		message.textColor = UIColor.white
		let size = message.sizeThatFits(CGSize(width:self.view.bounds.size.width, height:200))
		message.frame = CGRect(x:self.view.bounds.size.width/2 - size.width/2, y:self.preview.frame.origin.y,
		                       width: size.width, height:size.height)
		Timer.scheduledTimer(timeInterval:time, target: self, selector: #selector(self.hideMessage(timer:)),
		                     userInfo:message, repeats: false)
	}

	func hideMessage(timer: Timer) {
		(timer.userInfo! as! UILabel).alpha = 0
	}
	
//	@IBAction func backFromHistory(button: UIBarButtonItem) {
//		
//	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let _ = self.qrOverlay else {
			super.touchesEnded(touches, with: event)
			return
		}
		
		for touch in touches {
			let touchPoint = touch.location(in:self.view)
			for layer in self.preview.layer.sublayers as [CALayer]! {
				let convertedPoint = self.view.layer.convert(touchPoint, to: layer)
				if !(layer is QRLayer) {continue}
				
				if (layer as! QRLayer).path!.contains(convertedPoint) {
					self.selectedLayer = (layer as! QRLayer)

					let newHistory = HistoryEntry()
					newHistory.string = (layer as! QRLayer).qrString
					newHistory.date = Date()

					self.displayOverlay(newHistory: newHistory)
					//TODO add the history entry
					return //no need to continue parsing throught the available QR
				}
			}
		}

	}
	


	func displayOverlayFromHistory(notification: NSNotification) {
		self.navigationController!.popToRootViewController(animated:true)
		DispatchQueue.main.async {
			if let userInfo = notification.userInfo as? [String:HistoryEntry] {
				if let entry = userInfo[kEntryUserInfo] {
					self.displayOverlay(newHistory:entry)
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
			self.qrOverlay = self.storyboard!.instantiateViewController(withIdentifier:"QRHistoryOverlayViewController") as! QRHistoryOverlayViewController
		}
		self.qrOverlay.historyToDisplay = newHistory
		
		self.qrOverlay.view.frame = CGRect(x:0, y:0, width:15, height:15)
		self.qrOverlay.view.center = self.view.center
		self.qrOverlay.view.translatesAutoresizingMaskIntoConstraints = false
		self.addChildViewController(self.qrOverlay)
		self.view.addSubview(self.qrOverlay.view)
	
		let a = NSLayoutConstraint.constraints(withVisualFormat: "V:[navView]-0-[overlay]-0-|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil,
			views: ["navView":self.navigationController!.navigationBar, "overlay":self.qrOverlay.view!])
		let b = NSLayoutConstraint.constraints(withVisualFormat:"H:|-0-[overlay]-0-|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: ["overlay":self.qrOverlay.view])
		self.parent!.view.addConstraints(a)
		self.parent!.view.addConstraints(b)
	}
	
	
	func openQR(openURL: String!) {
		if openURL != nil {
			let url = URL(string: openURL!)
			UIApplication.shared.openURL(url!)
		}
	}
	
	func removeOverlay(vc: QRHistoryOverlayViewController) {
		//check if it is posible to open the URL?
		
		if self.qrOverlay == vc {
			self.qrOverlay = nil
			self.selectedLayer = nil
		}
//		self.updateSelectedLayer()
		UIView.animate(withDuration: 0.3, animations: { () -> Void in
			vc.view.frame.origin.y = vc.view.frame.size.height
		}) { (_) -> Void in
			vc.removeFromParentViewController()
			vc.view.removeFromSuperview()
		}
	}
	
}

