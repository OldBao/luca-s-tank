import Cocoa
import SpriteKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let windowWidth = Constants.windowWidth
        let windowHeight = Constants.windowHeight

        let contentRect = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Battle City"
        window.center()
        window.isReleasedWhenClosed = false
        window.backgroundColor = .black

        let skView = SKView(frame: contentRect)
        skView.ignoresSiblingOrder = true
        // skView.showsFPS = true
        // skView.showsNodeCount = true

        window.contentView = skView

        let scene = MenuScene(size: CGSize(width: Constants.logicalWidth, height: Constants.logicalHeight))
        scene.scaleMode = .aspectFit
        skView.presentScene(scene)

        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
