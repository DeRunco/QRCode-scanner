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

func interfaceOrientationForDevice () -> UIInterfaceOrientation
{
    var toOrientation = UIInterfaceOrientation(rawValue: UIDevice.current.orientation.rawValue)
    if (toOrientation == nil) {toOrientation = UIInterfaceOrientation.unknown}
    if toOrientation == UIInterfaceOrientation.landscapeRight {toOrientation = UIInterfaceOrientation.landscapeLeft}
    else if toOrientation == UIInterfaceOrientation.landscapeLeft { toOrientation = UIInterfaceOrientation.landscapeRight}
    return toOrientation!;
}


class UIViewResize: UIView {
	
	override func layoutSubviews() {
		if ( self.layer.sublayers == nil ){
			return
		}
        if let sublayers = self.layer.sublayers
        {
            for c in sublayers {
                if c is AVCaptureVideoPreviewLayer {
                    c.frame = self.bounds
                }
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
		if (AVCaptureDevice.default(for: AVMediaType.video) == nil ) {
			print("No capture device available - are we on Simulator?")
			return
		}
		let captureDevice:AVCaptureDevice = AVCaptureDevice.default(for:AVMediaType.video)!
		do {
			try captureDevice.lockForConfiguration()
		} catch let error as NSError {
			print("An error occured: \(error)")
		}
		if (captureDevice.isFocusModeSupported(AVCaptureDevice.FocusMode.continuousAutoFocus)) {
			captureDevice.focusPointOfInterest = CGPoint(x:0.5, y:0.5)
			captureDevice.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
		}
		captureDevice.unlockForConfiguration()
		// Get an instance of the AVCaptureDeviceInput class using the previous device object.

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
		captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr,
                                                     AVMetadataObject.ObjectType.aztec,
                                                     AVMetadataObject.ObjectType.code39,
                                                     AVMetadataObject.ObjectType.code39Mod43,
                                                     AVMetadataObject.ObjectType.code93,
                                                     AVMetadataObject.ObjectType.code128 ]
		// Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
		videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
		videoPreviewLayer.contentsGravity = kCAGravityResizeAspectFill
		//setup the view displaying the preview layer
		preview.layer.addSublayer(videoPreviewLayer)
		preview.layer.borderColor = UIColor.orange.cgColor
		preview.layer.borderWidth = 1
		preview.clipsToBounds = false
		captureSession.startRunning()
		if (videoPreviewLayer == nil) { print("Running on the simulator"); return }
		NotificationCenter.default.addObserver(self, selector: #selector(displayOverlayFromHistory(notification:)),
		                                       name: Notification.Name(kEntrySelectedFromHistoryNotification), object: nil)
	}

	//the video orientation is bound to the interface orientation
	func updateViewDisplayAccording(toOrientation: UIInterfaceOrientation) {
		if captureOutput.connection(with:AVMediaType.video) == nil {print("No video connection for \(captureOutput)"); return}
		var videoOrientation :AVCaptureVideoOrientation
		switch (toOrientation) {
		case .portrait: videoOrientation = AVCaptureVideoOrientation.portrait
		case .landscapeLeft: videoOrientation = AVCaptureVideoOrientation.landscapeLeft
		case .landscapeRight: videoOrientation = AVCaptureVideoOrientation.landscapeRight
		case .portraitUpsideDown : videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
		case .unknown: videoOrientation = captureOutput.connection(with:AVMediaType.video)!.videoOrientation
		}
		//pretty sure the connection rotation is not needed since we are not actually using the content.
		captureOutput.connection(with:AVMediaType.video)!.videoOrientation = videoOrientation

		var angle: CGFloat = 0.0
		var shouldRotate = true
		switch (toOrientation) {
		case .portrait: angle = 0
		case .portraitUpsideDown: angle = CGFloat(Double.pi)
		case .landscapeRight: angle = CGFloat(Double.pi / 2)
		case .landscapeLeft: angle = CGFloat(-Double.pi / 2)
		case .unknown: shouldRotate = false
		}

		if shouldRotate {
			videoPreviewLayer.transform = CATransform3DConcat(CATransform3DIdentity, CATransform3DMakeRotation(angle, 0, 0, 1));
		}
	}
    
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
			self.updateViewDisplayAccording(toOrientation: interfaceOrientationForDevice())
			})
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if (videoPreviewLayer == nil) {return}
		videoPreviewLayer.frame = preview.layer.bounds
        self.updateViewDisplayAccording(toOrientation: interfaceOrientationForDevice())
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		for layer in self.layers {
			layer.removeFromSuperlayer()
		}
		layers = [QRLayer]()
	}

	func metadataOutput(_ captureOutput: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
		guard isScanning else { return }
		guard metadataObjects.count != 0 else { return }
		
		let mObj = metadataObjects.filter { $0 is AVMetadataMachineReadableCodeObject }.filter {
            ($0 as! AVMetadataMachineReadableCodeObject).type == AVMetadataObject.ObjectType.qr ||
            ($0 as! AVMetadataMachineReadableCodeObject).type == AVMetadataObject.ObjectType.aztec ||
            ($0 as! AVMetadataMachineReadableCodeObject).type == AVMetadataObject.ObjectType.code39 ||
            ($0 as! AVMetadataMachineReadableCodeObject).type == AVMetadataObject.ObjectType.code39Mod43 ||
            ($0 as! AVMetadataMachineReadableCodeObject).type == AVMetadataObject.ObjectType.code93 ||
            ($0 as! AVMetadataMachineReadableCodeObject).type == AVMetadataObject.ObjectType.code128} as! [AVMetadataMachineReadableCodeObject]

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
					let newPoint = self.videoPreviewLayer.superlayer!.convert(j, from: self.videoPreviewLayer)
					arrayOfPoints.append(newPoint)
				}
                
				index.qrString = object.stringValue!
                var size : CGSize = object.bounds.size
                if (object.bounds.size.height <= 0.2) { size.height = 0.2 }
                if (object.bounds.size.width <= 0.2) { size.width = 0.2 }
                
                let newRect = self.videoPreviewLayer.superlayer!.convert(CGRect(origin:object.bounds.origin, size: size), from: self.videoPreviewLayer)
                index.updateLocation(frame: newRect)
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
		Timer.scheduledTimer(timeInterval:time, target: self, selector: #selector(hideMessage(timer:)),
		                     userInfo:message, repeats: false)
	}

	@objc func hideMessage(timer: Timer) {
		(timer.userInfo! as! UILabel).alpha = 0
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		if self.qrOverlay != nil {
			super.touchesEnded(touches, with: event)
			return
		}
		for touch in touches {
			let touchPoint = touch.location(in:self.view)
            guard let _ = self.preview.layer.sublayers else { break }
			for layer in self.preview.layer.sublayers! as [CALayer] {
				let convertedPoint = self.view.layer.convert(touchPoint, to: layer)
				if !(layer is QRLayer) { continue }
				
				if (layer as! QRLayer).path!.contains(convertedPoint) {
					self.selectedLayer = (layer as! QRLayer)

					let newHistory = HistoryEntry()
					newHistory.string = (layer as! QRLayer).qrString
					newHistory.date = Date()

					self.displayOverlay(newHistory: newHistory)
					return
				}
			}
		}
		
	}
	


	@objc func displayOverlayFromHistory(notification: NSNotification) {
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
		self.performSegue(withIdentifier: "tapQRCode", sender: newHistory);
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard sender is HistoryEntry else {
			return;
		}
		(segue.destination as! QRHistoryOverlayViewController).mainVC = self;
		(segue.destination as! QRHistoryOverlayViewController).historyToDisplay = (sender as! HistoryEntry)
	}
		
	func removeOverlay(vc: QRHistoryOverlayViewController) {
		if self.qrOverlay == vc {
			self.qrOverlay = nil
			self.selectedLayer = nil
		}

		UIView.animate(withDuration: 0.3, animations: { () -> Void in
			vc.view.frame.origin.y = vc.view.frame.size.height
		}) { (_) -> Void in
			vc.removeFromParentViewController()
			vc.view.removeFromSuperview()
		}
	}
	
}

