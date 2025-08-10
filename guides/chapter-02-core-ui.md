# Chapter 2: GRDB Repository Pattern

**⏱️ Estimated Time:** 1 Week  
**🎯 Learning Objective:** Implementeer type-veilige database toegang met GRDB repository pattern

---

## 📋 Prerequisites

Before starting this chapter:
- [ ] ✅ Chapter 1 completed - Database schema & value types are working
- [ ] ✅ All database tests passing
- [ ] ✅ GRDB dependency successfully added
- [ ] ✅ Basic understanding of repository pattern

---

## 🎯 Chapter Goals

By the end of this chapter, you will have:
- ✅ Een complete GRDB database connection setup
- ✅ Type-safe repository layer voor alle CRUD operations
- ✅ Database connection pooling voor performance
- ✅ Comprehensive error handling voor database operations
- ✅ Repository tests die de Point-Free patterns volgen
- ✅ Database observation setup voor reactive updates

**🌟 Point-Free Principle:** *"Create a clean abstraction layer that makes database operations simple and safe"*

---

## 📚 Lesson 2.1: Database Connection Setup

### Task 1: Create Database Manager

**Location:** `Library/Sources/Models/DatabaseManager.swift`

```swift
import Foundation
import GRDB
import Sharing

// MARK: - Database Manager
public final class DatabaseManager: @unchecked Sendable {
    private let dbQueue: DatabaseQueue
    
    public init(path: String? = nil) throws {
        if let path = path {
            // File-based database for production
            dbQueue = try DatabaseQueue(path: path)
        } else {
            // In-memory database for testing
            dbQueue = DatabaseQueue()
        }
        
        // Apply migrations
        try DatabaseMigrator.migrator().migrate(dbQueue)
        
        // Enable foreign key support
        try dbQueue.write { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
    }
    
    // MARK: - Database Access
    public var reader: DatabaseReader { dbQueue }
    public var writer: DatabaseWriter { dbQueue }
    
    // MARK: - Observation Support
    public func observation<T>(
        tracking request: @escaping (Database) throws -> T
    ) -> ValueObservation<T> {
        ValueObservation.tracking(request)
    }
}

// MARK: - Shared Database Instance
extension DatabaseManager {
    public static let shared: DatabaseManager = {
        do {
            let documentsPath = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
            let dbPath = documentsPath.appendingPathComponent("QuickCart.sqlite").path
            return try DatabaseManager(path: dbPath)
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }()
    
    public static let preview: DatabaseManager = {
        do {
            let manager = try DatabaseManager() // In-memory
            // Load sample data for previews
            try manager.loadSampleData()
            return manager
        } catch {
            fatalError("Failed to initialize preview database: \(error)")
        }
    }()
}

// MARK: - Sample Data Loading
extension DatabaseManager {
    public func loadSampleData() throws {
        try writer.write { db in
            // Insert sample shopping lists
            for list in SampleData.shoppingLists {
                try list.insert(db)
            }
            
            // Insert sample shopping items
            for item in SampleData.shoppingItems {
                try item.insert(db)
            }
        }
    }
}
```

**✅ Completion Check:**
- [ ] Database manager compiles without errors
- [ ] Both file-based and in-memory databases work
- [ ] Sample data loading works
- [ ] Foreign key constraints are enabled

---

## 📚 Lesson 2.2: Repository Base Pattern

### Task 2: Create Generic Repository Base

**Location:** `Library/Sources/Models/Repository.swift`

