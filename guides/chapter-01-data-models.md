# Chapter 1: SQL Schema & Value Types

**⏱️ Estimated Time:** 1 Week  
**🎯 Learning Objective:** Definieer je database schema met Swift value types volgens Point-Free moderne persistence

---

## 📋 Prerequisites

Before starting this chapter:
- [ ] Your modular project structure is set up (✅ Done)
- [ ] Library package exists with Models target (✅ Done)
- [ ] Basic understanding of Swift structs and SQL
- [ ] Xcode 15+ installed

---

## 🎯 Chapter Goals

By the end of this chapter, you will have:
- ✅ Een complete SQLite database schema voor QuickCart
- ✅ Swift value type models die je SQL schema representeren
- ✅ GRDB dependency setup in je project
- ✅ Database migrations voor schema versioning
- ✅ Sample data factory voor testing
- ✅ Comprehensive tests voor je models en database schema

**🌟 Point-Free Principle:** *"Start with the database schema, then build Swift types that mirror it exactly"*

---

## 📚 Lesson 1.1: Setup GRDB Dependency

### Task 1: Add GRDB to Package.swift

**Location:** `Library/Package.swift`

Update je package dependencies:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Library",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "Models", targets: ["Models"]),
        .library(name: "AppFeature", targets: ["AppFeature"]),
    ],
    dependencies: [
        // Point-Free Modern Persistence Stack
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.0"),
        .package(url: "https://github.com/pointfreeco/swift-sharing.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Models",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Sharing", package: "swift-sharing"),
            ]
        ),
        .target(
            name: "AppFeature",
            dependencies: ["Models"]
        ),
        .testTarget(
            name: "LibraryTests",
            dependencies: ["Models", "AppFeature"]
        ),
    ]
)
```

**✅ Completion Check:**
- [ ] Package.swift is updated with GRDB dependency
- [ ] Project builds without errors
- [ ] Dependencies resolve correctly

---

## 📚 Lesson 1.2: Design SQLite Database Schema

### Task 2: Create Database Schema

**Location:** `Library/Sources/Models/Schema.sql`

Definieer je database schema volgens Point-Free patterns:

```sql
-- QuickCart Database Schema v1.0
-- Based on Point-Free Modern Persistence patterns

-- Shopping Lists Table
CREATE TABLE IF NOT EXISTS shopping_lists (
    id TEXT PRIMARY KEY NOT NULL,
    title TEXT NOT NULL,
    created_at REAL NOT NULL, -- Unix timestamp
    updated_at REAL NOT NULL
);

-- Item Categories (as enum values)
CREATE TABLE IF NOT EXISTS item_categories (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    emoji TEXT NOT NULL,
    sort_order INTEGER NOT NULL
);

-- Insert default categories
INSERT OR IGNORE INTO item_categories (id, name, emoji, sort_order) VALUES
(1, 'Produce', '🥬', 1),
(2, 'Dairy', '🥛', 2),
(3, 'Meat & Seafood', '🥩', 3),
(4, 'Frozen', '🧊', 4),
(5, 'Pantry', '🥫', 5),
(6, 'Household', '🧽', 6),
(7, 'Personal Care', '🧴', 7),
(8, 'Other', '📦', 8);

-- Shopping Items Table
CREATE TABLE IF NOT EXISTS shopping_items (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    is_completed INTEGER NOT NULL DEFAULT 0, -- SQLite boolean as INTEGER
    notes TEXT NOT NULL DEFAULT '',
    category_id INTEGER NOT NULL DEFAULT 8, -- Foreign key to categories
    shopping_list_id TEXT NOT NULL, -- Foreign key to lists
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL,
    
    FOREIGN KEY (category_id) REFERENCES item_categories (id),
    FOREIGN KEY (shopping_list_id) REFERENCES shopping_lists (id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_items_list_id ON shopping_items (shopping_list_id);
CREATE INDEX IF NOT EXISTS idx_items_category ON shopping_items (category_id);
CREATE INDEX IF NOT EXISTS idx_items_completed ON shopping_items (is_completed);
CREATE INDEX IF NOT EXISTS idx_lists_updated ON shopping_lists (updated_at DESC);
```

**✅ Completion Check:**
- [ ] SQL schema is syntactically correct
- [ ] Foreign key relationships are defined
- [ ] Indexes are added for performance
- [ ] Default categories are populated

---

## 📚 Lesson 1.3: Create Swift Value Types

### Task 3: Define Value Type Models

**Location:** `Library/Sources/Models/ShoppingModels.swift`

```swift
import Foundation
import GRDB

// MARK: - ItemCategory Value Type
public struct ItemCategory: Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let emoji: String
    public let sortOrder: Int
    
    public init(id: Int, name: String, emoji: String, sortOrder: Int) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.sortOrder = sortOrder
    }
}

