//
//  CriticalFlowsUITests.swift
//  TetherFlowUITests
//
//  UI tests for critical user flows
//

import XCTest

final class CriticalFlowsUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    func openMenuBar() {
        // Tap the menu bar icon (assuming it's accessible)
        let menuBarIcon = app.statusItems.firstMatch
        menuBarIcon.tap()
    }
    
    // MARK: - Critical Flow Tests
    
    func testLaunchApp() {
        // Verify app launches without crashing
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
    
    func testOpenProfileManager() {
        openMenuBar()
        
        // Tap "Manage Profiles" button
        let manageProfilesButton = app.buttons["Manage Profiles..."]
        XCTAssertTrue(manageProfilesButton.waitForExistence(timeout: 2))
        manageProfilesButton.tap()
        
        // Verify ProfileListView appears
        let profileListTitle = app.staticTexts["Hotspot Profiles"]
        XCTAssertTrue(profileListTitle.waitForExistence(timeout: 2))
    }
    
    func testAddProfileFlow() {
        openMenuBar()
        
        // Open profile manager
        app.buttons["Manage Profiles..."].tap()
        
        // Tap Add button
        let addButton = app.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 2))
        addButton.tap()
        
        // Verify AddProfileView appears
        let ssidField = app.textFields["SSID"]
        XCTAssertTrue(ssidField.waitForExistence(timeout: 2))
        
        // Enter SSID
        ssidField.tap()
        ssidField.typeText("TestHotspot")
        
        // Save
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()
    }
    
    func testOpenDashboard() {
        openMenuBar()
        
        // Tap Dashboard button
        let dashboardButton = app.buttons["Dashboard..."]
        XCTAssertTrue(dashboardButton.waitForExistence(timeout: 2))
        dashboardButton.tap()
        
        // Verify DashboardView appears
        let dashboardTitle = app.staticTexts["Dashboard"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 2))
    }
    
    func testQuitApp() {
        openMenuBar()
        
        // Tap Quit button
        let quitButton = app.buttons["Quit"]
        XCTAssertTrue(quitButton.waitForExistence(timeout: 2))
        quitButton.tap()
        
        // Verify app terminates
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 5))
    }
}