```swift
import Foundation
import GRDB
import Sharing

// MARK: - Repository Error Types
public enum RepositoryError: Error, LocalizedError {
    case notFound(String)
    case insertFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case queryFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "Record with ID \(id) not found"
        case .insertFailed(let error):
            return "Insert failed: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Update failed: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Delete failed: \(error.localizedDescription)"
        case .queryFailed(let error):
            return "Query failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Generic Repository Protocol
public protocol Repository {
    associatedtype Model: FetchableRecord & PersistableRecord & Identifiable
    
    var database: DatabaseManager { get }
    
    func fetch(id: Model.ID) async throws -> Model?
    func fetchAll() async throws -> [Model]
    func insert(_ model: Model) async throws -> Model
    func update(_ model: Model) async throws -> Model
    func delete(id: Model.ID) async throws
    func delete(_ model: Model) async throws
}

// MARK: - Repository Base Implementation
public actor RepositoryBase<T>: Repository where T: FetchableRecord & PersistableRecord & Identifiable {
    public typealias Model = T
    
    public let database: DatabaseManager
    
    public init(database: DatabaseManager = .shared) {
        self.database = database
    }
    
    // MARK: - CRUD Operations
    
    public func fetch(id: Model.ID) async throws -> Model? {
        do {
            return try await database.reader.read { db in
                try Model.fetchOne(db, key: id)
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
    
    public func fetchAll() async throws -> [Model] {
        do {
            return try await database.reader.read { db in
                try Model.fetchAll(db)
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
    
    public func insert(_ model: Model) async throws -> Model {
        do {
            try await database.writer.write { db in
                try model.insert(db)
            }
            return model
        } catch {
            throw RepositoryError.insertFailed(error)
        }
    }
    
    public func update(_ model: Model) async throws -> Model {
        do {
            try await database.writer.write { db in
                try model.update(db)
            }
            return model
        } catch {
            throw RepositoryError.updateFailed(error)
        }
    }
    
    public func delete(id: Model.ID) async throws {
        do {
            let rowsDeleted = try await database.writer.write { db in
                try Model.deleteOne(db, key: id)
            }
            if !rowsDeleted {
                throw RepositoryError.notFound("\(id)")
            }
        } catch {
            if case RepositoryError.notFound = error {
                throw error
            }
            throw RepositoryError.deleteFailed(error)
        }
    }
    
    public func delete(_ model: Model) async throws {
        try await delete(id: model.id)
    }
}
```

**✅ Completion Check:**
- [ ] Generic repository base is implemented
- [ ] All CRUD operations are async/await
- [ ] Comprehensive error handling
- [ ] Actor isolation for thread safety

---

## 📚 Lesson 2.3: Shopping List Repository

### Task 3: Create ShoppingListRepository

**Location:** `Library/Sources/Models/ShoppingListRepository.swift`

```swift
import Foundation
import GRDB

// MARK: - Shopping List Repository
public actor ShoppingListRepository: RepositoryBase<ShoppingList> {
    
    // MARK: - Custom Queries
    
    /// Fetch lists ordered by most recently updated
    public func fetchAllOrderedByDate() async throws -> [ShoppingList] {
        do {
            return try await database.reader.read { db in
                try ShoppingList
                    .order(ShoppingList.Columns.updatedAt.desc)
                    .fetchAll(db)
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
    
    /// Fetch lists with their item counts
    public func fetchListsWithItemCounts() async throws -> [ShoppingListWithCount] {
        do {
            return try await database.reader.read { db in
                let request = """
                    SELECT 
                        l.*,
                        COUNT(i.id) as item_count,
                        COUNT(CASE WHEN i.is_completed = 1 THEN 1 END) as completed_count
                    FROM shopping_lists l
                    LEFT JOIN shopping_items i ON l.id = i.shopping_list_id
                    GROUP BY l.id
                    ORDER BY l.updated_at DESC
                    """
                
                return try ShoppingListWithCount.fetchAll(db, sql: request)
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
    
    /// Create new list with timestamp
    public func createList(title: String) async throws -> ShoppingList {
        let now = Date()
        let list = ShoppingList(
            title: title,
            createdAt: now,
            updatedAt: now
        )
        return try await insert(list)
    }
    
    /// Update list title and timestamp
    public func updateTitle(listId: String, newTitle: String) async throws -> ShoppingList {
        guard let existingList = try await fetch(id: listId) else {
            throw RepositoryError.notFound(listId)
        }
        
        let updatedList = ShoppingList(
            id: existingList.id,
            title: newTitle,
            createdAt: existingList.createdAt,
            updatedAt: Date()
        )
        
        return try await update(updatedList)
    }
}

// MARK: - Helper Types

public struct ShoppingListWithCount: Codable, Identifiable {
    public let id: String
    public let title: String
    public let createdAt: Date
    public let updatedAt: Date
    public let itemCount: Int
    public let completedCount: Int
    
    public var completionPercentage: Double {
        guard itemCount > 0 else { return 0 }
        return Double(completedCount) / Double(itemCount)
    }
}

// MARK: - GRDB Integration
extension ShoppingListWithCount: FetchableRecord {
    public init(row: Row) throws {
        id = row["id"]
        title = row["title"]
        createdAt = Date(timeIntervalSince1970: row["created_at"])
        updatedAt = Date(timeIntervalSince1970: row["updated_at"])
        itemCount = row["item_count"]
        completedCount = row["completed_count"]
    }
}
```

