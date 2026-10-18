import Cocoa

@MainActor final class Launcher: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    let folder = NSTextField(), server = NSTextField(), player = NSTextField(), relay = NSTextField()
    let invitation = NSSecureTextField()
    let wasd = NSButton(checkboxWithTitle: "Use WASD camera controls", target: nil, action: nil)
    let rightClickOrders = NSButton(checkboxWithTitle: "Left-click selects; right-click moves / attacks", target: nil, action: nil)
    let fullscreen = NSButton(checkboxWithTitle: "Start in fullscreen", target: nil, action: nil)
    let resolution = NSPopUpButton()
    let status = NSTextField(wrappingLabelWithString: "")
    let play = NSButton(title: "Start game", target: nil, action: nil)
    let updater = AppUpdater()
    var updateTimer: Timer?
    var settings = LaunchSettings()
    var child: Process?
    var logHandle: FileHandle?
    let fm = FileManager.default
    var home: URL {
        if let path = ProcessInfo.processInfo.environment["ZERO_HOUR_LAUNCHER_HOME"] { return URL(fileURLWithPath: path, isDirectory: true) }
        return fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Zero Hour", isDirectory: true)
    }
    var bundledGameRoot: URL? { LaunchSettings.bundledGameRoot(in: Bundle.main.resourceURL) }
    var configURL: URL { home.appendingPathComponent("Einstellungen.json") }
    var dataRoot: URL { home.appendingPathComponent("Benutzerdaten", isDirectory: true) }
    var optionsURL: URL { dataRoot.appendingPathComponent("Command and Conquer Generals Zero Hour Data/Options.ini") }

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        updater.idle = { [weak self] in self?.child == nil }
        updater.status = { [weak self] text in self?.status.stringValue = text }
        updater.lock = { [weak self] in self?.play.isEnabled = false }
        updater.prepare = { [weak self] in try self?.prepareForUpdate() }
        if let screen = NSScreen.main {
            let ratio = screen.frame.width / screen.frame.height
            if ratio > 3.0 { settings.resolution = "3840 x 1080" }
            else if ratio > 2.2 { settings.resolution = "2560 x 1080" }
        }
        if fm.fileExists(atPath: configURL.path) {
            do { settings = try JSONDecoder().decode(LaunchSettings.self, from: Data(contentsOf: configURL)) }
            catch { status.stringValue = "Saved settings could not be read. Please select them again." }
        }
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 740, height: 730), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Zero Hour – Launch and settings"
        window.delegate = self
        window.isReleasedWhenClosed = false
        let title = NSTextField(labelWithString: "ZERO HOUR")
        title.font = .systemFont(ofSize: 28, weight: .bold)
        let subtitle = NSTextField(labelWithString: "Generals Zero Hour for Apple Silicon")
        subtitle.textColor = .secondaryLabelColor
        folder.isEditable = false; folder.placeholderString = "Folder containing Generals and Zero Hour"
        server.placeholderString = "https://game.example.org (leave blank for single-player)"
        player.placeholderString = "Your name"
        relay.placeholderString = "Automatic: server hostname on port 3478"
        invitation.placeholderString = "Invitation code from the server operator"
        let browse = NSButton(title: "Browse …", target: self, action: #selector(chooseFolder))
        let folderRow = NSStackView(views: [folder, browse]); folderRow.orientation = .horizontal
        folder.widthAnchor.constraint(greaterThanOrEqualToConstant: 480).isActive = true
        resolution.addItems(withTitles: LaunchSettings.resolutions)
        let graphics = NSStackView(views: [resolution, fullscreen]); graphics.orientation = .horizontal; graphics.spacing = 22
        let controls = NSTextField(wrappingLabelWithString: "Arrow keys also work. WASD replaces unmodified W/A/S/D commands during a match; text entry is unchanged. ⌘ Return toggles fullscreen.")
        controls.font = .systemFont(ofSize: 12); controls.textColor = .secondaryLabelColor
        let network = NSTextField(wrappingLabelWithString: "For a private service, enter its server address and invitation code. Check the relay host after a server move. Settings apply when the next game starts.")
        network.font = .systemFont(ofSize: 12); network.textColor = .secondaryLabelColor
        let save = NSButton(title: "Save", target: self, action: #selector(saveSettings))
        let files = NSButton(title: "Open data folder", target: self, action: #selector(openData))
        play.target = self; play.action = #selector(startGame); play.bezelStyle = .rounded
        let actions = NSStackView(views: [files, save, play]); actions.orientation = .horizontal; actions.spacing = 16
        status.font = .systemFont(ofSize: 12); status.textColor = .secondaryLabelColor
        status.heightAnchor.constraint(greaterThanOrEqualToConstant: 34).isActive = true
        let stack = NSStackView(views: [title, subtitle, label(bundledGameRoot == nil ? "Game files from your installation" : "Game files included – ready to play"), folderRow,
            label("Resolution and display"), graphics, wasd, rightClickOrders, controls,
            label("Server address"), server, network,
            label("Player name and invitation code"), horizontal(player, invitation),
            label("Relay address (optional)"), relay, actions, status])
        stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        window.contentView!.addSubview(stack)
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 28), stack.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -28), stack.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 24)])
        for view in [folderRow, graphics, controls, server, network, relay, status] { view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true }
        folderRow.isHidden = bundledGameRoot != nil
        applySettings()
        if status.stringValue.isEmpty { status.stringValue = bundledGameRoot == nil ? "Select your game files once, save settings and start. Online play requires a configured private server." : "Ready. Choose Start game to play. Online play requires a configured private server." }
        window.center(); window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async { self.updater.check() }
        updateTimer = Timer.scheduledTimer(withTimeInterval: 21600, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updater.check() }
        }
    }
    func label(_ s: String) -> NSTextField { let l = NSTextField(labelWithString: s); l.font = .systemFont(ofSize: 12, weight: .semibold); return l }
    func horizontal(_ a: NSView, _ b: NSView) -> NSStackView { let s=NSStackView(views:[a,b]); s.orientation = .horizontal; s.spacing=14; a.widthAnchor.constraint(equalToConstant: 240).isActive=true; b.widthAnchor.constraint(equalToConstant: 430).isActive=true; return s }
    func buildMenu() {
        let bar = NSMenu(); let appItem = NSMenuItem(); let appMenu = NSMenu()
        let updates = NSMenuItem(title: "Updates …", action: #selector(updateSettings), keyEquivalent: "")
        updates.target = self; appMenu.addItem(updates)
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Zero Hour", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"); appItem.submenu=appMenu; bar.addItem(appItem)
        let editItem=NSMenuItem();editItem.title="Edit";let edit=NSMenu(title:"Edit")
        for (title,action,key) in [("Copy",#selector(NSText.copy(_:)),"c"),("Paste",#selector(NSText.paste(_:)),"v"),("Cut",#selector(NSText.cut(_:)),"x"),("Select All",#selector(NSText.selectAll(_:)),"a")] {edit.addItem(withTitle:title,action:action,keyEquivalent:key)}
        editItem.submenu=edit;bar.addItem(editItem);NSApp.mainMenu=bar
    }
    @objc func updateSettings() { updater.settings() }
    func prepareForUpdate() throws {
        try readSettings()
        if let root = bundledGameRoot {
            let destination = home.appendingPathComponent("Spieldaten", isDirectory: true)
            if !fm.fileExists(atPath: destination.path) {
                let temporary = home.appendingPathComponent("Spieldaten-" + UUID().uuidString)
                try fm.createDirectory(at: home, withIntermediateDirectories: true)
                defer { try? fm.removeItem(at: temporary) }
                try fm.copyItem(at: root, to: temporary)
                try fm.moveItem(at: temporary, to: destination)
            }
            var probe = settings; probe.gameFolder = destination.path
            _ = try probe.gameRoot()
            settings.gameFolder = destination.path
        }
        try persist()
    }
    func applySettings() {
        folder.stringValue=settings.gameFolder;server.stringValue=settings.server;player.stringValue=settings.playerName
        invitation.stringValue=settings.invitation;relay.stringValue=settings.relay
        wasd.state=settings.wasd ? .on : .off;fullscreen.state=settings.fullscreen ? .on : .off
        rightClickOrders.state=settings.usesRightClickOrders ? .on : .off
        resolution.selectItem(withTitle: settings.resolution)
    }
    func readSettings() throws {
        settings.gameFolder=bundledGameRoot == nil ? folder.stringValue : "";settings.server=server.stringValue.trimmingCharacters(in:.whitespacesAndNewlines)
        settings.playerName=player.stringValue.trimmingCharacters(in:.whitespacesAndNewlines)
        settings.invitation=invitation.stringValue.trimmingCharacters(in:.whitespacesAndNewlines);settings.relay=relay.stringValue
        settings.wasd=wasd.state == .on;settings.fullscreen=fullscreen.state == .on
        settings.rightClickOrders=rightClickOrders.state == .on
        settings.resolution=resolution.titleOfSelectedItem ?? "1920 x 1080"
        try settings.validate()
    }
    func persist() throws {
        try fm.createDirectory(at:home,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700])
        let encoder=JSONEncoder();encoder.outputFormatting=[.prettyPrinted,.sortedKeys]
        try encoder.encode(settings).write(to:configURL,options:.atomic)
        try fm.setAttributes([.posixPermissions:0o600],ofItemAtPath:configURL.path)
    }
    @objc func saveSettings() { do {try readSettings();try persist();status.stringValue="Saved. Changes apply when the next game starts."} catch {show(error)} }
    @objc func chooseFolder() {
        let panel=NSOpenPanel();panel.canChooseDirectories=true;panel.canChooseFiles=false;panel.allowsMultipleSelection=false
        panel.message="Choose the parent folder containing Generals and Zero Hour, or the Zero Hour folder itself."
        if panel.runModal() == .OK, let url=panel.url { folder.stringValue=url.path }
    }
    @objc func openData() { do {try fm.createDirectory(at:home,withIntermediateDirectories:true);NSWorkspace.shared.open(home)} catch {show(error)} }
    func show(_ error: Error) { let alert=NSAlert();alert.messageText="Check settings";alert.informativeText=error.localizedDescription;alert.runModal() }
    @objc func startGame() {
        guard child == nil else {status.stringValue="The game is already running.";return}
        do {
            try readSettings();let root=try settings.gameRoot(bundledRoot: bundledGameRoot);try persist()
            try fm.createDirectory(at:optionsURL.deletingLastPathComponent(),withIntermediateDirectories:true)
            let previous=(try? String(contentsOf:optionsURL,encoding:.utf8)) ?? ""
            let updated=updateOptions(previous,values:settings.gameOptions())
            try updated.write(to:optionsURL,atomically:true,encoding:.utf8)
            let process=Process()
            process.executableURL=Bundle.main.resourceURL!.appendingPathComponent("Engine.app/Contents/MacOS/GeneralsOnlineZH")
            process.currentDirectoryURL=home
            var env=ProcessInfo.processInfo.environment
            env["GENERALS_INSTALL_PATH"]=root.path;env["GENERALS_USER_DATA_ROOT"]=dataRoot.path
            env["GENERALS_MAC_DEBUG"]="0";env["GENERALS_MAC_DEBUG_CONSOLE"]="0"
            env["ZERO_HOUR_PRIVATE_SERVICE"]="1";env["ZERO_HOUR_SERVICE_URL"]=try settings.endpoint()
            env["ZERO_HOUR_PLAYER_NAME"]=settings.playerName;env["ZERO_HOUR_INVITATION"]=settings.invitation
            env["ZERO_HOUR_TURN_SERVERS"]=try settings.relayAddress();env["ZERO_HOUR_STUN_SERVERS"]=""
            env["ZERO_HOUR_FULLSCREEN"]=settings.fullscreen ? "1":"0";process.environment=env
            let logURL=home.appendingPathComponent("Spielstart.log")
            if !fm.fileExists(atPath:logURL.path){fm.createFile(atPath:logURL.path,contents:nil,attributes:[.posixPermissions:0o600])}
            let handle=try FileHandle(forWritingTo:logURL);try handle.seekToEnd();logHandle=handle
            process.standardOutput=handle;process.standardError=handle
            process.terminationHandler={ [weak self] process in DispatchQueue.main.async {
                guard let self=self else{return};self.child=nil;self.play.isEnabled=true
                try? self.logHandle?.close();self.logHandle=nil
                self.reloadResolution()
                self.status.stringValue=process.terminationStatus == 0 ? "Game finished. You can change settings now." : "The game exited (code \(process.terminationStatus)). See Spielstart.log in the data folder for details."
                self.window.makeKeyAndOrderFront(nil);NSApp.activate(ignoringOtherApps:true)
                self.updater.installIfIdle()
            }}
            child=process
            do {try process.run()} catch {child=nil;try? handle.close();throw error}
            play.isEnabled=false;status.stringValue="Game running. ⌘ Return toggles windowed/fullscreen mode."
            window.orderOut(nil)
        } catch { show(error) }
    }
    func reloadResolution() {
        guard let text=try? String(contentsOf:optionsURL,encoding:.utf8),let line=text.components(separatedBy:.newlines).first(where:{$0.hasPrefix("Resolution =")}) else{return}
        let dims=line.components(separatedBy:"=")[1].split(whereSeparator:{$0.isWhitespace}).map(String.init)
        guard dims.count==2 else{return};let value=dims.joined(separator:" x ")
        if LaunchSettings.resolutions.contains(value){settings.resolution=value;resolution.selectItem(withTitle:value);try? persist()}
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if child != nil {window.makeKeyAndOrderFront(nil);status.stringValue="Please exit the running match first.";return .terminateCancel}
        return .terminateNow
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {child == nil}
}
let application=NSApplication.shared
let delegate=MainActor.assumeIsolated { Launcher() }
application.setActivationPolicy(.regular)
application.delegate=delegate
application.run()
