//
//  ViewController.swift
//  Face Detector
//
//  Created by Manjit Bedi on 2019-08-20.
//  Copyright © 2019 Noorg. All rights reserved.
//

import Cocoa
import AVFoundation
import AVKit
import Vision
import CoreGraphics

import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage



class FaceDetectionViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var cameraView: NSView!

    @IBOutlet weak var buttonsView: NSStackView!

    @IBOutlet weak var toggleUploadsButton: NSButton!

    @IBOutlet weak var resultTextField: NSTextField!

    @IBOutlet weak var topConstraint: NSLayoutConstraint!

    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!

    // AVCapture variables to hold sequence data
    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?

    var videoDataOutput: AVCaptureVideoDataOutput?
    var videoDataOutputQueue: DispatchQueue?

    var captureDevice: AVCaptureDevice?
    var captureDeviceResolution: CGSize = CGSize()

    // Layer UI for drawing Vision results
    var rootLayer: CALayer?
    var detectionOverlayLayer: CALayer?
    var detectedFaceRectangleShapeLayer: CAShapeLayer?
    var detectedFaceLandmarksShapeLayer: CAShapeLayer?

    var displayFaceLandmarks = false
    var uploadFrame = false
    var uploadDetectedFaces = false
    var timeToUploadImage = false
    var compositeOverlays = true
    var saveImage = false
    var faceDetected = false
    var faceAnalyzed = false
    var displayRelativePref = false
    var uploadSmallerImagesPref = false

    // for debugging
    var prevScaleX: CGFloat = 0.0
    var prevScaleY: CGFloat = 0.0

    #if DEBUG
    var collectionName = "facesDebug"
    #else
    var collectionName = "faces"
    #endif

    var appTimer: Timer?

    private var analysisLabels = [String]()
    private var displayText = ""
    private var startLessFrequentText = 30
    private var indices = [Int]()

    // Vision requests
    private var detectionRequests: [VNDetectFaceRectanglesRequest]?
    private var trackingRequests: [VNTrackObjectRequest]?

    lazy var sequenceRequestHandler = VNSequenceRequestHandler()

    override func viewDidLoad() {
        super.viewDidLoad()

        loadAnalysisText()

        NotificationCenter.default.addObserver(self, selector: #selector(changeCameraDevice), name: NSNotification.Name(rawValue: Constants.ChangeDeviceNotification), object: nil)

        self.session = self.setupAVCaptureSession()
        self.prepareVisionRequest()
        self.session?.startRunning()

        appTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)

        let defaults = UserDefaults.standard
        displayRelativePref = defaults.bool(forKey: Constants.AnnotationPositionRelativePref)
        uploadSmallerImagesPref = defaults.bool(forKey: Constants.UploadSmallerImagesPref)

    }

    override func viewDidAppear() {
        print("\(#function)")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // MARK: Actions

    @IBAction func loginFirebase(_ sender: Any) {
        signIn()
    }

    @IBAction func uploadTestImage(_ sender: Any) {
        if let woodyImage = NSImage(named: "Woody") {
            guard let tiff = woodyImage.tiffRepresentation,
                let imageRep = NSBitmapImageRep(data: tiff) else {
                    return
            }

            let compressedData = imageRep.representation(using: .jpeg, properties: [.compressionFactor : 0.5])!
            uploadImageToFirebase(data: compressedData)
        }
    }

    @IBAction func uploadVideoFrame(_ sender: Any) {
        uploadFrame = true
    }


    @IBAction func toggleUploadingFromButton(_ sender: NSButton) {
        uploadDetectedFaces = Bool(truncating: NSNumber(value: sender.state.rawValue))

        if uploadDetectedFaces {
            timeToUploadImage = true
        } else {
            timeToUploadImage = false
        }

        if let menu = NSApplication.shared.mainMenu {
            if  let controlMenu = menu.item(withTitle: "Control") {
                if let menuItem = controlMenu.submenu!.item(withTag: 808) {
                    menuItem.state = sender.state
                }
            }
        }
    }


    @IBAction func toggleUploading(_ sender: NSMenuItem) {
        sender.state = sender.state == NSControl.StateValue.on ? NSControl.StateValue.off : NSControl.StateValue.on
        uploadDetectedFaces = Bool(truncating: NSNumber(value: sender.state.rawValue))
        toggleUploadsButton.state = sender.state
        if uploadDetectedFaces {
            timeToUploadImage = true
        }
    }

    @IBAction func toogleUIButtons(_ sender: NSMenuItem) {
        sender.state = sender.state == NSControl.StateValue.on ? NSControl.StateValue.off : NSControl.StateValue.on
        buttonsView.isHidden = !Bool(truncating: NSNumber(value: sender.state.rawValue))
    }

    @IBAction func saveDocument(_ sender: NSMenuItem) {
        saveImage = true
    }

    // MARK: AVCapture Setup

    /// - Tag: CreateCaptureSession
    fileprivate func setupAVCaptureSession() -> AVCaptureSession? {
        cameraView.layer = CALayer()
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.low

        let devices = AVCaptureDevice.devices()

        // Get the user preference for the camera if set
        let deviceName = getDevicePreference()

        if deviceName != nil {
            for device in devices {
                if ((device as AnyObject).hasMediaType(AVMediaType.video)) && deviceName == device.localizedName {
                    captureDevice = device
                    print("pref use camera \(String(describing: deviceName))")
                }
            }

            if captureDevice == nil {
                for device in devices {
                    if ((device as AnyObject).hasMediaType(AVMediaType.video)) {
                        captureDevice = device
                    }
                }
            }
        } else {
            // Get all audio and video devices on this machine
            for device in devices {
                if ((device as AnyObject).hasMediaType(AVMediaType.video)) {
                    captureDevice = device
                }
            }
        }

        if captureDevice != nil {
            do {
                try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice!))

                // TODO: is this a good way to get the resolution?
                let resolution = getCaptureResolution(device: captureDevice!)
                self.configureVideoDataOutput(for: captureDevice!, resolution: resolution , captureSession: captureSession)
                self.designatePreviewLayer(for: captureSession)
                return captureSession

            } catch {
                print(AVCaptureSessionErrorKey.description)
            }
        }

        self.teardownAVCapture()

        return nil
    }

    private func getCaptureResolution(device: AVCaptureDevice) -> CGSize {
        // Define default resolution
        var resolution = CGSize(width: 0, height: 0)

        // Get video dimensions
        let formatDescription = device.activeFormat.formatDescription
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        resolution = CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))

        // Return resolution
        return resolution
    }

    /// - Tag: ConfigureDeviceResolution
    fileprivate func highestResolution420Format(for device: AVCaptureDevice) -> (format: AVCaptureDevice.Format, resolution: CGSize)? {
        var highestResolutionFormat: AVCaptureDevice.Format? = nil
        var highestResolutionDimensions = CMVideoDimensions(width: 0, height: 0)

        for format in device.formats {
            let deviceFormat = format as AVCaptureDevice.Format

            let deviceFormatDescription = deviceFormat.formatDescription
            if CMFormatDescriptionGetMediaSubType(deviceFormatDescription) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
                let candidateDimensions = CMVideoFormatDescriptionGetDimensions(deviceFormatDescription)
                if (highestResolutionFormat == nil) || (candidateDimensions.width > highestResolutionDimensions.width) {
                    highestResolutionFormat = deviceFormat
                    highestResolutionDimensions = candidateDimensions
                }
            }
        }

        if highestResolutionFormat != nil {
            let resolution = CGSize(width: CGFloat(highestResolutionDimensions.width), height: CGFloat(highestResolutionDimensions.height))
            return (highestResolutionFormat!, resolution)
        }

        return nil
    }

    /// - Tag: CreateSerialDispatchQueue
    fileprivate func configureVideoDataOutput(for inputDevice: AVCaptureDevice, resolution: CGSize, captureSession: AVCaptureSession) {

        let videoDataOutput = AVCaptureVideoDataOutput()

        // Setting the video format to be able to capture a still
        // How does this affect the Vision face detection?
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: kCVPixelFormatType_32BGRA]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true

        // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured.
        // A serial dispatch queue must be used to guarantee that video frames will be delivered in order.
        let videoDataOutputQueue = DispatchQueue(label: "com.noorg.Face-Detector")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)

        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }

        videoDataOutput.connection(with: .video)?.isEnabled = true

        // TODO: fixme?
        // iOS specific code,  is there an equivalent for Mac OS?
