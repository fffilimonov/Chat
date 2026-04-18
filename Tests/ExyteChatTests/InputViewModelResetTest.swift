import XCTest
@testable import ExyteChat

/// Guards the fix for upstream issue #210 (drafted text sometimes remaining
/// in the TextField after send). The root cause was `reset()` and
/// `sendMessage()` wrapping their state mutations in `DispatchQueue.main.async`,
/// which added a runloop hop that raced with SwiftUI's re-render of the
/// multiline TextField (axis: .vertical). This test verifies that the
/// mutations are now synchronous — `text` must be cleared immediately after
/// `reset()` returns, with no additional runloop ticks needed.
@MainActor
final class InputViewModelResetTest: XCTestCase {

    func testResetClearsTextSynchronously() async {
        let vm = InputViewModel()
        vm.text = "draft message"
        XCTAssertEqual(vm.text, "draft message")

        vm.reset()

        // No await, no runloop tick. If the implementation dispatches async,
        // this assertion fires before the clear and the test fails.
        XCTAssertEqual(vm.text, "", "reset() must clear text synchronously, not via DispatchQueue.main.async")
    }

    func testResetClearsAttachmentsAndStateSynchronously() async {
        let vm = InputViewModel()
        vm.text = "some draft"
        vm.showPicker = true
        vm.showGiphyPicker = true
        vm.state = .editing

        vm.reset()

        XCTAssertEqual(vm.text, "")
        XCTAssertFalse(vm.showPicker)
        XCTAssertFalse(vm.showGiphyPicker)
        XCTAssertEqual(vm.state, .empty)
    }

    func testRepeatedResetsDoNotReintroduceStaleText() async {
        let vm = InputViewModel()

        for i in 0..<50 {
            vm.text = "message \(i)"
            vm.reset()
            XCTAssertEqual(vm.text, "", "Iteration \(i): text should be empty after reset")
        }
    }
}
