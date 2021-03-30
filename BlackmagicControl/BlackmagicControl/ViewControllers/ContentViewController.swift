import Foundation
import AppKit

class ContentViewController: NSViewController {

    func returnToSelectView() {
        if let baseViewController = self.parent as? BaseViewController? {
            baseViewController?.switchToSelectView()
        }
    }
}
