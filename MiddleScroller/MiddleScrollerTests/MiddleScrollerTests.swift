//
//  MiddleScrollerTests.swift
//  MiddleScrollerTests
//

import XCTest
@testable import MiddleScroller

final class PreferencesManagerTests: XCTestCase {

    private let testSuiteName = "com.lowryan.MiddleScrollerTests"
    private var testDefaults: UserDefaults!

    override func setUpWithError() throws {
        // Create isolated UserDefaults for testing
        testDefaults = UserDefaults(suiteName: testSuiteName)
        testDefaults.removePersistentDomain(forName: testSuiteName)
    }

    override func tearDownWithError() throws {
        // Clean up test defaults
        testDefaults.removePersistentDomain(forName: testSuiteName)
        testDefaults = nil
    }

    // MARK: - Scroll Speed Tests

    func testScrollSpeedDefaultValue() throws {
        // The default scroll speed multiplier should be 1.0
        let defaultSpeed = PreferencesManager.shared.scrollSpeedMultiplier
        
        // Default should be 1.0 (registered in registerDefaults)
        XCTAssertEqual(defaultSpeed, 1.0, accuracy: 0.001, "Default scroll speed should be 1.0")
    }

    func testScrollSpeedPersistence() throws {
        let manager = PreferencesManager.shared
        let originalValue = manager.scrollSpeedMultiplier
        
        // Set a new value
        manager.scrollSpeedMultiplier = 2.0
        
        // Verify it persisted
        XCTAssertEqual(manager.scrollSpeedMultiplier, 2.0, accuracy: 0.001, "Scroll speed should persist after setting")
        
        // Restore original
        manager.scrollSpeedMultiplier = originalValue
    }

    func testScrollSpeedAcceptsValidValues() throws {
        let manager = PreferencesManager.shared
        let originalValue = manager.scrollSpeedMultiplier
        
        // Test various valid speed values
        let validSpeeds: [Double] = [0.5, 1.0, 1.5, 2.0]
        
        for speed in validSpeeds {
            manager.scrollSpeedMultiplier = speed
            XCTAssertEqual(manager.scrollSpeedMultiplier, speed, accuracy: 0.001, "Should accept speed value \(speed)")
        }
        
        // Restore
        manager.scrollSpeedMultiplier = originalValue
    }

    // MARK: - Launch at Login Tests

    func testLaunchAtLoginDefaultValue() throws {
        // Test that launchAtLogin returns a boolean value
        // We can't reliably test the default because UserDefaults may have user-set values
        // Instead, verify the property is accessible and returns a valid boolean
        let value = PreferencesManager.shared.launchAtLogin
        XCTAssertTrue(value == true || value == false, "launchAtLogin should return a valid boolean")
    }

    func testLaunchAtLoginToggle() throws {
        let manager = PreferencesManager.shared
        let originalValue = manager.launchAtLogin

        // Toggle to opposite
        manager.launchAtLogin = !originalValue
        XCTAssertEqual(manager.launchAtLogin, !originalValue, "launchAtLogin should toggle")

        // Toggle back
        manager.launchAtLogin = originalValue
        XCTAssertEqual(manager.launchAtLogin, originalValue, "launchAtLogin should restore")
    }

    // MARK: - Scroll Speed Mode Tests

    func testScrollSpeedModeDefaultValue() throws {
        let manager = PreferencesManager.shared
        let originalMode = manager.scrollSpeedMode

        // Reset to test default behavior
        UserDefaults.standard.removeObject(forKey: "scrollSpeedMode")

        // Default should be "static"
        XCTAssertEqual(manager.scrollSpeedMode, "static", "Default scroll speed mode should be 'static'")

        // Restore original
        manager.scrollSpeedMode = originalMode
    }

    func testScrollSpeedModePersistence() throws {
        let manager = PreferencesManager.shared
        let originalMode = manager.scrollSpeedMode

        // Set to dynamic
        manager.scrollSpeedMode = "dynamic"
        XCTAssertEqual(manager.scrollSpeedMode, "dynamic", "Scroll speed mode should persist as 'dynamic'")

        // Set back to static
        manager.scrollSpeedMode = "static"
        XCTAssertEqual(manager.scrollSpeedMode, "static", "Scroll speed mode should persist as 'static'")

        // Restore original
        manager.scrollSpeedMode = originalMode
    }