// MARK: - ShoppingItem Value Type  
public struct ShoppingItem: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let quantity: Int
    public let isCompleted: Bool
    public let notes: String
    public let categoryId: Int
    public let shoppingListId: String
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        quantity: Int = 1,
        isCompleted: Bool = false,
        notes: String = "",
        categoryId: Int = 8, // Default to "Other"
        shoppingListId: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.isCompleted = isCompleted
        self.notes = notes
        self.categoryId = categoryId
        self.shoppingListId = shoppingListId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - ShoppingList Value Type
public struct ShoppingList: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
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
```

**✅ Completion Check:**
- [ ] Value types mirror SQL schema exactly
- [ ] All properties are immutable (let)
- [ ] Types conform to Codable, Hashable, Sendable
- [ ] No business logic in models (pure data)

---

## 📚 Lesson 1.4: Database Records (GRDB Integration)

### Task 4: Create GRDB Database Records

**Location:** `Library/Sources/Models/DatabaseRecords.swift`

```swift
import Foundation
import GRDB

// MARK: - ItemCategory Database Record
extension ItemCategory: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "item_categories"
    
    public enum Columns {
        static let id = Column("id")
        static let name = Column("name")
        static let emoji = Column("emoji")
        static let sortOrder = Column("sort_order")
    }
}

// MARK: - ShoppingList Database Record
extension ShoppingList: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "shopping_lists"
    
    public enum Columns {
        static let id = Column("id")
        static let title = Column("title")
        static let createdAt = Column("created_at")
        static let updatedAt = Column("updated_at")
    }
    
    // Convert dates to/from Unix timestamps for SQLite
    public init(row: Row) throws {
        id = row[Columns.id]
        title = row[Columns.title]
        createdAt = Date(timeIntervalSince1970: row[Columns.createdAt])
        updatedAt = Date(timeIntervalSince1970: row[Columns.updatedAt])
    }
    
    public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.title] = title
        container[Columns.createdAt] = createdAt.timeIntervalSince1970
        container[Columns.updatedAt] = updatedAt.timeIntervalSince1970
    }
}

// MARK: - ShoppingItem Database Record
extension ShoppingItem: FetchableRecord, PersistableRecord {
    public static let databaseTableName = "shopping_items"
    
    public enum Columns {
        static let id = Column("id")
        static let name = Column("name")
        static let quantity = Column("quantity")
        static let isCompleted = Column("is_completed")
        static let notes = Column("notes")
        static let categoryId = Column("category_id")
        static let shoppingListId = Column("shopping_list_id")
        static let createdAt = Column("created_at")
        static let updatedAt = Column("updated_at")
    }
    
    public init(row: Row) throws {
        id = row[Columns.id]
        name = row[Columns.name]
        quantity = row[Columns.quantity]
        isCompleted = row[Columns.isCompleted]
        notes = row[Columns.notes]
        categoryId = row[Columns.categoryId]
        shoppingListId = row[Columns.shoppingListId]
        createdAt = Date(timeIntervalSince1970: row[Columns.createdAt])
        updatedAt = Date(timeIntervalSince1970: row[Columns.updatedAt])
    }
    
