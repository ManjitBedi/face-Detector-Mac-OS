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
    static let OverlayLineWidthPref = "com.noorg.overlayLineWidth"
    static let AnnotationPositionRelativePref = "com.noorg.positionRelative"
    static let UploadSmallerImagesPref = "com.noorg.uploadSmaller"
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

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
        animated: true,
        hidesToolbarForSingleItem: true
    )

    @IBAction private func preferencesMenuItemActionHandler(_ sender: NSMenuItem) {
        preferencesWindowController.show()
    }

    func configurePreferences() {
        UserDefaults.standard.register(defaults: [
            Constants.ShowPrefsAtStartPref: true,
            Constants.OverlayLineWidthPref: 1.0,
            Constants.AnnotationPositionRelativePref: false,
            Constants.UploadSmallerImagesPref: false
            ])
    }
}

