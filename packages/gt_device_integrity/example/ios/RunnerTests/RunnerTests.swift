import Flutter
import UIKit
import XCTest

@testable import gt_device_integrity

/// Runs on the simulator, which must report itself and never a jailbreak.
class RunnerTests: XCTestCase {

  func testReportOnTheSimulator() {
    let plugin = GtDeviceIntegrityPlugin()
    let call = FlutterMethodCall(methodName: "report", arguments: nil)

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      let report = result as! [String: Any]
      XCTAssertEqual(report["platform"] as? String, "ios")
      XCTAssertEqual(report["emulator"] as? Bool, true)
      XCTAssertEqual(report["rooted"] as? Bool, false)
      XCTAssertNil(report["developerMode"])
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
