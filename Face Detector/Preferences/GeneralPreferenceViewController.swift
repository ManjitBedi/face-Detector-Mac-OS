import Cocoa
import Preferences
import SwiftyUserDefaults

final class GeneralPreferenceViewController: NSViewController, PreferencePane {

    @IBOutlet weak var showPrefsButton: NSButton!

    @IBOutlet weak var strokeThicknessSlider: NSSlider!

    @IBOutlet weak var lineWidthLabel: NSTextField!
    
    @IBOutlet weak var useRelativePositionButton: NSButton!

    @IBOutlet weak var uploadSmallerImagesButton: NSButton!

    @IBOutlet weak var confidenceThresholdSlider: NSSlider!
    @IBOutlet weak var confidenceThresholdLabel: NSTextField!

    @IBOutlet weak var uploadPeriodSlider: NSSlider!
    @IBOutlet weak var uploadPeriodLabel: NSTextField!

    @IBOutlet weak var hideOverlayWhenNoFacesDetectedButton: NSButton!


    let preferencePaneIdentifier = PreferencePane.Identifier.general
	let preferencePaneTitle = "General"
	let toolbarItemIcon = NSImage(named: NSImage.preferencesGeneralName)!

	override var nibName: NSNib.Name? {
		return "GeneralPreferenceViewController"
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		// Setup stuff here
        let showPrefs = Defaults[.showPrefsPane]
        showPrefsButton.state = showPrefs ? NSControl.StateValue.on : NSControl.StateValue.off
        let strokeWidth = Float(Defaults[.strokeWidth])
        strokeThicknessSlider.floatValue = Float(Defaults[.strokeWidth])
        lineWidthLabel.stringValue = String(format: "%.01f", strokeWidth)
        let displayRelativePref = Defaults[.annotationPositionRelative]
        useRelativePositionButton.state = displayRelativePref ? NSControl.StateValue.on : NSControl.StateValue.off
        let uploadSmallerImagesPref = Defaults[.uploadSmallerImages]
        uploadSmallerImagesButton.state = uploadSmallerImagesPref ? NSControl.StateValue.on : NSControl.StateValue.off
        let timePeriod = Float(Defaults[.uploadTimePeriod])
        uploadPeriodSlider.floatValue = timePeriod
        uploadPeriodLabel.stringValue = String(format: "%.01f", timePeriod)
        let threshold = Float(Defaults[.trackingConfidenceThreshold])
        confidenceThresholdSlider.floatValue = threshold
        confidenceThresholdLabel.stringValue = String(format: "%.01f", threshold)
	}

    @IBAction func updatePrefs(_ sender: NSButton) {
        let showPrefsPane = Bool(truncating: NSNumber(value: sender.state.rawValue))
        Defaults[.showPrefsPane] = showPrefsPane
    }

    @IBAction func updateStrokeThickness(_ sender: Any) {
        var lineWidth: Float = 1.0
        let slider = sender as! NSSlider
        lineWidth = slider.floatValue
        lineWidthLabel.stringValue =  String(format: "%.01f", lineWidth)
        Defaults[.strokeWidth] = Double(lineWidth)
    }

    @IBAction func updateUseRelativePositionPrefs(_ sender: NSButton) {
        let useRelativePosition = Bool(truncating: NSNumber(value: sender.state.rawValue))
        Defaults[.annotationPositionRelative] = useRelativePosition
    }

    @IBAction func updateUploadSmallerImagesPref(_ sender: NSButton) {
        let uploadSmallerImages = Bool(truncating: NSNumber(value: sender.state.rawValue))
        Defaults[.uploadSmallerImages] = uploadSmallerImages
    }

    @IBAction func updateTrackingConfidence(_ sender: NSSlider) {
        let threshold = sender.floatValue
        confidenceThresholdLabel.stringValue =  String(format: "%.01f", threshold)
        Defaults[.trackingConfidenceThreshold] = Double(threshold)
    }

    @IBAction func updateUploadPeriod(_ sender: NSSlider) {
        let uploadPeriod = sender.floatValue
        uploadPeriodLabel.stringValue =  String(format: "%.01f", uploadPeriod)
        Defaults[.uploadTimePeriod] = Double(uploadPeriod)
    }

    @IBAction func updateHideOverlayAction(_ sender: NSButton) {
        let hideOverlaysWhenNoFaces = Bool(truncating: NSNumber(value: sender.state.rawValue))
        Defaults[.hideOverlayWhenNoFacesDetected] = hideOverlaysWhenNoFaces
    }
}
