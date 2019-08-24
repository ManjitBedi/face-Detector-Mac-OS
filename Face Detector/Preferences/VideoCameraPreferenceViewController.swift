import Cocoa
import AVFoundation
import AVKit

import Preferences

final class VideoCameraPreferenceViewController: NSViewController, PreferencePane, NSTableViewDelegate, NSTableViewDataSource {
	let preferencePaneIdentifier = PreferencePane.Identifier.video
	let preferencePaneTitle = "Video Camera"
	let toolbarItemIcon = NSImage(named: NSImage.advancedName)!

    @IBOutlet weak var deviceNamesTableView: NSTableView!
    
    var deviceNames = [String]()

	override var nibName: NSNib.Name? {
		return "VideoCameraPreferenceViewController"
	}

	override func viewDidLoad() {
		super.viewDidLoad()

        deviceNamesTableView.delegate = self
        deviceNamesTableView.dataSource = self

        getVideoCameraDeviceNames()
	}

    func getVideoCameraDeviceNames() {
        // Get all audio and video devices on this machine
        let devices = AVCaptureDevice.devices()

        for device in devices {

            // Camera object found and assign it to captureDevice
            if ((device as AnyObject).hasMediaType(AVMediaType.video)) {
                print(device)
                deviceNames.append(device.localizedName)
            }
        }

        deviceNamesTableView.reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return deviceNames.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return deviceNames[row]
    }
}