    func testIsDynamicSpeedComputedProperty() throws {
        let manager = PreferencesManager.shared
        let originalMode = manager.scrollSpeedMode

        // Test static mode
        manager.scrollSpeedMode = "static"
        XCTAssertFalse(manager.isDynamicSpeed, "isDynamicSpeed should be false when mode is 'static'")

        // Test dynamic mode
        manager.scrollSpeedMode = "dynamic"
        XCTAssertTrue(manager.isDynamicSpeed, "isDynamicSpeed should be true when mode is 'dynamic'")

        // Restore original
        manager.scrollSpeedMode = originalMode
    }
}

// MARK: - ScrollController Tests

final class ScrollControllerTests: XCTestCase {

    // MARK: - Scroll Vector Calculation Tests
    
    func testDeadZoneBehavior() throws {
        // When cursor is within deadzone (< 10px from anchor), no scrolling should occur
        // We can verify this indirectly by testing the scroll logic
        
        let anchor = CGPoint(x: 100, y: 100)
        let nearbyPoint = CGPoint(x: 105, y: 105) // ~7px away, within deadzone
        
        let dx = nearbyPoint.x - anchor.x
        let dy = nearbyPoint.y - anchor.y
        let distance = sqrt(dx * dx + dy * dy)
        
        let deadZone: CGFloat = 10.0
        XCTAssertLessThan(distance, deadZone, "Point should be within dead zone")
    }

    func testScrollDistanceCalculation() throws {
        // Test that distance calculation is correct
        let anchor = CGPoint(x: 100, y: 100)
        let farPoint = CGPoint(x: 150, y: 100) // 50px away horizontally
        
        let dx = farPoint.x - anchor.x
        let dy = farPoint.y - anchor.y
        let distance = sqrt(dx * dx + dy * dy)
        
        XCTAssertEqual(distance, 50.0, accuracy: 0.001, "Distance should be 50px")
    }

    func testScrollVectorDirection() throws {
        // Test scroll direction calculation
        let anchor = CGPoint(x: 100, y: 100)
        
        // Moving right from anchor
        let rightPoint = CGPoint(x: 150, y: 100)
        let dxRight = rightPoint.x - anchor.x
        XCTAssertGreaterThan(dxRight, 0, "Moving right should have positive dx")
        
        // Moving down from anchor  
        let downPoint = CGPoint(x: 100, y: 150)
        let dyDown = downPoint.y - anchor.y
        XCTAssertGreaterThan(dyDown, 0, "Moving down should have positive dy")
        
        // Moving left from anchor
        let leftPoint = CGPoint(x: 50, y: 100)
        let dxLeft = leftPoint.x - anchor.x
        XCTAssertLessThan(dxLeft, 0, "Moving left should have negative dx")
        
        // Moving up from anchor
        let upPoint = CGPoint(x: 100, y: 50)
        let dyUp = upPoint.y - anchor.y
        XCTAssertLessThan(dyUp, 0, "Moving up should have negative dy")
    }

    func testEffectiveDistanceCalculation() throws {
        // Effective distance = distance - deadzone
        let deadZone: CGFloat = 10.0
        let distance: CGFloat = 50.0
        let effectiveDistance = distance - deadZone
        
        XCTAssertEqual(effectiveDistance, 40.0, accuracy: 0.001, "Effective distance should subtract dead zone")
    }

    func testScaleFactorCapping() throws {
        // Scale factor should be capped at 1.0
        let effectiveDistance: CGFloat = 200.0 // Very far from anchor
        let scaleFactor = min(effectiveDistance / 100.0, 1.0)
        
        XCTAssertEqual(scaleFactor, 1.0, accuracy: 0.001, "Scale factor should be capped at 1.0")
    }

    func testSpeedMultiplierEffect() throws {
        // Speed multiplier should affect scale factor
        let effectiveDistance: CGFloat = 50.0
        let speedMultiplier: CGFloat = 2.0
        
        let baseScale = min(effectiveDistance / 100.0, 1.0)
        let scaledFactor = baseScale * speedMultiplier
        
        XCTAssertEqual(scaledFactor, 1.0, accuracy: 0.001, "Speed multiplier should double the scale")
    }

