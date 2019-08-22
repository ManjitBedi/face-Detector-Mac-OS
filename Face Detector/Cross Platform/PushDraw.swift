#if os(macOS)
    import Cocoa
    
    public func pushDraw(in context: Any? = nil,
                         applying actions: () -> Void)
    {
        NSGraphicsContext.saveGraphicsState()
        actions()
        NSGraphicsContext.restoreGraphicsState()
    }
#else
    import UIKit
    
    public func pushDraw(in context: UIGraphicsImageRendererContext,
                         applying actions: () -> Void)
    {
        context.cgContext.saveGState()
        actions()
        context.cgContext.restoreGState()
    }
#endif