**✅ Completion Check:**
- [ ] Shopping list repository extends base repository
- [ ] Custom queries for business logic are implemented
- [ ] Complex aggregations work (item counts)
- [ ] Timestamp management is handled correctly

---

## 📚 Lesson 2.4: Shopping Item Repository

### Task 4: Create ShoppingItemRepository

**Location:** `Library/Sources/Models/ShoppingItemRepository.swift`

```swift
import Foundation
import GRDB

// MARK: - Shopping Item Repository
public actor ShoppingItemRepository: RepositoryBase<ShoppingItem> {
    
    // MARK: - List-specific Operations
    
    /// Fetch all items for a specific shopping list
    public func fetchItems(forListId listId: String) async throws -> [ShoppingItem] {
        do {
            return try await database.reader.read { db in
                try ShoppingItem
                    .filter(ShoppingItem.Columns.shoppingListId == listId)
                    .order(ShoppingItem.Columns.createdAt.asc)
                    .fetchAll(db)
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
    
    /// Fetch items grouped by category for a list
    public func fetchItemsGroupedByCategory(forListId listId: String) async throws -> [ItemWithCategory] {
        do {
            return try await database.reader.read { db in
                let request = """
                    SELECT 
                        i.*,
                        c.name as category_name,
                        c.emoji as category_emoji,
                        c.sort_order as category_sort_order
                    FROM shopping_items i
                    JOIN item_categories c ON i.category_id = c.id
                    WHERE i.shopping_list_id = ?
                    ORDER BY c.sort_order, i.created_at
                    """
                
                return try ItemWithCategory.fetchAll(db, sql: request, arguments: [listId])
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
    
    /// Create new item for a list
    public func createItem(
        name: String,
        quantity: Int = 1,
        notes: String = "",
        categoryId: Int = 8, // Default to "Other"
        shoppingListId: String
    ) async throws -> ShoppingItem {
        let now = Date()
        let item = ShoppingItem(
            name: name,
            quantity: quantity,
            isCompleted: false,
            notes: notes,
            categoryId: categoryId,
            shoppingListId: shoppingListId,
            createdAt: now,
            updatedAt: now
        )
        
        return try await insert(item)
    }
    
    /// Toggle item completion status
    public func toggleCompletion(itemId: String) async throws -> ShoppingItem {
        guard let existingItem = try await fetch(id: itemId) else {
            throw RepositoryError.notFound(itemId)
        }
        
        let updatedItem = ShoppingItem(
            id: existingItem.id,
            name: existingItem.name,
            quantity: existingItem.quantity,
            isCompleted: !existingItem.isCompleted,
            notes: existingItem.notes,
            categoryId: existingItem.categoryId,
            shoppingListId: existingItem.shoppingListId,
            createdAt: existingItem.createdAt,
            updatedAt: Date()
        )
        
        return try await update(updatedItem)
    }
    
    /// Delete all completed items from a list
    public func deleteCompletedItems(forListId listId: String) async throws {
        do {
            _ = try await database.writer.write { db in
                try ShoppingItem
                    .filter(ShoppingItem.Columns.shoppingListId == listId)
                    .filter(ShoppingItem.Columns.isCompleted == true)
                    .deleteAll(db)
            }
        } catch {
            throw RepositoryError.deleteFailed(error)
        }
    }
    
    /// Update item details
    public func updateItem(
        itemId: String,
        name: String,
        quantity: Int,
        notes: String,
        categoryId: Int
    ) async throws -> ShoppingItem {
        guard let existingItem = try await fetch(id: itemId) else {
            throw RepositoryError.notFound(itemId)
        }
        
        let updatedItem = ShoppingItem(
            id: existingItem.id,
            name: name,
            quantity: quantity,
            isCompleted: existingItem.isCompleted,
            notes: notes,
            categoryId: categoryId,
            shoppingListId: existingItem.shoppingListId,
            createdAt: existingItem.createdAt,
            updatedAt: Date()
        )
        
        return try await update(updatedItem)
    }
}

// MARK: - Helper Types

public struct ItemWithCategory: Codable, Identifiable {
    public let id: String
    public let name: String
    public let quantity: Int
    public let isCompleted: Bool
    public let notes: String
    public let categoryId: Int
    public let shoppingListId: String
    public let createdAt: Date
    public let updatedAt: Date
    
    // Category info
    public let categoryName: String
    public let categoryEmoji: String
    public let categorySortOrder: Int
    
    public var displayName: String {
        quantity > 1 ? "\(quantity)x \(name)" : name
    }
}

// MARK: - GRDB Integration
extension ItemWithCategory: FetchableRecord {
    public init(row: Row) throws {
        id = row["id"]
        name = row["name"]
        quantity = row["quantity"]
        isCompleted = row["is_completed"]
        notes = row["notes"]
        categoryId = row["category_id"]
        shoppingListId = row["shopping_list_id"]
        createdAt = Date(timeIntervalSince1970: row["created_at"])
        updatedAt = Date(timeIntervalSince1970: row["updated_at"])
        
        categoryName = row["category_name"]
        categoryEmoji = row["category_emoji"]
        categorySortOrder = row["category_sort_order"]
    }
}
```

