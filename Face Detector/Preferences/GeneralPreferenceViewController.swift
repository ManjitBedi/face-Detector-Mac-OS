import Cocoa
import Preferences

final class GeneralPreferenceViewController: NSViewController, PreferencePane {

    @IBOutlet weak var showPrefsCheckBox: NSButton!

    @IBOutlet weak var strokeThicknessSlider: NSSlider!

    @IBOutlet weak var lineWidthLabel: NSTextField!
    
    let preferencePaneIdentifier = PreferencePane.Identifier.general
	let preferencePaneTitle = "General"
	let toolbarItemIcon = NSImage(named: NSImage.preferencesGeneralName)!

	override var nibName: NSNib.Name? {
		return "GeneralPreferenceViewController"
	}

	override func viewDidLoad() {
		super.viewDidLoad()

        print("view \(view.frame)")

		// Setup stuff here
        let defaults = UserDefaults.standard
        let showPrefs = defaults.bool(forKey: Constants.ShowPrefsAtStartPref)
        showPrefsCheckBox.state = showPrefs ? NSControl.StateValue.on : NSControl.StateValue.off
        // strokeThicknessSlider.floatValue = defaults.float(forKey: Constants.OverlayLineWidthPref)
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
        print("new width \(lineWidth)")
        lineWidthLabel.stringValue = String(lineWidth)
        let defaults = UserDefaults.standard
        defaults.set(lineWidth, forKey: Constants.OverlayLineWidthPref)
    }
}
