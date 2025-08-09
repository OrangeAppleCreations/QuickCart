# Chapter 1: Data Models Setup

**⏱️ Estimated Time:** 1 Week  
**🎯 Learning Objective:** Create the foundation data models for QuickCart

---

## 📋 Prerequisites

Before starting this chapter:
- [x] Your modular project structure is set up (✅ Done)
- [x] Library package exists with Models target (✅ Done)
- [x] Basic understanding of Swift structs and enums

---

## 🎯 Chapter Goals

By the end of this chapter, you will have:
- ✅ A complete `ShoppingItem` model with all necessary properties
- ✅ A robust `ShoppingList` model that can hold multiple items
- ✅ Proper model validation and error handling
- ✅ Sample data for testing
- ✅ Unit tests covering your models

---

## 📚 Lesson 1.1: Basic ShoppingItem Model

### Task 1: Create the ShoppingItem Model

**Location:** `Library/Sources/Models/ShoppingItem.swift`

```swift
import Foundation

public struct ShoppingItem: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var quantity: Int
    public var isCompleted: Bool
    public var notes: String
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        quantity: Int = 1,
        isCompleted: Bool = false,
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.isCompleted = isCompleted
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Computed Properties
public extension ShoppingItem {
    var displayName: String {
        quantity > 1 ? "\(quantity)x \(name)" : name
    }
}

// MARK: - Mutations
public extension ShoppingItem {
    mutating func toggle() {
        isCompleted.toggle()
        updatedAt = Date()
    }
    
    mutating func updateQuantity(_ newQuantity: Int) {
        guard newQuantity > 0 else { return }
        quantity = newQuantity
        updatedAt = Date()
    }
}
```

**✅ Completion Check:**
- [x] Model compiles without errors
- [x] All properties are properly initialized
- [x] Public API is correctly exposed

---

## 📚 Lesson 1.2: Categories System

### Task 2: Add Item Categories

Add this to your `ShoppingItem.swift` file:

```swift
public enum ItemCategory: String, CaseIterable, Codable, Sendable {
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat & Seafood"
    case pantry = "Pantry"
    case frozen = "Frozen"
    case household = "Household"
    case personal = "Personal Care"
    case other = "Other"
    
    public var emoji: String {
        switch self {
        case .produce: return "🥬"
        case .dairy: return "🥛"
        case .meat: return "🥩"
        case .pantry: return "🥫"
        case .frozen: return "🧊"
        case .household: return "🧽"
        case .personal: return "🧴"
        case .other: return "📦"
        }
    }
    
    public var sortOrder: Int {
        switch self {
        case .produce: return 1
        case .dairy: return 2
        case .meat: return 3
        case .frozen: return 4
        case .pantry: return 5
        case .household: return 6
        case .personal: return 7
        case .other: return 8
        }
    }
}
```

### Task 3: Add Category to ShoppingItem

Update your `ShoppingItem` model:

```swift
public struct ShoppingItem: Identifiable, Codable, Sendable {
    // ... existing properties ...
    public var category: ItemCategory
    
    public init(
        id: UUID = UUID(),
        name: String,
        quantity: Int = 1,
        isCompleted: Bool = false,
        notes: String = "",
        category: ItemCategory = .other,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        // ... existing initialization ...
        self.category = category
    }
}
```

**✅ Completion Check:**
- [ ] Categories enum is complete
- [ ] ShoppingItem includes category property
- [ ] All categories have emojis and sort orders

---

## 📚 Lesson 1.3: ShoppingList Model

### Task 4: Create the ShoppingList Model

**Location:** `Library/Sources/Models/ShoppingList.swift`