**✅ Completion Check:**
- [ ] Item repository with list-specific operations
- [ ] Complex JOIN queries work correctly
- [ ] Business logic operations (toggle, update) implemented
- [ ] Helper types for enhanced data are created

---

## 📚 Lesson 2.5: Category Repository

### Task 5: Create CategoryRepository

**Location:** `Library/Sources/Models/CategoryRepository.swift`

```swift
import Foundation
import GRDB

// MARK: - Category Repository
public actor CategoryRepository: RepositoryBase<ItemCategory> {
    
    /// Fetch all categories ordered by sort order
    public func fetchAllOrdered() async throws -> [ItemCategory] {
        do {
            return try await database.reader.read { db in
                try ItemCategory
                    .order(ItemCategory.Columns.sortOrder.asc)
                    .fetchAll(db)
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
    
    /// Fetch category by name
    public func fetchCategory(byName name: String) async throws -> ItemCategory? {
        do {
            return try await database.reader.read { db in
                try ItemCategory
                    .filter(ItemCategory.Columns.name == name)
                    .fetchOne(db)
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
    
    /// Get category statistics for a specific list
    public func fetchCategoryStats(forListId listId: String) async throws -> [CategoryStats] {
        do {
            return try await database.reader.read { db in
                let request = """
                    SELECT 
                        c.id,
                        c.name,
                        c.emoji,
                        c.sort_order,
                        COUNT(i.id) as item_count,
                        COUNT(CASE WHEN i.is_completed = 1 THEN 1 END) as completed_count
                    FROM item_categories c
                    LEFT JOIN shopping_items i ON c.id = i.category_id AND i.shopping_list_id = ?
                    GROUP BY c.id, c.name, c.emoji, c.sort_order
                    HAVING item_count > 0
                    ORDER BY c.sort_order
                    """
                
                return try CategoryStats.fetchAll(db, sql: request, arguments: [listId])
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
}

// MARK: - Category Statistics

public struct CategoryStats: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let emoji: String
    public let sortOrder: Int
    public let itemCount: Int
    public let completedCount: Int
    
    public var completionPercentage: Double {
        guard itemCount > 0 else { return 0 }
        return Double(completedCount) / Double(itemCount)
    }
    
    public var pendingCount: Int {
        itemCount - completedCount
    }
}

// MARK: - GRDB Integration
extension CategoryStats: FetchableRecord {
    public init(row: Row) throws {
        id = row["id"]
        name = row["name"]
        emoji = row["emoji"]
        sortOrder = row["sort_order"]
        itemCount = row["item_count"]
        completedCount = row["completed_count"]
    }
}
```

