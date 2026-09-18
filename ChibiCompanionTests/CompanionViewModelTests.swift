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
}