```swift
import Foundation

public struct ShoppingList: Identifiable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var items: [ShoppingItem]
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        items: [ShoppingItem] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Computed Properties
public extension ShoppingList {
    var completedItems: [ShoppingItem] {
        items.filter(\.isCompleted)
    }
    
    var pendingItems: [ShoppingItem] {
        items.filter { !$0.isCompleted }
    }
    
    var completionPercentage: Double {
        guard !items.isEmpty else { return 0 }
        return Double(completedItems.count) / Double(items.count)
    }
    
    var itemsByCategory: [ItemCategory: [ShoppingItem]] {
        Dictionary(grouping: items) { $0.category }
    }
}

// MARK: - Mutations
public extension ShoppingList {
    mutating func addItem(_ item: ShoppingItem) {
        items.append(item)
        updatedAt = Date()
    }
    
    mutating func removeItem(withId id: UUID) {
        items.removeAll { $0.id == id }
        updatedAt = Date()
    }
    
    mutating func updateItem(_ updatedItem: ShoppingItem) {
        if let index = items.firstIndex(where: { $0.id == updatedItem.id }) {
            items[index] = updatedItem
            updatedAt = Date()
        }
    }
    
    mutating func clearCompleted() {
        items.removeAll(where: \.isCompleted)
        updatedAt = Date()
    }
}
```

**✅ Completion Check:**
- [ ] ShoppingList model compiles
- [ ] Computed properties work correctly
- [ ] Mutation methods update `updatedAt`

---

## 📚 Lesson 1.4: Sample Data

### Task 5: Create Sample Data Factory

**Location:** `Library/Sources/Models/SampleData.swift`

```swift
import Foundation

public enum SampleData {
    public static let sampleItems: [ShoppingItem] = [
        ShoppingItem(name: "Bananas", quantity: 6, category: .produce),
        ShoppingItem(name: "Milk", quantity: 1, category: .dairy),
        ShoppingItem(name: "Chicken Breast", quantity: 2, category: .meat),
        ShoppingItem(name: "Rice", quantity: 1, category: .pantry, notes: "Basmati preferred"),
        ShoppingItem(name: "Ice Cream", quantity: 1, category: .frozen),
        ShoppingItem(name: "Dish Soap", quantity: 1, category: .household),
        ShoppingItem(name: "Toothpaste", quantity: 1, category: .personal),
    ]
    
    public static let sampleLists: [ShoppingList] = [
        ShoppingList(
            title: "Weekly Groceries",
            items: Array(sampleItems.prefix(5))
        ),
        ShoppingList(
            title: "Party Supplies",
            items: [
                ShoppingItem(name: "Chips", quantity: 3, category: .pantry),
                ShoppingItem(name: "Soda", quantity: 6, category: .other),
                ShoppingItem(name: "Napkins", quantity: 1, category: .household),
            ]
        ),
        ShoppingList(
            title: "Quick Run",
            items: [
                ShoppingItem(name: "Bread", quantity: 1, category: .pantry),
                ShoppingItem(name: "Eggs", quantity: 12, category: .dairy),
            ]
        )
    ]
}
```

**✅ Completion Check:**
- [ ] Sample data compiles
- [ ] Diverse categories represented
- [ ] Different quantities and notes included

---

## 📚 Lesson 1.5: Model Validation

### Task 6: Add Validation

Add validation to your models:

```swift
// Add to ShoppingItem.swift
public extension ShoppingItem {
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        quantity > 0
    }
    
    enum ValidationError: Error, LocalizedError {
        case emptyName
        case invalidQuantity
        
        public var errorDescription: String? {
            switch self {
            case .emptyName:
                return "Item name cannot be empty"
            case .invalidQuantity:
                return "Quantity must be greater than 0"
            }
        }
    }
    
    func validate() throws {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.emptyName
        }
        if quantity <= 0 {
            throw ValidationError.invalidQuantity
        }
    }
}

// Add to ShoppingList.swift
public extension ShoppingList {
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    enum ValidationError: Error, LocalizedError {
        case emptyTitle
        
        public var errorDescription: String? {
            switch self {
            case .emptyTitle:
                return "List title cannot be empty"
            }
        }
    }
    
    func validate() throws {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.emptyTitle
        }
    }
}
```

---

## 🧪 Testing Your Work

### Task 7: Create Unit Tests

**Location:** `Library/Tests/LibraryTests/ModelsTests.swift`