**✅ Completion Check:**
- [ ] Category repository with statistics queries
- [ ] Category-based analytics implemented
- [ ] Complex aggregation queries work
- [ ] Helper types for category statistics

---

## 🧪 Testing Repository Layer

### Task 6: Create Repository Tests

**Location:** `Library/Tests/LibraryTests/RepositoryTests.swift`

```swift
import XCTest
import GRDB
@testable import Models

final class RepositoryTests: XCTestCase {
    var database: DatabaseManager!
    var shoppingListRepo: ShoppingListRepository!
    var shoppingItemRepo: ShoppingItemRepository!
    var categoryRepo: CategoryRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Use in-memory database for tests
        database = try DatabaseManager()
        shoppingListRepo = ShoppingListRepository(database: database)
        shoppingItemRepo = ShoppingItemRepository(database: database)
        categoryRepo = CategoryRepository(database: database)
    }
    
    func testShoppingListCRUD() async throws {
        // Create
        let list = try await shoppingListRepo.createList(title: "Test List")
        XCTAssertEqual(list.title, "Test List")
        XCTAssertFalse(list.id.isEmpty)
        
        // Read
        let fetchedList = try await shoppingListRepo.fetch(id: list.id)
        XCTAssertNotNil(fetchedList)
        XCTAssertEqual(fetchedList?.title, "Test List")
        
        // Update
        let updatedList = try await shoppingListRepo.updateTitle(
            listId: list.id,
            newTitle: "Updated List"
        )
        XCTAssertEqual(updatedList.title, "Updated List")
        
        // Delete
        try await shoppingListRepo.delete(id: list.id)
        let deletedList = try await shoppingListRepo.fetch(id: list.id)
        XCTAssertNil(deletedList)
    }
    
    func testShoppingItemOperations() async throws {
        // First create a list
        let list = try await shoppingListRepo.createList(title: "Test List")
        
        // Create item
        let item = try await shoppingItemRepo.createItem(
            name: "Test Item",
            quantity: 2,
            shoppingListId: list.id
        )
        XCTAssertEqual(item.name, "Test Item")
        XCTAssertEqual(item.quantity, 2)
        XCTAssertFalse(item.isCompleted)
        
        // Toggle completion
        let toggledItem = try await shoppingItemRepo.toggleCompletion(itemId: item.id)
        XCTAssertTrue(toggledItem.isCompleted)
        
        // Fetch items for list
        let items = try await shoppingItemRepo.fetchItems(forListId: list.id)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "Test Item")
    }
    
    func testListWithItemCounts() async throws {
        let list = try await shoppingListRepo.createList(title: "Test List")
        
        // Add some items
        _ = try await shoppingItemRepo.createItem(name: "Item 1", shoppingListId: list.id)
        let item2 = try await shoppingItemRepo.createItem(name: "Item 2", shoppingListId: list.id)
        
        // Complete one item
        _ = try await shoppingItemRepo.toggleCompletion(itemId: item2.id)
        
        // Fetch lists with counts
        let listsWithCounts = try await shoppingListRepo.fetchListsWithItemCounts()
        XCTAssertEqual(listsWithCounts.count, 1)
        
        let listWithCount = listsWithCounts.first!
        XCTAssertEqual(listWithCount.itemCount, 2)
        XCTAssertEqual(listWithCount.completedCount, 1)
        XCTAssertEqual(listWithCount.completionPercentage, 0.5)
    }
    
    func testCategoryQueries() async throws {
        // Categories should be populated from migration
        let categories = try await categoryRepo.fetchAllOrdered()
        XCTAssertEqual(categories.count, 8)
        
        // First category should be "Produce"
        let produce = categories.first
        XCTAssertEqual(produce?.name, "Produce")
        XCTAssertEqual(produce?.emoji, "🥬")
    }
    
    func testComplexJoinQuery() async throws {
        let list = try await shoppingListRepo.createList(title: "Test List")
        
        // Create item with specific category (Produce = 1)
        _ = try await shoppingItemRepo.createItem(
            name: "Bananas",
            categoryId: 1,
            shoppingListId: list.id
        )
        
        // Fetch items with category info
        let itemsWithCategory = try await shoppingItemRepo.fetchItemsGroupedByCategory(forListId: list.id)
        XCTAssertEqual(itemsWithCategory.count, 1)
        
        let item = itemsWithCategory.first!
        XCTAssertEqual(item.name, "Bananas")
        XCTAssertEqual(item.categoryName, "Produce")
        XCTAssertEqual(item.categoryEmoji, "🥬")
    }
}
```

