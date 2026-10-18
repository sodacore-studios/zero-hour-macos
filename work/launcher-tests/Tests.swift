import Foundation
func check(_ value: Bool, line: UInt = #line) { if !value { fatalError("Check failed at line \(line)") } }
@main struct Checks {
 static func main() throws {
  var s=LaunchSettings();s.server="https://example.org"
  check(try s.endpoint() == "https://example.org/env/prod/contract/1")
  s.server="https://example.org/custom/env/prod/contract/1/"
  check(try s.endpoint() == "https://example.org/custom/env/prod/contract/1")
  for value in ["http://example.org", "https://user:secret@example.org", "https://example.org?token=x", "https://example.org/#x", "https://example.org/a b", "file:///tmp", "https://"] {
   s.server=value;do{_ = try s.endpoint();fatalError("Accepted invalid URL")}catch{}
  }
  s.server="http://127.0.0.1:3097";check(try s.endpoint() == "http://127.0.0.1:3097/env/prod/contract/1")
  s.server="https://new.example.org";s.relay="";check(try s.relayAddress() == "new.example.org:3478")
  s.relay="relay.example.org:3479";check(try s.relayAddress() == "relay.example.org:3479")
  for value in ["relay.example.org", "relay.example.org:0", "relay.example.org:70000", "user:pass@relay.example.org:3478", "relay.example.org:3478/path"] {
   s.relay=value;do{_ = try s.relayAddress();fatalError("Accepted invalid relay")}catch{}
  }
  let text="Resolution = 800 600\nCustomOption = keep\nResolution = 1024 768\n"
  let result=updateOptions(text,values:["Resolution":"3840 1080","WASDMapScroll":"yes"])
  check(result.components(separatedBy:"Resolution =").count==2)
  check(result.contains("CustomOption = keep"));check(result.contains("Resolution = 3840 1080"))
  let temp=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  let zh=temp.appendingPathComponent("Zero Hour")
  try FileManager.default.createDirectory(at:zh,withIntermediateDirectories:true)
  defer{try? FileManager.default.removeItem(at:temp)}
  try Data().write(to:zh.appendingPathComponent("INIZH.big"))
  s.gameFolder=temp.path;check(try s.gameRoot().path==temp.path)
  s.gameFolder=zh.path;check(try s.gameRoot().path==temp.path)
  let resources=temp.appendingPathComponent("Complete.app/Contents/Resources")
  let embedded=resources.appendingPathComponent("Spieldaten/Zero Hour")
  try FileManager.default.createDirectory(at:embedded,withIntermediateDirectories:true)
  try Data().write(to:embedded.appendingPathComponent("INIZH.big"))
  s.gameFolder="/unavailable/old-computer/path"
  let detected=LaunchSettings.bundledGameRoot(in:resources)
  check(detected != nil)
  check(try s.gameRoot(bundledRoot:detected).path==embedded.deletingLastPathComponent().path)
  let moved=temp.appendingPathComponent("Installed.app")
  try FileManager.default.moveItem(at:resources.deletingLastPathComponent().deletingLastPathComponent(),to:moved)
  check(LaunchSettings.bundledGameRoot(in:resources)==nil)
  let relocated=LaunchSettings.bundledGameRoot(in:moved.appendingPathComponent("Contents/Resources"))
  check(relocated != nil)
  check(try LaunchSettings().gameRoot(bundledRoot:relocated).path.hasPrefix(moved.path))
  print("PASS: embedded data auto-detection, fresh install and app relocation")
  print("PASS: server URL validation/normalization, relay migration, settings preservation, both data-folder selections")
 }
}