//        if let captureConnection = videoDataOutput.connection(with: AVMediaType.video) {
//            if captureConnection.isCameraIntrinsicMatrixDeliverySupported {
//                captureConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
//            }
//        }

        self.videoDataOutput = videoDataOutput
        self.videoDataOutputQueue = videoDataOutputQueue

        self.captureDevice = inputDevice
        self.captureDeviceResolution = resolution
    }

    /// - Tag: DesignatePreviewLayer
    fileprivate func designatePreviewLayer(for captureSession: AVCaptureSession) {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer = videoPreviewLayer

        videoPreviewLayer.name = "CameraPreview"
        videoPreviewLayer.backgroundColor = NSColor.black.cgColor
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

        if let previewRootLayer = self.cameraView.layer {
            self.rootLayer = previewRootLayer

            previewRootLayer.masksToBounds = true
            videoPreviewLayer.frame = previewRootLayer.bounds
            previewRootLayer.addSublayer(videoPreviewLayer)
        }
    }

    // Removes infrastructure for AVCapture as part of cleanup.
    fileprivate func teardownAVCapture() {
        self.videoDataOutput = nil
        self.videoDataOutputQueue = nil

        if let previewLayer = self.previewLayer {
            previewLayer.removeFromSuperlayer()
            self.previewLayer = nil
        }
    }

    // MARK: Helper Methods for Error Presentation

    fileprivate func presentErrorAlert(withTitle title: String = "Unexpected Failure", message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = title
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.runModal()
    }

    fileprivate func presentError(_ error: NSError) {
        self.presentErrorAlert(withTitle: "Failed with error \(error.code)", message: error.localizedDescription)
    }

    // MARK: Helper Methods for Handling Device Orientation & EXIF

    fileprivate func radiansForDegrees(_ degrees: CGFloat) -> CGFloat {
        return CGFloat(Double(degrees) * Double.pi / 180.0)
    }


    // MARK: Performing Vision Requests

    /// - Tag: WriteCompletionHandler
    fileprivate func prepareVisionRequest() {

        //self.trackingRequests = []
        var requests = [VNTrackObjectRequest]()

        let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request, error) in

            if error != nil {
                print("FaceDetection error: \(String(describing: error)).")
            }

            guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
                let results = faceDetectionRequest.results as? [VNFaceObservation] else {
                    return
            }
            DispatchQueue.main.async {
                // Add the observations to the tracking list
                for observation in results {
                    let faceTrackingRequest = VNTrackObjectRequest(detectedObjectObservation: observation)
                    requests.append(faceTrackingRequest)
                }
                self.trackingRequests = requests
            }
        })

        // Start with detection.  Find face, then track it.
        self.detectionRequests = [faceDetectionRequest]

        self.sequenceRequestHandler = VNSequenceRequestHandler()

        self.setupVisionDrawingLayers()
    }

    // MARK: Drawing Vision Observations

    /// - This method gets called once when a capture device is configured.
    /// Changing the device will result in this method being called again.
    fileprivate func setupVisionDrawingLayers() {

        guard let lineWidth = getLineWidthPreference() else {
            return
        }

        let captureDeviceResolution = self.captureDeviceResolution

        print("capture resolution \(self.captureDeviceResolution)")
        print("camera preview frame \(self.cameraView.frame)")

        let captureDeviceBounds = CGRect(x: 0,
                                         y: 0,
                                         width: captureDeviceResolution.width,
                                         height: captureDeviceResolution.height)

        let captureDeviceBoundsCenterPoint = CGPoint(x: captureDeviceBounds.midX,
                                                     y: captureDeviceBounds.midY)

        let normalizedCenterPoint = CGPoint(x: 0.5, y: 0.5)

        guard let rootLayer = self.rootLayer else {
            self.presentErrorAlert(message: "view was not property initialized")
            return
        }

        let overlayLayer = CALayer()
        overlayLayer.name = "DetectionOverlay"
        overlayLayer.masksToBounds = true
        overlayLayer.anchorPoint = normalizedCenterPoint
        overlayLayer.bounds = captureDeviceBounds
        overlayLayer.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)

        #if DEBUG
        print("overlay position \(overlayLayer.position)")
        #endif

        overlayLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

        let faceRectangleShapeLayer = CAShapeLayer()
        faceRectangleShapeLayer.name = "RectangleOutlineLayer"
        faceRectangleShapeLayer.bounds = captureDeviceBounds
        faceRectangleShapeLayer.anchorPoint = normalizedCenterPoint
        faceRectangleShapeLayer.position = captureDeviceBoundsCenterPoint
        faceRectangleShapeLayer.fillColor = nil
        faceRectangleShapeLayer.strokeColor = NSColor(named: "rectColor")?.cgColor
        faceRectangleShapeLayer.lineWidth = CGFloat(lineWidth)
        faceRectangleShapeLayer.shadowOpacity = 0.7
        faceRectangleShapeLayer.shadowRadius = 5

        let faceLandmarksShapeLayer = CAShapeLayer()
        faceLandmarksShapeLayer.name = "FaceLandmarksLayer"
        faceLandmarksShapeLayer.bounds = captureDeviceBounds
        faceLandmarksShapeLayer.anchorPoint = normalizedCenterPoint
        faceLandmarksShapeLayer.position = captureDeviceBoundsCenterPoint
        faceLandmarksShapeLayer.fillColor = nil
        faceLandmarksShapeLayer.strokeColor =  NSColor(named: "faceLandmarksColor")?.cgColor
        faceLandmarksShapeLayer.lineWidth = CGFloat(lineWidth)
        faceLandmarksShapeLayer.shadowOpacity = 0.7
        faceLandmarksShapeLayer.shadowRadius = 3

        overlayLayer.addSublayer(faceRectangleShapeLayer)
        faceRectangleShapeLayer.addSublayer(faceLandmarksShapeLayer)
        rootLayer.addSublayer(overlayLayer)

        self.detectionOverlayLayer = overlayLayer
        self.detectedFaceRectangleShapeLayer = faceRectangleShapeLayer
        self.detectedFaceLandmarksShapeLayer = faceLandmarksShapeLayer

        self.updateLayerGeometry()
    }

    fileprivate func updateLayerGeometry() {
        guard let overlayLayer = self.detectionOverlayLayer,
            let rootLayer = self.rootLayer,
            let previewLayer = self.previewLayer
            else {
                return
        }

        CATransaction.setValue(NSNumber(value: true), forKey: kCATransactionDisableActions)

        // iOS specific code
        // let videoPreviewRect = previewLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))

         let videoPreviewRect = previewLayer.frame

        var scaleX: CGFloat
        var scaleY: CGFloat

        scaleX = videoPreviewRect.width / captureDeviceResolution.width
        scaleY = videoPreviewRect.height / captureDeviceResolution.height

        // Scale and mirror the image to ensure upright presentation.
        let affineTransform = CGAffineTransform(rotationAngle: 0)
            .scaledBy(x: scaleX, y: scaleY)
        overlayLayer.setAffineTransform(affineTransform)

        // Cover entire screen UI.
        let rootLayerBounds = rootLayer.bounds

        overlayLayer.position = CGPoint(x: rootLayerBounds.midX, y: rootLayerBounds.midY)

        // Debug code
        #if DEBUG
        if prevScaleX != scaleX || prevScaleY != scaleY {
            print("window resized: \(previewLayer.frame.size) scale (\(scaleX), \(scaleX))")
            print("root layer bounds: \(rootLayerBounds)")
            print("overlay frame: \(overlayLayer.frame)")
            print("overlay bounds: \(overlayLayer.bounds)")
        }
        prevScaleX = scaleX
        prevScaleY = scaleY
        #endif
    }

    fileprivate func addPoints(in landmarkRegion: VNFaceLandmarkRegion2D, to path: CGMutablePath, applying affineTransform: CGAffineTransform, closingWhenComplete closePath: Bool) {
        let pointCount = landmarkRegion.pointCount
        if pointCount > 1 {
            let points: [CGPoint] = landmarkRegion.normalizedPoints
            path.move(to: points[0], transform: affineTransform)
            path.addLines(between: points, transform: affineTransform)
            if closePath {
                path.addLine(to: points[0], transform: affineTransform)
                path.closeSubpath()
            }
        }
    }

    fileprivate func addIndicators(to faceRectanglePath: CGMutablePath, faceLandmarksPath: CGMutablePath, for faceObservation: VNFaceObservation) {
        let displaySize = self.captureDeviceResolution

        let faceBounds = VNImageRectForNormalizedRect(faceObservation.boundingBox, Int(displaySize.width), Int(displaySize.height))
        faceRectanglePath.addRect(faceBounds)


        if faceAnalyzed && displayRelativePref {
            updateAnnotationPosition(faceBounds: faceBounds)
        }

        if let landmarks = faceObservation.landmarks {
            // Landmarks are relative to -- and normalized within --- face bounds
            let affineTransform = CGAffineTransform(translationX: faceBounds.origin.x, y: faceBounds.origin.y)
                .scaledBy(x: faceBounds.size.width, y: faceBounds.size.height)


            // Treat eyebrows and lines as open-ended regions when drawing paths.
            let openLandmarkRegions: [VNFaceLandmarkRegion2D?] = [
                landmarks.leftEyebrow,
                landmarks.rightEyebrow,
                landmarks.faceContour,
                landmarks.noseCrest,
                landmarks.medianLine
            ]
            for openLandmarkRegion in openLandmarkRegions where openLandmarkRegion != nil {
                self.addPoints(in: openLandmarkRegion!, to: faceLandmarksPath, applying: affineTransform, closingWhenComplete: false)
            }

            // Draw eyes, lips, and nose as closed regions.
            let closedLandmarkRegions: [VNFaceLandmarkRegion2D?] = [
                landmarks.leftEye,
                landmarks.rightEye,
                landmarks.outerLips,
                landmarks.innerLips,
                landmarks.nose
            ]
            for closedLandmarkRegion in closedLandmarkRegions where closedLandmarkRegion != nil {
                self.addPoints(in: closedLandmarkRegion!, to: faceLandmarksPath, applying: affineTransform, closingWhenComplete: true)
            }
        }
    }

    /// - Tag: DrawPaths
    fileprivate func drawFaceObservations(_ faceObservations: [VNFaceObservation]) {
        guard let faceRectangleShapeLayer = self.detectedFaceRectangleShapeLayer,
            let faceLandmarksShapeLayer = self.detectedFaceLandmarksShapeLayer
            else {
                return
        }

        CATransaction.begin()

        CATransaction.setValue(NSNumber(value: true), forKey: kCATransactionDisableActions)

        let faceRectanglePath = CGMutablePath()
        let faceLandmarksPath = CGMutablePath()

        for faceObservation in faceObservations {
            self.addIndicators(to: faceRectanglePath,
                               faceLandmarksPath: faceLandmarksPath,
                               for: faceObservation)
        }

        faceRectangleShapeLayer.path = faceRectanglePath
        faceLandmarksShapeLayer.path = faceLandmarksPath

        self.updateLayerGeometry()

        CATransaction.commit()
    }

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    /// - Tag: PerformRequests
    // Handle delegate method callback on receiving a sample buffer.
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        if uploadFrame {
            uploadFrame = false
            uploadFrame(sampleBuffer: sampleBuffer)
        }

        var requestHandlerOptions: [VNImageOption: AnyObject] = [:]

        let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil)
        if cameraIntrinsicData != nil {
            requestHandlerOptions[VNImageOption.cameraIntrinsics] = cameraIntrinsicData
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to obtain a CVPixelBuffer for the current output frame.")
            return
        }

        guard let requests = self.trackingRequests, !requests.isEmpty else {
            // No tracking object detected, so perform initial detection
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                            options: requestHandlerOptions)

            do {
                guard let detectRequests = self.detectionRequests else {
                    return
                }
                try imageRequestHandler.perform(detectRequests)
            } catch let error as NSError {
                NSLog("Failed to perform FaceRectangleRequest: %@", error)
            }
            return
        }

        do {
            try self.sequenceRequestHandler.perform(requests,
                                                    on: pixelBuffer)
        } catch let error as NSError {
            NSLog("Failed to perform SequenceRequest: %@", error)
        }

        // Setup the next round of tracking.
        var newTrackingRequests = [VNTrackObjectRequest]()
        for trackingRequest in requests {

            guard let results = trackingRequest.results else {
                return
            }

            guard let observation = results[0] as? VNDetectedObjectObservation else {
                return
            }

            if !trackingRequest.isLastFrame {
                if observation.confidence > 0.3 {
                    trackingRequest.inputObservation = observation
                } else {
                    trackingRequest.isLastFrame = true
                }
                newTrackingRequests.append(trackingRequest)
            }
        }
        self.trackingRequests = newTrackingRequests

        if newTrackingRequests.isEmpty {
            // Nothing to track, so abort.
            self.faceDetected = false
            self.faceAnalyzed = false
            return
        }

        // Perform face landmark tracking on detected faces.
        var faceLandmarkRequests = [VNDetectFaceLandmarksRequest]()

        // Perform landmark detection on tracked faces.
        for trackingRequest in newTrackingRequests {

            let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request, error) in

                if error != nil {
                    print("FaceLandmarks error: \(String(describing: error)).")
                }

                guard let landmarksRequest = request as? VNDetectFaceLandmarksRequest,
                    let results = landmarksRequest.results as? [VNFaceObservation] else {
                        return
                }

                if self.timeToUploadImage || self.saveImage {
                    self.uploadDetectedFace(sampleBuffer: sampleBuffer)
                }

                // Perform all UI updates (drawing) on the main queue, not the background queue on which this handler is being called.
                DispatchQueue.main.async {
                    self.faceDetected = true
                    self.drawFaceObservations(results)
                }

                if !self.faceAnalyzed && self.faceDetected {
                    DispatchQueue.main.async {
                        self.emotionAnalysis(results)
                    }
                }
            })

            guard let trackingResults = trackingRequest.results else {
                self.faceDetected = false
                self.faceAnalyzed = false
                return
            }

            guard let observation = trackingResults[0] as? VNDetectedObjectObservation else {
                return
            }
            let faceObservation = VNFaceObservation(boundingBox: observation.boundingBox)
            faceLandmarksRequest.inputFaceObservations = [faceObservation]

            // Continue to track detected facial landmarks.
            faceLandmarkRequests.append(faceLandmarksRequest)

            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                            options: requestHandlerOptions)

            do {
                try imageRequestHandler.perform(faceLandmarkRequests)
            } catch let error as NSError {
                NSLog("Failed to perform FaceLandmarkRequest: %@", error)
                self.faceDetected = false
            }
        }
    }

    func uploadFrame(sampleBuffer: CMSampleBuffer) {
        guard let image = getImageFromSampleBuffer( sampleBuffer: sampleBuffer) else {
            return
        }

        if compositeOverlays {
            let overlaysImage = detectionOverlayLayer?.image()
            let combinedImage = NSImage(size: image.size)
            // Draw the images into a new image!
            combinedImage.lockFocus()
            let rect = CGRect(origin: CGPoint.zero, size: image.size)
            // draw the video frame
            image.draw(at: CGPoint.zero, from: rect, operation: .sourceOver, fraction: 1.0)
            // draw the overlays
            overlaysImage!.draw(at: CGPoint.zero, from: rect, operation: .sourceOver, fraction: 1.0)
            combinedImage.unlockFocus()
            convertAndUploadImage(sourceImage: combinedImage)
        } else {
            convertAndUploadImage(sourceImage: image)
        }
    }

    func convertAndUploadImage(sourceImage: NSImage) {
        if uploadSmallerImagesPref {
            let reducedSize = CGSize(width: 0.25 * sourceImage.size.width, height: 0.25 * sourceImage.size.height)
            if let resizedImage = sourceImage.resized(to: reducedSize) {
                if let tiff = resizedImage.tiffRepresentation,
                    let imageRep = NSBitmapImageRep(data: tiff)  {
                    let compressedData = imageRep.representation(using: .jpeg, properties: [.compressionFactor : 0.5])!
                    uploadImageToFirebase(data: compressedData)
                }
            }
        } else {
            if let tiff = sourceImage.tiffRepresentation,
                let imageRep = NSBitmapImageRep(data: tiff)  {
                let compressedData = imageRep.representation(using: .jpeg, properties: [.compressionFactor : 0.5])!
                uploadImageToFirebase(data: compressedData)
            }
        }
    }

    func uploadDetectedFace(sampleBuffer: CMSampleBuffer) {
        var image: NSImage

        guard let videoImage = getImageFromSampleBuffer( sampleBuffer: sampleBuffer) else {
            return
        }

        if compositeOverlays {
            guard let overlaysImage = detectionOverlayLayer?.image() else {
                return
            }

            guard let resizedOverlayImage = overlaysImage.resized(to: videoImage.size) else {
                return
            }

            let combinedImage = NSImage(size: videoImage.size)

            // Draw the images into a new image!
            combinedImage.lockFocus()
            let rect = CGRect(origin: CGPoint.zero, size: videoImage.size)

            // draw the video frame
            videoImage.draw(at: CGPoint.zero, from: rect, operation: .sourceOver, fraction: 1.0)

            // draw the overlays
            resizedOverlayImage.draw(at: CGPoint.zero, from: rect, operation: .sourceOver, fraction: 1.0)

            combinedImage.unlockFocus()
            image = combinedImage
        } else {
            image = videoImage
        }

        if uploadSmallerImagesPref {
            let reducedSize = CGSize(width: 0.25 * image.size.width, height: 0.25 * image.size.height)
            if let resizedImage = image.resized(to: reducedSize) {
               image = resizedImage
            }
        }

        if let tiff = image.tiffRepresentation,
            let imageRep = NSBitmapImageRep(data: tiff)  {
            let compressedData = imageRep.representation(using: .jpeg, properties: [.compressionFactor : 0.5])!

            if saveImage {
                saveImage = false
                saveFile(data: compressedData)
            }

            if timeToUploadImage {
                uploadImageToFirebase(data: compressedData)
            }
        }

        timeToUploadImage = false

        // do another image upload in 5 seconds
        if uploadDetectedFaces {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.timeToUploadImage = true
            }
        }
    }


    func getImageFromSampleBuffer(sampleBuffer: CMSampleBuffer) ->NSImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        guard let cgImage = context.makeImage() else {
            return nil
        }
        let image = NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        return image
    }

    // Firebase

    func signIn() {
        Auth.auth().signIn(withEmail: "info@jakelaffoley.co.uk", password: "biomexit123") { [weak self] user, error in
            if self != nil {
                print("logged into Firebase")
            }
        }
    }

    func uploadImageToFirebase(data: Data) {
        // Create a root reference
        let storageRef = Storage.storage().reference()

        #if DEBUG
        let imageRef = storageRef.child("facesDebug/" + randomString(length: 20) + ".jpg")
        #else
        let imageRef = storageRef.child("faces/" + randomString(length: 20) + ".jpg")
        #endif

        imageRef.putData(data, metadata: nil) { metadata, error in

            if error != nil{
                print(error?.localizedDescription as Any)
                return
            }

            if metadata == nil {
                // Uh-oh, an error occurred!
                print("putData completed with no meta data")
                return
            }
            // Metadata contains file metadata such as size, content-type.
            // let size = metadata.size
            // You can also access to download URL after upload.
            imageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    print("no download URL?")
                    return
                }

                // Add the image to the database
                let db = Firestore.firestore()
                let randomName = randomString(length: 20)

                if self.faceAnalyzed && self.displayText != "" {
                    db.collection(self.collectionName).document(randomName).setData([
                        "url": downloadURL.absoluteString,
                        "date": Timestamp(),
                        "analysis" : self.displayText
                    ]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                        }
                    }
                } else {
                    db.collection(self.collectionName).document(randomName).setData([
                        "url": downloadURL.absoluteString,
                        "date": Timestamp()
                    ]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                        }
                    }
                }
            }
        }
    }

    func getDevicePreference() -> String? {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: Constants.DeviceNamePref)
    }

    @objc func changeCameraDevice() {
        teardownAVCapture()
        self.session = self.setupAVCaptureSession()
        self.prepareVisionRequest()
        self.session?.startRunning()
    }

    func saveFile(data: Data) {
        guard let desktopPath = (NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true) as [String]).first else {
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd_hh_mm_ss"
        let dateString = (formatter.string(from: Date()) as NSString) as String
        let file = desktopPath + "/detected face image " + dateString + ".jpg"
        let url = URL(fileURLWithPath: file)

        try! data.write(to: url, options: .atomicWrite)
    }

    func loadAnalysisText() {
        do {
            // This solution assumes  you've got the file in your bundle
            if let path = Bundle.main.path(forResource: "analysis", ofType: "txt"){
                let data = try String(contentsOfFile:path, encoding: String.Encoding.utf8)
                analysisLabels = data.components(separatedBy: "\n")

                // more frequently used annotations appear 3 times in the indices array
                for i in stride(from: 0, to: analysisLabels.count, by: 1) {
                    if i < startLessFrequentText {
                        indices.append(i)
                        indices.append(i)
                        indices.append(i)
                    } else {
                        indices.append(i)
                    }
                }
            }
        } catch let err as NSError {
            // TODO: do something with Error
            print(err)
        }
    }

    func emotionAnalysis(_ faceObservations: [VNFaceObservation]) {
        if analysisLabels.count > 0 {
            displayText = ""
            if let random = indices.randomElement() {
                let text = analysisLabels[random]
                faceAnalyzed = true
                displayText = text
            }
        }
    }

    @objc func runTimedCode() {
        if faceDetected {
            resultTextField.stringValue = displayText
        } else {
            resultTextField.stringValue = ""
        }
    }

    func getLineWidthPreference() -> Float? {
        let defaults = UserDefaults.standard
        var value = defaults.float(forKey: Constants.OverlayLineWidthPref)

        if value == 0 {
            value = 1
        }

        return value
    }

    func updateAnnotationPosition(faceBounds: CGRect) {
        leadingConstraint.constant = faceBounds.origin.x - resultTextField.frame.size.width/2
        topConstraint.constant = faceBounds.origin.y + faceBounds.size.height
    }
}