Run your repository tests:
```bash
xcodebuild test -scheme Library -destination 'platform=iOS Simulator,name=iPhone 15'
```

**✅ Completion Check:**
- [ ] All repository tests pass
- [ ] CRUD operations work correctly
- [ ] Complex queries and joins are tested
- [ ] Error handling is validated

---

## 🎉 Chapter 2 Complete!

### Final Checklist

Before moving to Chapter 3, ensure:

- [ ] ✅ GRDB database manager is properly configured
- [ ] ✅ Generic repository base pattern implemented
- [ ] ✅ Shopping list repository with custom queries
- [ ] ✅ Shopping item repository with business logic
- [ ] ✅ Category repository with statistics
- [ ] ✅ All repository tests passing
- [ ] ✅ Error handling covers all scenarios
- [ ] ✅ Async/await patterns correctly implemented

### What You've Built

🎊 **Geweldig werk!** Je hebt nu:

- **Type-Safe Repository Layer**: Veilige database toegang met compile-time checks
- **Modern Async/Await**: All database operations zijn async voor betere performance
- **Business Logic Separation**: Repository handles data, UI handles presentation
- **Comprehensive Error Handling**: Graceful handling van database errors
- **Complex Query Support**: JOINs, aggregations, and custom SQL queries
- **Actor-Based Thread Safety**: Modern Swift concurrency voor database access
- **Point-Free Architecture**: Clean separation tussen data en business logic

### Key Learnings

📚 **Je hebt geleerd:**
- GRDB setup en configuration voor production apps
- Repository pattern implementation met Swift generics
- Complex SQL queries met type-safe Swift integration
- Modern Swift concurrency patterns (async/await, actors)
- Database observation setup voor reactive programming
- Test-driven development voor database layers

### Next Steps

Ready for **Chapter 3: Type-Safe Queries & UI Binding**? Je gaat nu StructuredQueries gebruiken en reactive UI bouwen!

---

**🤔 Vragen over repository patterns?** Test je queries thoroughly en vraag Claude Code om hulp bij complex SQL!