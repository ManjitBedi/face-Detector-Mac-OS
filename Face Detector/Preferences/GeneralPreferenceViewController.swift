import Cocoa
import Preferences

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

    let preferencePaneIdentifier = PreferencePane.Identifier.general
	let preferencePaneTitle = "General"
	let toolbarItemIcon = NSImage(named: NSImage.preferencesGeneralName)!

	override var nibName: NSNib.Name? {
		return "GeneralPreferenceViewController"
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		// Setup stuff here
        let defaults = UserDefaults.standard
        let showPrefs = defaults.bool(forKey: Constants.ShowPrefsAtStartPref)
        showPrefsButton.state = showPrefs ? NSControl.StateValue.on : NSControl.StateValue.off
        strokeThicknessSlider.floatValue = defaults.float(forKey: Constants.OverlayLineWidthPref)
        let displayRelativePref = defaults.bool(forKey: Constants.AnnotationPositionRelativePref)
        useRelativePositionButton.state = displayRelativePref ? NSControl.StateValue.on : NSControl.StateValue.off
        let uploadSmallerImagesPref = defaults.bool(forKey: Constants.UploadSmallerImagesPref)
        uploadSmallerImagesButton.state = uploadSmallerImagesPref ? NSControl.StateValue.on : NSControl.StateValue.off
	}

    @IBAction func updatePrefs(_ sender: NSButton) {
        let showPrefsPane = Bool(truncating: NSNumber(value: sender.state.rawValue))
        let defaults = UserDefaults.standard
        defaults.set(showPrefsPane, forKey: Constants.ShowPrefsAtStartPref)
    }


    @IBAction func updateStrokeThickness(_ sender: Any) {
        var lineWidth: Float = 1.0
        let slider = sender as! NSSlider
        lineWidth = slider.floatValue
        lineWidthLabel.stringValue =  String(format: "%.01f", lineWidth)
        let defaults = UserDefaults.standard
        defaults.set(lineWidth, forKey: Constants.OverlayLineWidthPref)
    }

    @IBAction func updateUseRelativePositionPrefs(_ sender: NSButton) {
        let useRelativePosition = Bool(truncating: NSNumber(value: sender.state.rawValue))
        let defaults = UserDefaults.standard
        defaults.set(useRelativePosition, forKey: Constants.AnnotationPositionRelativePref)
    }

    @IBAction func updateUploadSmallerImagesPref(_ sender: NSButton) {
        let uploadSmallerImages = Bool(truncating: NSNumber(value: sender.state.rawValue))
        let defaults = UserDefaults.standard
        defaults.set(uploadSmallerImages, forKey: Constants.UploadSmallerImagesPref)
    }

    @IBAction func updateTrackingConfidence(_ sender: NSSlider) {
        let threshold = sender.floatValue
        confidenceThresholdLabel.stringValue =  String(format: "%.01f", threshold)
    }

    @IBAction func updateUploadPeriod(_ sender: NSSlider) {
        let uploadPeriod = sender.floatValue
        uploadPeriodLabel.stringValue =  String(format: "%.01f", uploadPeriod)
    }
}
