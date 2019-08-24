import Cocoa
import Preferences

final class VideoCameraPreferenceViewController: NSViewController, PreferencePane {
	let preferencePaneIdentifier = PreferencePane.Identifier.video
	let preferencePaneTitle = "Video Camera"
	let toolbarItemIcon = NSImage(named: NSImage.advancedName)!

	override var nibName: NSNib.Name? {
		return "VideoCameraPreferenceViewController"
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		// Setup stuff here
	}
}
