import XCTest
@testable import ChibiCompanion

final class CompanionViewModelTests: XCTestCase {
    var viewModel: CompanionViewModel!

    override func setUp() {
        super.setUp()
        viewModel = CompanionViewModel()
        viewModel.stopTimers()
    }

    override func tearDown() {
        viewModel.stopTimers()
        viewModel = nil
        UserDefaults.standard.removeObject(forKey: "MovementSpeed")
        UserDefaults.standard.removeObject(forKey: "IsSoundEnabled")
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(viewModel.currentState, .idle)
        XCTAssertEqual(viewModel.position, CGPoint(x: 200, y: 200))
        XCTAssertTrue(viewModel.isFacingRight)
        XCTAssertEqual(viewModel.currentFrameIndex, 0)
    }

    func testMoveTowardsRight() {
        let initialPosition = viewModel.position
        let target = CGPoint(x: initialPosition.x + 100, y: initialPosition.y)
        
        viewModel.moveTowards(target: target)
        
        XCTAssertGreaterThan(viewModel.position.x, initialPosition.x)
        XCTAssertTrue(viewModel.isFacingRight)
    }

    func testMoveTowardsLeftSetsFacingRightFalse() {
        let initialPosition = viewModel.position
        let target = CGPoint(x: initialPosition.x - 100, y: initialPosition.y)
        
        viewModel.moveTowards(target: target)
        
        XCTAssertLessThan(viewModel.position.x, initialPosition.x)
        XCTAssertFalse(viewModel.isFacingRight)
    }

    func testStartWalkingChangesState() {
        viewModel.startWalking()
        XCTAssertEqual(viewModel.currentState, .walking)
    }

    func testUpdateAnimationFrameCycles() {
        XCTAssertEqual(viewModel.currentFrameIndex, 0)
        viewModel.updateAnimationFrame()
        XCTAssertEqual(viewModel.currentFrameIndex, 1)
        viewModel.updateAnimationFrame()
        XCTAssertEqual(viewModel.currentFrameIndex, 2)
        viewModel.updateAnimationFrame()
        XCTAssertEqual(viewModel.currentFrameIndex, 3)
        viewModel.updateAnimationFrame()
        XCTAssertEqual(viewModel.currentFrameIndex, 0)
    }

    func testHandleTapTransitionsToPlaying() {
        viewModel.handleTap()
        XCTAssertEqual(viewModel.currentState, .playing)
    }

    func testMovementSpeedPersistence() {
        viewModel.movementSpeed = .fast
        XCTAssertEqual(UserDefaults.standard.double(forKey: "MovementSpeed"), MovementSpeed.fast.rawValue)
        
        let newVM = CompanionViewModel()
        newVM.stopTimers()
        XCTAssertEqual(newVM.movementSpeed, .fast)
    }

    func testIsSoundEnabledPersistence() {
        viewModel.isSoundEnabled = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "IsSoundEnabled"))
        
        let newVM = CompanionViewModel()
        newVM.stopTimers()
        XCTAssertFalse(newVM.isSoundEnabled)
    }

    func testIdleTransitionToSleepingWhenTicksExceedThreshold() {
        viewModel.currentState = .idle
        viewModel.position = CGPoint(x: 10000, y: 10000)
        
        for _ in 0...600 {
            viewModel.update()
        }
        
        XCTAssertEqual(viewModel.currentState, .sleeping)
    }

    func testSleepingWakeUpWhenMouseIsClose() {
        viewModel.currentState = .sleeping
        let mouseLocation = NSEvent.mouseLocation
        viewModel.position = CGPoint(x: mouseLocation.x + 10, y: mouseLocation.y + 10)
        
        viewModel.update()
        
        XCTAssertEqual(viewModel.currentState, .idle)
    }
}
