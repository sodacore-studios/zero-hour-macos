// Reproducible text artwork for the sodacore studios startup card.
import AppKit
import CoreText
import ImageIO
let width=4096, height=512
let context=CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
let font=CTFontCreateWithName("Arial-BoldMT" as CFString,480,nil)
let attributes:[NSAttributedString.Key:Any]=[.font:font,.foregroundColor:NSColor.white]
let line=CTLineCreateWithAttributedString(NSAttributedString(string:"sodacore studios",attributes:attributes))
let bounds=CTLineGetBoundsWithOptions(line,[.useGlyphPathBounds])
let scale=min(CGFloat(width-128)/bounds.width,CGFloat(height-96)/bounds.height)
context.translateBy(x:CGFloat(width)/2,y:CGFloat(height)/2)
context.scaleBy(x:scale,y:scale)
context.textPosition=CGPoint(x:-bounds.midX,y:-bounds.midY)
CTLineDraw(line,context)
let image=context.makeImage()!
let output=URL(fileURLWithPath:CommandLine.arguments[1])
let destination=CGImageDestinationCreateWithURL(output as CFURL,"public.png" as CFString,1,nil)!
CGImageDestinationAddImage(destination,image,nil)
precondition(CGImageDestinationFinalize(destination))