    public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.name] = name
        container[Columns.quantity] = quantity
        container[Columns.isCompleted] = isCompleted
        container[Columns.notes] = notes
        container[Columns.categoryId] = categoryId
        container[Columns.shoppingListId] = shoppingListId
        container[Columns.createdAt] = createdAt.timeIntervalSince1970
        container[Columns.updatedAt] = updatedAt.timeIntervalSince1970
    }
}
```

**✅ Completion Check:**
- [ ] All records conform to FetchableRecord & PersistableRecord
- [ ] Column enums are defined for type safety
- [ ] Date conversion handles Unix timestamps correctly
- [ ] Database table names match SQL schema

---

## 📚 Lesson 1.5: Database Migration System

### Task 5: Setup Database Migrations

**Location:** `Library/Sources/Models/DatabaseMigrator.swift`

```swift
import Foundation
import GRDB

public struct DatabaseMigrator {
    public static func migrator() -> DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        // Version 1.0: Initial Schema
        migrator.registerMigration("v1.0") { db in
            // Create shopping_lists table
            try db.execute(sql: """
                CREATE TABLE shopping_lists (
                    id TEXT PRIMARY KEY NOT NULL,
                    title TEXT NOT NULL,
                    created_at REAL NOT NULL,
                    updated_at REAL NOT NULL
                )
                """)
            
            // Create item_categories table
            try db.execute(sql: """
                CREATE TABLE item_categories (
                    id INTEGER PRIMARY KEY,
                    name TEXT UNIQUE NOT NULL,
                    emoji TEXT NOT NULL,
                    sort_order INTEGER NOT NULL
                )
                """)
            
            // Insert default categories
            try db.execute(sql: """
                INSERT INTO item_categories (id, name, emoji, sort_order) VALUES
                (1, 'Produce', '🥬', 1),
                (2, 'Dairy', '🥛', 2),
                (3, 'Meat & Seafood', '🥩', 3),
                (4, 'Frozen', '🧊', 4),
                (5, 'Pantry', '🥫', 5),
                (6, 'Household', '🧽', 6),
                (7, 'Personal Care', '🧴', 7),
                (8, 'Other', '📦', 8)
                """)
            
            // Create shopping_items table
            try db.execute(sql: """
                CREATE TABLE shopping_items (
                    id TEXT PRIMARY KEY NOT NULL,
                    name TEXT NOT NULL,
                    quantity INTEGER NOT NULL DEFAULT 1,
                    is_completed INTEGER NOT NULL DEFAULT 0,
                    notes TEXT NOT NULL DEFAULT '',
                    category_id INTEGER NOT NULL DEFAULT 8,
                    shopping_list_id TEXT NOT NULL,
                    created_at REAL NOT NULL,
                    updated_at REAL NOT NULL,
                    
                    FOREIGN KEY (category_id) REFERENCES item_categories (id),
                    FOREIGN KEY (shopping_list_id) REFERENCES shopping_lists (id) ON DELETE CASCADE
                )
                """)
            
            // Create indexes
            try db.execute(sql: "CREATE INDEX idx_items_list_id ON shopping_items (shopping_list_id)")
            try db.execute(sql: "CREATE INDEX idx_items_category ON shopping_items (category_id)")
            try db.execute(sql: "CREATE INDEX idx_items_completed ON shopping_items (is_completed)")
            try db.execute(sql: "CREATE INDEX idx_lists_updated ON shopping_lists (updated_at DESC)")
        }
        
        return migrator
    }
}
```

---

## 📚 Lesson 1.6: Sample Data Factory

### Task 6: Create Sample Data for Testing

**Location:** `Library/Sources/Models/SampleData.swift`

```swift
import Foundation

public struct SampleData {
    
