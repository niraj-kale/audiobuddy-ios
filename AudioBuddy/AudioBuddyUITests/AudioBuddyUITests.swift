//
//  AudioBuddyUITests.swift
//  AudioBuddyUITests
//
//  UI tests for Audio Buddy app.
//

import XCTest

final class AudioBuddyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify main UI elements are present
        XCTAssertTrue(app.tabBars.buttons["Record"].exists)
        XCTAssertTrue(app.tabBars.buttons["Recordings"].exists)
    }
    
    func testNavigationBetweenTabs() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Start on Record tab
        XCTAssertTrue(app.tabBars.buttons["Record"].isSelected)
        
        // Navigate to Recordings tab
        app.tabBars.buttons["Recordings"].tap()
        XCTAssertTrue(app.tabBars.buttons["Recordings"].isSelected)
        
        // Navigate back to Record tab
        app.tabBars.buttons["Record"].tap()
        XCTAssertTrue(app.tabBars.buttons["Record"].isSelected)
    }
}
