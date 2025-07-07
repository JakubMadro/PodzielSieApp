import XCTest

class DzielSieAppUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        
        // Set up a test account or use existing one
        app.launchArguments = ["UI-TESTING"]
        app.launchEnvironment = ["isUITesting": "true"]
    }
    
    // MARK: - Test Cases
    
    func testLoginFlow() throws {
        // Make sure we're logged out
        logoutIfNeeded()
        
        // Verify we're on the login screen
        XCTAssertTrue(isOnLoginScreen(), "Not on login screen")
        
        // Login with test credentials
        login(email: "jakubmadro@gmail.com", password: "qwerty123")
        
        // Verify login was successful
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5.0), "Login failed - tab bar not found")
    }
    
    func testGroupCreation() throws {
        // Login if needed
        ensureLoggedIn()
        
        // Navigate to Groups tab
        tapTab(containing: "Grupy")
        
        // Tap the add group button
        tapAddButton()
        
        // Enter group details
        let groupName = "Test Group UI"
        enterText(groupName, inFieldContaining: "Nazwa")
        
        // Try to enter description if the field exists
        let descField = findTextField(containing: "Opis")
        if descField.exists {
            enterText("Opis testowej grupy utworzony przez test UI", in: descField)
        }
        
        // Try to set currency if possible
        trySelectCurrency("EUR")
        
        // Create the group
        tapButton(containing: "Utwórz")
        
        // Verify group was created
        XCTAssertTrue(waitForElementToExist(containing: groupName, timeout: 5.0),
                     "Created group not found")
    }
    
    func testAddExpense() throws {
        // Ensure we're logged in and have a test group
        ensureLoggedIn()
        ensureTestGroupExists()
        openGroup(named: "Test Group UI")
        
        
        // Find and tap the add expense button
        let addExpenseButton = findButton(withOptions: [
            { self.app.buttons.matching(NSPredicate(format: "label == 'Dodaj wydatek'")).firstMatch },
            { self.app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'dodaj wydatek'")).firstMatch },
            { self.app.buttons.matching(NSPredicate(format: "label == '+'")).firstMatch },
            { self.app.buttons.matching(NSPredicate(format: "label CONTAINS '+'")).firstMatch }
        ])
        
        guard let addButton = addExpenseButton, addButton.exists else {
            XCTFail("Add expense button not found")
            return
        }
        
        addButton.tap()
        
        // Enter expense details
        let descriptionField = findTextField(containing: "Opis")
        XCTAssertTrue(descriptionField.waitForExistence(timeout: 5.0), "Expense form not loaded")
        
        enterText("Wydatek testowy", in: descriptionField)
        
        // Enter amount
        let amountField = findTextField(containing: "0.00")
        if amountField.exists {
            enterText("50.00", in: amountField)
            dismissKeyboard()
        }
        
        // Add the expense
        tapButton(containing: "Dodaj wydatek")
        
        // Verify we returned to group screen or see the expense
        sleep(2) // Allow time for processing
        let isSuccess = elementExists(containing: "Test Group UI") ||
                        elementExists(containing: "Wydatek testowy")
        XCTAssertTrue(isSuccess, "Failed to return to group screen after adding expense")
    }
    
    func testAddMemberToGroup() {
        // Setup
        ensureLoggedIn()
        openGroup(named: "Test Group UI")
        
        // Add member
        let addMemberButton = findButton(containing: "Dodaj")
        XCTAssertTrue(addMemberButton.exists, "Add member button not found")
        addMemberButton.tap()
        
        // Enter new member email
        let emailField = findTextField(containing: "Email")
        XCTAssertTrue(emailField.exists, "Email field not found")
        enterText("jakubmadro@gmail.com", in: emailField)
        
        // Add the member
        tapButton(containing: "Dodaj członka")
        
        // Verify member was added
        XCTAssertTrue(
            app.staticTexts["jakubmadro@gmail.com"].waitForExistence(timeout: 5.0),
            "New member not found"
        )
    }
    
    func testLogout() throws {
        ensureLoggedIn()
        logout()
        XCTAssertTrue(isOnLoginScreen(), "Failed to return to login screen")
    }
    
    // MARK: - Helper Methods - UI Element Finders
    
    /// Find a button by its label content
    private func findButton(containing text: String) -> XCUIElement {
        return app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }
    
    /// Find a button using multiple search strategies
    private func findButton(withOptions options: [() -> XCUIElement]) -> XCUIElement? {
        for option in options {
            let element = option()
            if element.exists {
                return element
            }
        }
        return nil
    }
    
    /// Find a text field by its placeholder or label
    private func findTextField(containing text: String) -> XCUIElement {
        return app.textFields.matching(
            NSPredicate(format: "placeholderValue CONTAINS %@ OR label CONTAINS %@", text, text)
        ).firstMatch
    }
    
    /// Find a secure text field (password field)
    private func findSecureTextField() -> XCUIElement {
        return app.secureTextFields.firstMatch
    }
    
    /// Check if element exists that contains specific text
    private func elementExists(containing text: String) -> Bool {
        return app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch.exists ||
               app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch.exists
    }
    
    /// Wait for an element to exist
    private func waitForElementToExist(containing text: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let element = app.staticTexts.matching(predicate).firstMatch
        return element.waitForExistence(timeout: timeout)
    }
    
    // MARK: - Helper Methods - Actions
    
    /// Enter text in a text field
    private func enterText(_ text: String, in textField: XCUIElement) {
        textField.tap()
        textField.typeText(text)
    }
    
    /// Enter text in a field containing specific text in placeholder or label
    private func enterText(_ text: String, inFieldContaining placeholder: String) {
        let field = findTextField(containing: placeholder)
        if field.exists {
            enterText(text, in: field)
        } else {
            XCTFail("Field containing '\(placeholder)' not found")
        }
    }
    
    /// Tap a button containing specific text
    private func tapButton(containing text: String) {
        let button = findButton(containing: text)
        XCTAssertTrue(button.exists, "Button containing '\(text)' not found")
        button.tap()
    }
    
    /// Tap a tab containing specific text
    private func tapTab(containing text: String) {
        let tab = app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        XCTAssertTrue(tab.exists, "Tab containing '\(text)' not found")
        tab.tap()
    }
    
    /// Tap the add button (usually a "+" button)
    private func tapAddButton() {
        let addButton = findButton(withOptions: [
            { self.app.buttons["plus"] },
            { self.app.navigationBars.firstMatch.buttons.element(boundBy: 1) },
            { self.app.buttons.matching(NSPredicate(format: "label CONTAINS '+'")).firstMatch }
        ])
        
        guard let button = addButton, button.exists else {
            XCTFail("Add button not found")
            return
        }
        
        button.tap()
    }
    
    /// Dismiss keyboard if it's present
    private func dismissKeyboard() {
        if app.buttons["Done"].exists {
            app.buttons["Done"].tap()
        } else if app.buttons["Gotowe"].exists {
            app.buttons["Gotowe"].tap()
        } else {
            app.tap() // Alternative way to dismiss keyboard
        }
    }
    
    /// Try to select a currency in a picker
    private func trySelectCurrency(_ currency: String) {
        let currencyButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'waluta'")).firstMatch
        
        if currencyButton.exists {
            currencyButton.tap()
            
            let currencyOption = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", currency)).firstMatch
            if currencyOption.exists {
                currencyOption.tap()
            } else {
                currencyButton.tap() // Close picker if currency not found
            }
        }
    }
    
    // MARK: - Helper Methods - Application State
    
    /// Check if we're on the login screen
    private func isOnLoginScreen() -> Bool {
        return app.staticTexts["DzielSię"].exists ||
               app.buttons.matching(NSPredicate(format: "label CONTAINS 'Zaloguj'")).firstMatch.exists
    }
    
    /// Open a group by name
    private func openGroup(named groupName: String) {
        tapTab(containing: "Grupy")
        sleep(2) // Allow time for groups to load
        
        // Try different methods to find and open the group
        let groupButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", groupName)).firstMatch
        if groupButton.exists {
            groupButton.tap()
            return
        }
        
        let groupText = app.staticTexts[groupName]
        if groupText.exists {
            groupText.tap()
            return
        }
        
        // Try cells as a last resort
        let cells = app.cells.allElementsBoundByIndex
        for cell in cells {
            if cell.label.contains(groupName) {
                cell.tap()
                return
            }
        }
        
        XCTFail("Group '\(groupName)' not found")
    }
    
    /// Ensure we're logged in, logging in if necessary
    private func ensureLoggedIn() {
        if app.tabBars.firstMatch.exists {
            return // Already logged in
        }
        
        login(email: "test@example.com", password: "password123")
        XCTAssertTrue(
            app.tabBars.firstMatch.waitForExistence(timeout: 5.0),
            "Login failed - tab bar not found"
        )
    }
    
    /// Login with specific credentials
    private func login(email: String, password: String) {
        let emailField = findTextField(containing: "email")
        let passwordField = findSecureTextField()
        let loginButton = findButton(containing: "Zaloguj")
        
        XCTAssertTrue(emailField.exists, "Email field not found")
        XCTAssertTrue(passwordField.exists, "Password field not found")
        XCTAssertTrue(loginButton.exists, "Login button not found")
        
        enterText(email, in: emailField)
        enterText(password, in: passwordField)
        loginButton.tap()
    }
    
    /// Logout if currently logged in
    private func logoutIfNeeded() {
        if app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS 'Ustawienia'")).firstMatch.exists {
            logout()
        }
    }
    
    /// Logout from the app
    private func logout() {
        tapTab(containing: "Ustawienia")
        tapButton(containing: "Wyloguj")
    }
    
    /// Ensure the test group exists, creating it if necessary
    private func ensureTestGroupExists() {
        tapTab(containing: "Grupy")
        
        // Check if test group exists
        let groupExists = elementExists(containing: "Test Group UI")
        
        if !groupExists {
            // Create the group
            tapAddButton()
            
            let groupNameField = findTextField(containing: "Nazwa")
            XCTAssertTrue(groupNameField.exists, "Group name field not found")
            
            enterText("Test Group UI", in: groupNameField)
            tapButton(containing: "Utwórz")
            
            sleep(2) // Allow time for group creation
        }
    }
}

extension XCUIElement {
    /// Clear text field and enter new text
    func clearAndEnterText(_ text: String) {
        guard let stringValue = value as? String else {
            XCTFail("Couldn't clear text field")
            return
        }
        
        tap()
        
        // Delete existing text using backspace
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
        
        // Enter new text
        typeText(text)
    }
}