    // Sample Categories (matches database)
    public static let categories: [ItemCategory] = [
        ItemCategory(id: 1, name: "Produce", emoji: "🥬", sortOrder: 1),
        ItemCategory(id: 2, name: "Dairy", emoji: "🥛", sortOrder: 2),
        ItemCategory(id: 3, name: "Meat & Seafood", emoji: "🥩", sortOrder: 3),
        ItemCategory(id: 4, name: "Frozen", emoji: "🧊", sortOrder: 4),
        ItemCategory(id: 5, name: "Pantry", emoji: "🥫", sortOrder: 5),
        ItemCategory(id: 6, name: "Household", emoji: "🧽", sortOrder: 6),
        ItemCategory(id: 7, name: "Personal Care", emoji: "🧴", sortOrder: 7),
        ItemCategory(id: 8, name: "Other", emoji: "📦", sortOrder: 8),
    ]
    
    // Sample Shopping Lists
    public static let shoppingLists: [ShoppingList] = [
        ShoppingList(
            id: "list-1",
            title: "Boodschappen deze week",
            createdAt: Date().addingTimeInterval(-86400 * 2), // 2 days ago
            updatedAt: Date().addingTimeInterval(-3600) // 1 hour ago
        ),
        ShoppingList(
            id: "list-2", 
            title: "Feestje supplies",
            createdAt: Date().addingTimeInterval(-86400), // 1 day ago
            updatedAt: Date().addingTimeInterval(-1800) // 30 minutes ago
        ),
        ShoppingList(
            id: "list-3",
            title: "Quick run naar winkel",
            createdAt: Date().addingTimeInterval(-3600 * 6), // 6 hours ago
            updatedAt: Date().addingTimeInterval(-600) // 10 minutes ago
        )
    ]
    
    // Sample Shopping Items
    public static let shoppingItems: [ShoppingItem] = [
        // Items for list-1 (Weekly groceries)
        ShoppingItem(id: "item-1", name: "Bananen", quantity: 6, categoryId: 1, shoppingListId: "list-1"),
        ShoppingItem(id: "item-2", name: "Melk", quantity: 1, categoryId: 2, shoppingListId: "list-1"),
        ShoppingItem(id: "item-3", name: "Kipfilet", quantity: 2, categoryId: 3, shoppingListId: "list-1"),
        ShoppingItem(id: "item-4", name: "IJs", quantity: 1, categoryId: 4, shoppingListId: "list-1"),
        ShoppingItem(id: "item-5", name: "Rijst", quantity: 1, categoryId: 5, shoppingListId: "list-1", notes: "Basmati bij voorkeur"),
        
        // Items for list-2 (Party supplies) 
        ShoppingItem(id: "item-6", name: "Chips", quantity: 3, categoryId: 5, shoppingListId: "list-2"),
        ShoppingItem(id: "item-7", name: "Frisdrank", quantity: 6, categoryId: 8, shoppingListId: "list-2"),
        ShoppingItem(id: "item-8", name: "Servetten", quantity: 1, categoryId: 6, shoppingListId: "list-2"),
        
        // Items for list-3 (Quick run)
        ShoppingItem(id: "item-9", name: "Brood", quantity: 1, categoryId: 5, shoppingListId: "list-3"),
        ShoppingItem(id: "item-10", name: "Eieren", quantity: 12, categoryId: 2, shoppingListId: "list-3", isCompleted: true),
    ]
}
```

**✅ Completion Check:**
- [ ] Sample data matches database schema exactly
- [ ] Foreign key relationships are correct
- [ ] Mix of completed and pending items
- [ ] Diverse categories and quantities represented

---

## 🧪 Testing Your Database Schema

### Task 7: Create Comprehensive Tests

**Location:** `Library/Tests/LibraryTests/DatabaseSchemaTests.swift`

```swift
import XCTest
import GRDB
@testable import Models

final class DatabaseSchemaTests: XCTestCase {
    var dbQueue: DatabaseQueue!
    
    override func setUp() {
        super.setUp()
        // Create in-memory database for testing
        dbQueue = DatabaseQueue()
        
        do {
            try DatabaseMigrator.migrator().migrate(dbQueue)
        } catch {
            XCTFail("Failed to setup test database: \(error)")
        }
    }
    
    func testDatabaseSchemaCreation() throws {
        try dbQueue.read { db in
            // Test that all tables exist
            XCTAssertTrue(try db.tableExists("shopping_lists"))
            XCTAssertTrue(try db.tableExists("item_categories"))
            XCTAssertTrue(try db.tableExists("shopping_items"))
        }
    }
    
