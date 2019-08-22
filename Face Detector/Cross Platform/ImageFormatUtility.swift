#if os(OSX)
    import Cocoa
#else
    import UIKit
#endif

#if os(OSX)
    extension NSImage {
        /// Return PNG representation data for image
        var pngData: Data? {
            var imageRect = CGRect(origin: .zero, size: size)
            guard let cgImage = cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
                else { return nil }
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            bitmapRep.size = size
            return bitmapRep.representation(using: .png, properties: [:])
        }
    }
#else
    extension UIImage {
        /// Return PNG representation data for image
        var pngData: Data? {
            return UIImagePNGRepresentation(self)
        }
    }
#endif
