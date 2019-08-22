/*
 
 Erica Sadun, http://ericasadun.com
 Cross Platform Defines
 
 Apple Platforms Only
 Will update to #if canImport() when available
 
 */

import Foundation

// Frameworks
#if os(OSX)
    import Cocoa
#else
    import UIKit
#endif

// UIKit/Cocoa Classes
#if os(OSX)
    public typealias View = NSView
    public typealias Font = NSFont
    public typealias Color = NSColor
    public typealias Image = NSImage
    public typealias BezierPath = NSBezierPath
    public typealias ViewController = NSViewController
#else
    public typealias View = UIView
    public typealias Font = UIFont
    public typealias Color = UIColor
    public typealias Image = UIImage
    public typealias BezierPath = UIBezierPath
    public typealias ViewController = UIViewController
#endif