    func testDefaultCategoriesExist() throws {
        try dbQueue.read { db in
            let categories = try ItemCategory.fetchAll(db)
            XCTAssertEqual(categories.count, 8)
            
            // Test specific categories
            let produce = try ItemCategory.filter(ItemCategory.Columns.name == "Produce").fetchOne(db)
            XCTAssertNotNil(produce)
            XCTAssertEqual(produce?.emoji, "🥬")
        }
    }
    
    func testShoppingListCRUD() throws {
        let list = ShoppingList(id: "test-list", title: "Test List")
        
        try dbQueue.write { db in
            // Insert
            try list.insert(db)
        }
        
        // Fetch
        let fetchedList = try dbQueue.read { db in
            try ShoppingList.fetchOne(db, key: "test-list")
        }
        
        XCTAssertNotNil(fetchedList)
        XCTAssertEqual(fetchedList?.title, "Test List")
    }
    
    func testShoppingItemWithForeignKeys() throws {
        let list = ShoppingList(id: "test-list", title: "Test List")
        let item = ShoppingItem(
            id: "test-item",
            name: "Test Item",
            categoryId: 1, // Produce
            shoppingListId: "test-list"
        )
        
        try dbQueue.write { db in
            try list.insert(db)
            try item.insert(db)
        }
        
        let fetchedItem = try dbQueue.read { db in
            try ShoppingItem.fetchOne(db, key: "test-item")
        }
        
        XCTAssertNotNil(fetchedItem)
        XCTAssertEqual(fetchedItem?.name, "Test Item")
        XCTAssertEqual(fetchedItem?.categoryId, 1)
    }
    
    func testForeignKeyConstraints() throws {
        let item = ShoppingItem(
            id: "orphan-item",
            name: "Orphan Item", 
            shoppingListId: "non-existent-list"
        )
        
        // This should fail due to foreign key constraint
        XCTAssertThrowsError(try dbQueue.write { db in
            try item.insert(db)
        })
    }
}
```

Run je tests:
```bash
cd QuickCart
xcodebuild test -scheme Library -destination 'platform=iOS Simulator,name=iPhone 15'
```

**✅ Completion Check:**
- [ ] All database tests pass
- [ ] Schema creation works correctly
- [ ] Foreign key constraints are enforced
- [ ] CRUD operations work with GRDB

---

## 🎉 Chapter 1 Complete!

### Final Checklist

Before moving to Chapter 2, ensure:

- [ ] ✅ GRDB dependency is correctly added to Package.swift
- [ ] ✅ SQLite database schema is properly designed
- [ ] ✅ Swift value types mirror SQL schema exactly  
- [ ] ✅ GRDB database records are implemented
- [ ] ✅ Database migration system is working
- [ ] ✅ Sample data factory matches schema
- [ ] ✅ All database tests are passing
- [ ] ✅ No compiler warnings or errors

### What You've Built

🎊 **Gefeliciteerd!** Je hebt nu:

- **SQL-First Foundation**: Een solide database schema als fundament
- **Type-Safe Models**: Swift value types die exact je database weerspiegelen
- **Modern Persistence**: GRDB integration volgens Point-Free patterns
- **Migration System**: Database versioning voor toekomstige updates
- **Test Coverage**: Comprehensive tests voor je database layer
- **Point-Free Architecture**: Database als "single source of truth"

### Key Learnings

📚 **Je hebt geleerd:**
- Database-first design approach
- SQLite schema design met foreign keys en indexes
- Swift value types vs reference types voor data modeling
- GRDB integration voor type-safe database toegang
- Migration patterns voor schema evolutie

### Next Steps

Ready for **Chapter 2: GRDB Repository Pattern**? Je gaat nu een type-safe repository layer bouwen!

---

**🤔 Vragen of problemen?** Review je SQL schema, run de database tests, en vraag Claude Code om hulp bij complexe queries!