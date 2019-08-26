//
//  AppDelegate.swift
//  Face Detector
//
//  Created by Manjit Bedi on 2019-08-20.
//  Copyright © 2019 Noorg. All rights reserved.
//

import Cocoa
import FirebaseCore
import Preferences

extension PreferencePane.Identifier {
    static let general = Identifier("general")
    static let video = Identifier("video")
}

struct Constants {
    static let DeviceNamePref = "com.noorg.deviceName"
    static let ChangeDeviceNotification = "com.noorg.changeDevice"
    static let ShowPrefsAtStartPref = "com.noorg.showPrefsAtStart"
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var preferencesStyle: PreferencesStyle {
        get {
            return PreferencesStyle.preferencesStyleFromUserDefaults()
        }
        set {
            newValue.storeInUserDefaults()
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        print("\(#function)")

        // Use Firebase library to configure APIs
        FirebaseApp.configure()

        configurePreferences()

        let defaults = UserDefaults.standard
        let showPrefs = defaults.bool(forKey: Constants.ShowPrefsAtStartPref)
        if showPrefs {
            preferencesWindowController.show(preferencePane: .video)
        }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {

    }


    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    lazy var preferences: [PreferencePane] = [
        GeneralPreferenceViewController(),
        VideoCameraPreferenceViewController()
    ]

    lazy var preferencesWindowController = PreferencesWindowController(
        preferencePanes: preferences,
        style: preferencesStyle,
        animated: true,
        hidesToolbarForSingleItem: true
    )

    @IBAction private func preferencesMenuItemActionHandler(_ sender: NSMenuItem) {
        preferencesWindowController.show()
    }

    @IBAction private func switchStyle(_ sender: Any) {
        preferencesStyle = preferencesStyle == .segmentedControl
            ? .toolbarItems
            : .segmentedControl

        NSApp.relaunch()
    }

    func configurePreferences() {
        UserDefaults.standard.register(defaults: [
            Constants.ShowPrefsAtStartPref: true,
            ])
    }
}

