// Convert the supplied artwork into macOS icon sizes, preserving its aspect ratio.
import AppKit
let source=NSImage(contentsOfFile:CommandLine.arguments[1])!
let output=URL(fileURLWithPath:CommandLine.arguments[2],isDirectory:true)
try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
for size in [16,32,128,256,512] {
 for factor in [1,2] {
  let pixels=size*factor
  let rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:pixels,pixelsHigh:pixels,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
  rep.size=NSSize(width:pixels,height:pixels)
  let context=NSGraphicsContext(bitmapImageRep:rep)!
  NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=context
  context.imageInterpolation = .high
  let scale=min(CGFloat(pixels)/source.size.width,CGFloat(pixels)/source.size.height)
  let width=source.size.width*scale,height=source.size.height*scale
  source.draw(in:NSRect(x:(CGFloat(pixels)-width)/2,y:(CGFloat(pixels)-height)/2,width:width,height:height),from:.zero,operation:.copy,fraction:1)
  NSGraphicsContext.restoreGraphicsState()
  let name="icon_\(size)x\(size)"+(factor==2 ? "@2x" : "")+".png"
  try rep.representation(using:.png,properties:[:])!.write(to:output.appendingPathComponent(name))
 }
}
