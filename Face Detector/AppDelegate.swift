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
import SwiftyUserDefaults

extension DefaultsKeys {
    static let deviceName = DefaultsKey<String?>("deviceName")
    static let showPrefsPane = DefaultsKey<Bool>("showPrefsPane", defaultValue: true)
    static let strokeWidth = DefaultsKey<Double>("strokeWidth", defaultValue: 2.0)
    static let uploadSmallerImages = DefaultsKey<Bool>("uploadSmallerImages", defaultValue: true)
    static let compositeOverlays = DefaultsKey<Bool>("compositeOverlays", defaultValue: true)
    static let uploadTimePeriod = DefaultsKey<Double>("uploadTimePeriod", defaultValue: 5.0)
    static let trackingConfidenceThreshold = DefaultsKey<Double>("TrackingConfidenceThreshold", defaultValue: 0.5)
    static let annotationPositionRelative = DefaultsKey<Bool>("annotationPositionRelative", defaultValue: false)
    static let hideOverlayWhenNoFacesDetected = DefaultsKey<Bool>("hideOverlayWhenNoFacesDetected", defaultValue: false)
}

extension PreferencePane.Identifier {
    static let general = Identifier("general")
    static let video = Identifier("video")
}


struct Constants {
    static let ChangeDeviceNotification = "com.noorg.changeDevice"
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        print("\(#function)")

        // Use Firebase library to configure APIs
        FirebaseApp.configure()

        let showPrefs = Defaults[.showPrefsPane]
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
}

