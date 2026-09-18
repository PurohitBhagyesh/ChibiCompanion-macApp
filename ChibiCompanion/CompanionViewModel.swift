import Foundation
import Combine
import SwiftUI
import AppKit

/// Enum representing the current behavior state of the desktop companion.
public enum CompanionState: String, CaseIterable, Codable {
    case idle
    case walking
    case chasingCursor
    case sleeping
    case playing
}

/// Movement speed settings for the companion.
public enum MovementSpeed: Double, CaseIterable, Codable {
    case slow = 2.0
    case normal = 4.0
    case fast = 8.0
}

/// ViewModel responsible for managing companion state, desktop movement, and user interactions.
public class CompanionViewModel: ObservableObject {
    @Published public var currentState: CompanionState = .idle
    @Published public var position: CGPoint = CGPoint(x: 200, y: 200)
    @Published public var isFacingRight: Bool = true
    @Published public var movementSpeed: MovementSpeed = .normal {
        didSet {
            UserDefaults.standard.set(movementSpeed.rawValue, forKey: userDefaultsSpeedKey)
        }
    }
    @Published public var isSoundEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: userDefaultsSoundKey)
        }
    }
    @Published public var currentFrameIndex: Int = 0

    private var timer: Timer?
    private var animationTimer: Timer?

    private let cursorProximityThreshold: CGFloat = 300.0
    private let interactionDistance: CGFloat = 30.0

    private var wanderTarget: CGPoint?
    public private(set) var idleTicks: Int = 0
    private let idleSleepThreshold: Int = 600 // ~10 seconds at 60 FPS

    private let userDefaultsSpeedKey = "MovementSpeed"
    private let userDefaultsSoundKey = "IsSoundEnabled"

    public init() {
        if let savedSpeed = UserDefaults.standard.object(forKey: userDefaultsSpeedKey) as? Double,
           let speed = MovementSpeed(rawValue: savedSpeed) {
            self.movementSpeed = speed
        }
        if UserDefaults.standard.object(forKey: userDefaultsSoundKey) != nil {
            self.isSoundEnabled = UserDefaults.standard.bool(forKey: userDefaultsSoundKey)
        }
        setupTimers()
    }

    deinit {
        stopTimers()
    }

    /// Stops active timers.
    public func stopTimers() {
        timer?.invalidate()
        timer = nil
        animationTimer?.invalidate()
        animationTimer = nil
    }

    /// Sets up update loop for behavior and animation frame updates.
    public func setupTimers() {
        stopTimers()

        // Main movement and logic loop (60 FPS)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.update()
        }
        
        // Sprite animation frame update (10 FPS)
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAnimationFrame()
        }
    }

    /// Primary update cycle handling position updates and state transitions.
    public func update() {
        let mouseLocation = NSEvent.mouseLocation
        let distanceToMouse = hypot(mouseLocation.x - position.x, mouseLocation.y - position.y)

        switch currentState {
        case .idle:
            idleTicks += 1
            if distanceToMouse < cursorProximityThreshold && distanceToMouse > interactionDistance {
                idleTicks = 0
                currentState = .chasingCursor
            } else if idleTicks > idleSleepThreshold {
                currentState = .sleeping
            } else if idleTicks % 180 == 0 && Double.random(in: 0...1) < 0.3 {
                startWalking()
            }

        case .chasingCursor:
            idleTicks = 0
            if distanceToMouse <= interactionDistance {
                currentState = .idle
            } else if distanceToMouse > cursorProximityThreshold * 1.5 {
                currentState = .idle
            } else {
                moveTowards(target: mouseLocation)
            }

        case .walking:
            idleTicks = 0
            if distanceToMouse < cursorProximityThreshold / 2.0 {
                wanderTarget = nil
                currentState = .chasingCursor
            } else if let target = wanderTarget {
                let distToTarget = hypot(target.x - position.x, target.y - position.y)
                if distToTarget <= interactionDistance {
                    wanderTarget = nil
                    currentState = .idle
                } else {
                    moveTowards(target: target)
                }
            } else {
                startWalking()
            }

        case .sleeping:
            if distanceToMouse < cursorProximityThreshold / 3.0 {
                idleTicks = 0
                currentState = .idle
            }

        case .playing:
            idleTicks = 0
        }
    }

    /// Initiates walking to a random point within primary screen bounds.
    public func startWalking() {
        let frame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 800, height: 600)
        let randomX = CGFloat.random(in: frame.minX...frame.maxX)
        let randomY = CGFloat.random(in: frame.minY...frame.maxY)
        wanderTarget = CGPoint(x: randomX, y: randomY)
        currentState = .walking
    }

    /// Moves companion position toward target point with current speed settings.
    public func moveTowards(target: CGPoint) {
        let dx = target.x - position.x
        let dy = target.y - position.y
        let distance = hypot(dx, dy)

        guard distance > 0 else { return }

        let vx = (dx / distance) * movementSpeed.rawValue
        let vy = (dy / distance) * movementSpeed.rawValue

        position.x += vx
        position.y += vy
        isFacingRight = dx > 0

        // Keep position within primary screen bounds
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            position.x = max(frame.minX, min(frame.maxX, position.x))
            position.y = max(frame.minY, min(frame.maxY, position.y))
        }
    }

    /// Cycle through sprite animation frames based on current state.
    public func updateAnimationFrame() {
        currentFrameIndex = (currentFrameIndex + 1) % 4
    }

    /// Trigger companion interaction response on tap or click.
    public func handleTap() {
        idleTicks = 0
        currentState = .playing
        if isSoundEnabled {
            playSoundEffect()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if self?.currentState == .playing {
                self?.currentState = .idle
            }
        }
    }

    /// Plays companion feedback audio.
    private func playSoundEffect() {
        NSSound.beep()
    }
}