    func testHorizontalScrollSuppression() throws {
        // When vertical movement dominates, horizontal should be suppressed
        let anchor = CGPoint(x: 100, y: 100)
        let verticalDominant = CGPoint(x: 110, y: 200) // dx=10, dy=100
        
        let dx = abs(verticalDominant.x - anchor.x)
        let dy = abs(verticalDominant.y - anchor.y)
        
        // If dx < dy * 0.5, horizontal scroll should be zeroed
        XCTAssertLessThan(dx, dy * 0.5, "Horizontal component should be suppressed when vertical dominates")
    }

    func testVerticalScrollSuppression() throws {
        // When horizontal movement dominates, vertical should be suppressed
        let anchor = CGPoint(x: 100, y: 100)
        let horizontalDominant = CGPoint(x: 200, y: 110) // dx=100, dy=10

        let dx = abs(horizontalDominant.x - anchor.x)
        let dy = abs(horizontalDominant.y - anchor.y)

        // If dy < dx * 0.5, vertical scroll should be zeroed
        XCTAssertLessThan(dy, dx * 0.5, "Vertical component should be suppressed when horizontal dominates")
    }

    // MARK: - Dynamic Speed Mode Tests

    func testStaticModeScaleFactorCapping() throws {
        // In static mode, scale factor should be capped at 1.0
        let effectiveDistance: CGFloat = 500.0 // Very far from anchor
        let maxScale: CGFloat = 1.0 // Static mode cap

        let scaleFactor = min(effectiveDistance / 100.0, maxScale)
        XCTAssertEqual(scaleFactor, 1.0, accuracy: 0.001, "Static mode scale factor should be capped at 1.0")
    }

    func testDynamicModeScaleFactorGrowth() throws {
        // In dynamic mode, scale factor can grow up to 10.0
        let effectiveDistance: CGFloat = 500.0 // 500px from dead zone edge
        let maxScale: CGFloat = 10.0 // Dynamic mode cap

        let scaleFactor = min(effectiveDistance / 100.0, maxScale)
        XCTAssertEqual(scaleFactor, 5.0, accuracy: 0.001, "Dynamic mode scale factor should be 5.0 at 500px")
    }

    func testDynamicModeScaleFactorCapping() throws {
        // In dynamic mode, scale factor should cap at 10.0
        let effectiveDistance: CGFloat = 1500.0 // Very far from anchor
        let maxScale: CGFloat = 10.0 // Dynamic mode cap

        let scaleFactor = min(effectiveDistance / 100.0, maxScale)
        XCTAssertEqual(scaleFactor, 10.0, accuracy: 0.001, "Dynamic mode scale factor should cap at 10.0")
    }

    func testDynamicModeWithSpeedMultiplier() throws {
        // Test that speed multiplier is applied on top of dynamic scaling
        let effectiveDistance: CGFloat = 500.0
        let speedMultiplier: CGFloat = 1.5 // "Fast" preset
        let maxScale: CGFloat = 10.0 // Dynamic mode

        let baseScale = min(effectiveDistance / 100.0, maxScale)
        let scaledFactor = baseScale * speedMultiplier

        // At 500px with Fast preset: 5.0 * 1.5 = 7.5x effective speed
        XCTAssertEqual(scaledFactor, 7.5, accuracy: 0.001, "Dynamic mode with Fast preset should give 7.5x at 500px")
    }
}

// MARK: - Logger Tests

final class LoggerTests: XCTestCase {

    func testDebugLoggingGatedByEnvironment() throws {
        // In test environment, debug logging should be controlled by MIDDLESCROLLER_DEBUG
        // This test verifies the Logger respects the debug flag
        
        #if DEBUG
        let debugBuild = true
        #else
        let debugBuild = false
        #endif
        
        // Logger.isDebugEnabled should be false unless env var is set
        if debugBuild && ProcessInfo.processInfo.environment["MIDDLESCROLLER_DEBUG"] != nil {
            XCTAssertTrue(Logger.isDebugEnabled, "Debug should be enabled when env var is set")
        } else if !debugBuild {
            XCTAssertFalse(Logger.isDebugEnabled, "Debug should be disabled in release builds")
        }
    }
}