```swift
import XCTest
@testable import Models

final class ShoppingItemTests: XCTestCase {
    func testItemCreation() {
        let item = ShoppingItem(name: "Test Item")
        
        XCTAssertEqual(item.name, "Test Item")
        XCTAssertEqual(item.quantity, 1)
        XCTAssertFalse(item.isCompleted)
        XCTAssertEqual(item.category, .other)
    }
    
    func testToggleCompletion() {
        var item = ShoppingItem(name: "Test Item")
        let originalDate = item.updatedAt
        
        // Small delay to ensure updatedAt changes
        Thread.sleep(forTimeInterval: 0.01)
        item.toggle()
        
        XCTAssertTrue(item.isCompleted)
        XCTAssertGreaterThan(item.updatedAt, originalDate)
    }
    
    func testDisplayName() {
        let singleItem = ShoppingItem(name: "Apple", quantity: 1)
        let multipleItems = ShoppingItem(name: "Banana", quantity: 5)
        
        XCTAssertEqual(singleItem.displayName, "Apple")
        XCTAssertEqual(multipleItems.displayName, "5x Banana")
    }
    
    func testValidation() {
        let validItem = ShoppingItem(name: "Valid Item")
        let invalidItem = ShoppingItem(name: "", quantity: 0)
        
        XCTAssertTrue(validItem.isValid)
        XCTAssertFalse(invalidItem.isValid)
        
        XCTAssertNoThrow(try validItem.validate())
        XCTAssertThrowsError(try invalidItem.validate())
    }
}

final class ShoppingListTests: XCTestCase {
    func testListCreation() {
        let list = ShoppingList(title: "Test List")
        
        XCTAssertEqual(list.title, "Test List")
        XCTAssertTrue(list.items.isEmpty)
        XCTAssertEqual(list.completionPercentage, 0)
    }
    
    func testAddingItems() {
        var list = ShoppingList(title: "Test List")
        let item = ShoppingItem(name: "Test Item")
        
        list.addItem(item)
        
        XCTAssertEqual(list.items.count, 1)
        XCTAssertEqual(list.items.first?.name, "Test Item")
    }
    
    func testCompletionPercentage() {
        var list = ShoppingList(title: "Test List")
        var item1 = ShoppingItem(name: "Item 1")
        var item2 = ShoppingItem(name: "Item 2")
        
        item1.toggle() // Complete first item
        
        list.addItem(item1)
        list.addItem(item2)
        
        XCTAssertEqual(list.completionPercentage, 0.5)
    }
}
```

### Run Your Tests

```bash
cd QuickCart
xcodebuild test -scheme Library
```

**✅ Completion Check:**
- [ ] All tests pass
- [ ] Code coverage is good
- [ ] No compiler warnings

---

## 📚 Lesson 1.6: Update Your Models Export

### Task 8: Clean Up Models Module

**Location:** `Library/Sources/Models/Models.swift`

Replace the placeholder content with:

```swift
// Models Module - QuickCart Core Data Models

// Export all public types
@_exported import Foundation

// This file serves as the main entry point for the Models module
// Individual model files are automatically included
```

Update your file structure:
```
Library/Sources/Models/
├── Models.swift          (main module file)
├── ShoppingItem.swift    (item model)
├── ShoppingList.swift    (list model)
├── SampleData.swift      (test data)
└── ItemCategory.swift    (move category here if you want)
```

---

## 🎉 Chapter 1 Complete!

### Final Checklist

Before moving to Chapter 2, ensure:

- [ ] ✅ ShoppingItem model is complete with all properties
- [ ] ✅ ItemCategory enum with emojis and sorting
- [ ] ✅ ShoppingList model with computed properties
- [ ] ✅ Sample data for testing
- [ ] ✅ Model validation with error handling
- [ ] ✅ Unit tests passing
- [ ] ✅ Models module exports correctly
- [ ] ✅ No compiler warnings or errors

### What You've Built

🎊 **Congratulations!** You now have:

- **Solid Foundation**: Robust data models that will power your entire app
- **Type Safety**: Proper Swift types with validation
- **Testability**: Unit tests ensuring your models work correctly
- **Extensibility**: Models designed to grow with your app

### Next Steps

Ready for **Chapter 2: Core UI Components**? You'll use these models to build your first SwiftUI views!

---

**🤔 Stuck or confused?** Review the code examples, run the tests, and don't hesitate to ask Claude Code for help!
