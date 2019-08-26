import Cocoa
import Preferences

final class GeneralPreferenceViewController: NSViewController, PreferencePane {

    @IBOutlet weak var showPrefsCheckBox: NSButton!

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
        showPrefsCheckBox.state = showPrefs ? NSControl.StateValue.on : NSControl.StateValue.off
	}

    @IBAction func updatePrefs(_ sender: NSButton) {
        let showPrefsPane = Bool(truncating: NSNumber(value: sender.state.rawValue))
        let defaults = UserDefaults.standard
        defaults.set(showPrefsPane, forKey: Constants.ShowPrefsAtStartPref)
    }
}
