# Chapter 3: Type-Safe Queries & UI Binding

**⏱️ Estimated Time:** 1 Week  
**🎯 Learning Objective:** Bouw reactive UI met type-safe SQL queries via StructuredQueries & SharingGRDB

---

## 📋 Prerequisites

Before starting this chapter:
- [ ] ✅ Chapter 2 completed - Repository pattern working
- [ ] ✅ All repository tests passing
- [ ] ✅ Understanding van GRDB basics
- [ ] ✅ Basic SwiftUI knowledge

---

## 🎯 Chapter Goals

By the end of this chapter, you will have:
- ✅ StructuredQueries library geïntegreerd voor type-safe SQL
- ✅ @FetchAll property wrapper voor reactive UI updates
- ✅ Type-safe query composition voor complex database operations
- ✅ SwiftUI views die automatisch updaten met database changes
- ✅ Advanced query patterns voor search en filtering
- ✅ Performance-optimized database observations

**🌟 Point-Free Principle:** *"Build type-safe queries that compile to efficient SQL and drive reactive UI updates"*

---

## 📚 Lesson 3.1: StructuredQueries Setup

### Task 1: Add StructuredQueries Dependencies

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
        .package(url: "https://github.com/pointfreeco/swift-structured-queries.git", from: "0.10.0"),
    ],
    targets: [
        .target(
            name: "Models",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Sharing", package: "swift-sharing"),
                .product(name: "StructuredQueriesCore", package: "swift-structured-queries"),
            ]
        ),
        .target(
            name: "AppFeature",
            dependencies: [
                "Models",
                .product(name: "SharingGRDBCore", package: "swift-sharing"),
            ]
        ),
        .testTarget(
            name: "LibraryTests",
            dependencies: ["Models", "AppFeature"]
        ),
    ]
)
```

**✅ Completion Check:**
- [ ] StructuredQueries dependency toegevoegd
- [ ] SharingGRDB dependency toegevoegd voor AppFeature
- [ ] Project compileert zonder errors

---

## 📚 Lesson 3.2: Table Definitions met StructuredQueries

### Task 2: Create Type-Safe Table Definitions

**Location:** `Library/Sources/Models/TableDefinitions.swift`

```swift
import Foundation
import GRDB
import StructuredQueriesCore

// MARK: - Shopping Lists Table Definition
public struct ShoppingListsTable: Table {
    public static let databaseTableName = "shopping_lists"
    
    public let id = Column("id", .text, .primaryKey)
    public let title = Column("title", .text, .notNull)
    public let createdAt = Column("created_at", .real, .notNull)
    public let updatedAt = Column("updated_at", .real, .notNull)
}

// MARK: - Shopping Items Table Definition
public struct ShoppingItemsTable: Table {
    public static let databaseTableName = "shopping_items"
    
    public let id = Column("id", .text, .primaryKey)
    public let name = Column("name", .text, .notNull)
    public let quantity = Column("quantity", .integer, .notNull)
    public let isCompleted = Column("is_completed", .integer, .notNull)
    public let notes = Column("notes", .text, .notNull)
    public let categoryId = Column("category_id", .integer, .notNull)
    public let shoppingListId = Column("shopping_list_id", .text, .notNull)
    public let createdAt = Column("created_at", .real, .notNull)
    public let updatedAt = Column("updated_at", .real, .notNull)
}

// MARK: - Item Categories Table Definition
public struct ItemCategoriesTable: Table {
    public static let databaseTableName = "item_categories"
    
    public let id = Column("id", .integer, .primaryKey)
    public let name = Column("name", .text, .notNull)
    public let emoji = Column("emoji", .text, .notNull)
    public let sortOrder = Column("sort_order", .integer, .notNull)
}

// MARK: - Global Table Instances
public let shoppingListsTable = ShoppingListsTable()
public let shoppingItemsTable = ShoppingItemsTable()
public let itemCategoriesTable = ItemCategoriesTable()
```

**✅ Completion Check:**
- [ ] Alle tables gedefinieerd met StructuredQueries syntax
- [ ] Column types matchen SQL schema exact
- [ ] Global table instances beschikbaar

---

## 📚 Lesson 3.3: Type-Safe Query Builders

### Task 3: Create Query Extensions

**Location:** `Library/Sources/Models/QueryExtensions.swift`

```swift
import Foundation
import GRDB
import StructuredQueriesCore

// MARK: - Shopping List Queries
public extension QueryInterface where T == ShoppingListsTable {
    /// Fetch all lists ordered by most recent update
    static func allOrderedByDate() -> some SelectStatement<ShoppingList> {
        from(shoppingListsTable)
            .orderBy(.desc(shoppingListsTable.updatedAt))
    }
    
    /// Fetch lists with item counts using LEFT JOIN
    static func withItemCounts() -> some SelectStatement<ShoppingListWithCount> {
        from(shoppingListsTable)
            .leftJoin(shoppingItemsTable, on: shoppingListsTable.id == shoppingItemsTable.shoppingListId)
            .select([
                shoppingListsTable.id,
                shoppingListsTable.title, 
                shoppingListsTable.createdAt,
                shoppingListsTable.updatedAt,
                count(shoppingItemsTable.id).as("item_count"),
                countIf(shoppingItemsTable.isCompleted == 1).as("completed_count")
            ])
            .groupBy([shoppingListsTable.id])
            .orderBy(.desc(shoppingListsTable.updatedAt))
    }
    
    /// Find list by exact title
    static func byTitle(_ title: String) -> some SelectStatement<ShoppingList> {
        from(shoppingListsTable)
            .where(shoppingListsTable.title == title)
    }
    
    /// Search lists by title pattern
    static func searchByTitle(_ searchTerm: String) -> some SelectStatement<ShoppingList> {
        from(shoppingListsTable)
            .where(shoppingListsTable.title.like("%\(searchTerm)%"))
            .orderBy(.desc(shoppingListsTable.updatedAt))
    }
}

// MARK: - Shopping Item Queries  
public extension QueryInterface where T == ShoppingItemsTable {
    /// Fetch all items for a specific list
    static func forList(_ listId: String) -> some SelectStatement<ShoppingItem> {
        from(shoppingItemsTable)
            .where(shoppingItemsTable.shoppingListId == listId)
            .orderBy(.asc(shoppingItemsTable.createdAt))
    }
    
    /// Fetch items with category information using INNER JOIN
    static func withCategories(forListId listId: String) -> some SelectStatement<ItemWithCategory> {
        from(shoppingItemsTable)
            .join(itemCategoriesTable, on: shoppingItemsTable.categoryId == itemCategoriesTable.id)
            .where(shoppingItemsTable.shoppingListId == listId)
            .select([
                shoppingItemsTable.allColumns,
                itemCategoriesTable.name.as("category_name"),
                itemCategoriesTable.emoji.as("category_emoji"),
                itemCategoriesTable.sortOrder.as("category_sort_order")
            ])
            .orderBy([.asc(itemCategoriesTable.sortOrder), .asc(shoppingItemsTable.createdAt)])
    }
    
    /// Fetch completed items for a list
    static func completed(forListId listId: String) -> some SelectStatement<ShoppingItem> {
        from(shoppingItemsTable)
            .where(shoppingItemsTable.shoppingListId == listId)
            .where(shoppingItemsTable.isCompleted == 1)
            .orderBy(.desc(shoppingItemsTable.updatedAt))
    }
    
    /// Fetch pending items for a list
    static func pending(forListId listId: String) -> some SelectStatement<ShoppingItem> {
        from(shoppingItemsTable)
            .where(shoppingItemsTable.shoppingListId == listId)
            .where(shoppingItemsTable.isCompleted == 0)
            .orderBy(.asc(shoppingItemsTable.createdAt))
    }
    
    /// Search items by name within a list
    static func search(_ searchTerm: String, inListId listId: String) -> some SelectStatement<ShoppingItem> {
        from(shoppingItemsTable)
            .where(shoppingItemsTable.shoppingListId == listId)
            .where(shoppingItemsTable.name.like("%\(searchTerm)%"))
            .orderBy(.asc(shoppingItemsTable.name))
    }
    
    /// Complex aggregation: items grouped by category with counts
    static func categoryStats(forListId listId: String) -> some SelectStatement<CategoryStats> {
        from(shoppingItemsTable)
            .join(itemCategoriesTable, on: shoppingItemsTable.categoryId == itemCategoriesTable.id)
            .where(shoppingItemsTable.shoppingListId == listId)
            .select([
                itemCategoriesTable.id,
                itemCategoriesTable.name,
                itemCategoriesTable.emoji,
                itemCategoriesTable.sortOrder,
                count(shoppingItemsTable.id).as("item_count"),
                countIf(shoppingItemsTable.isCompleted == 1).as("completed_count")
            ])
            .groupBy([itemCategoriesTable.id])
            .having(count(shoppingItemsTable.id) > 0)
            .orderBy(.asc(itemCategoriesTable.sortOrder))
    }
}

// MARK: - Helper Functions
public func countIf<T>(_ condition: T) -> CountExpression {
    count(case: when(condition, then: 1))
}
```

**✅ Completion Check:**
- [ ] Type-safe query builders geïmplementeerd
- [ ] Complex JOIN queries werken
- [ ] Aggregation functions correct gedefinieerd
- [ ] Search en filtering patterns werkend

---

## 📚 Lesson 3.4: Repository Updates met StructuredQueries

### Task 4: Update Repositories met Type-Safe Queries

**Location:** `Library/Sources/Models/StructuredQueriesRepository.swift`

```swift
import Foundation
import GRDB
import StructuredQueriesCore

// MARK: - Updated Shopping List Repository
public extension ShoppingListRepository {
    /// Fetch lists using type-safe queries
    func fetchAllOrderedByDateStructured() async throws -> [ShoppingList] {
        do {
            return try await database.reader.read { db in
                try QueryInterface<ShoppingListsTable>.allOrderedByDate().fetchAll(db)
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
    
    /// Fetch lists with counts using structured query
    func fetchListsWithItemCountsStructured() async throws -> [ShoppingListWithCount] {
        do {
            return try await database.reader.read { db in
                try QueryInterface<ShoppingListsTable>.withItemCounts().fetchAll(db)
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
    
    /// Search lists by title
    func searchLists(byTitle searchTerm: String) async throws -> [ShoppingList] {
        do {
            return try await database.reader.read { db in
                try QueryInterface<ShoppingListsTable>.searchByTitle(searchTerm).fetchAll(db)
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
}

// MARK: - Updated Shopping Item Repository
public extension ShoppingItemRepository {
    /// Fetch items using structured query
    func fetchItemsStructured(forListId listId: String) async throws -> [ShoppingItem] {
        do {
            return try await database.reader.read { db in
                try QueryInterface<ShoppingItemsTable>.forList(listId).fetchAll(db)
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
    
    /// Fetch items with category info using structured query
    func fetchItemsWithCategoriesStructured(forListId listId: String) async throws -> [ItemWithCategory] {
        do {
            return try await database.reader.read { db in
                try QueryInterface<ShoppingItemsTable>.withCategories(forListId: listId).fetchAll(db)
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
    
    /// Search items within a list
    func searchItems(_ searchTerm: String, inListId listId: String) async throws -> [ShoppingItem] {
        do {
            return try await database.reader.read { db in
                try QueryInterface<ShoppingItemsTable>.search(searchTerm, inListId: listId).fetchAll(db)
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
    
    /// Get category statistics for a list
    func fetchCategoryStatsStructured(forListId listId: String) async throws -> [CategoryStats] {
        do {
            return try await database.reader.read { db in
                try QueryInterface<ShoppingItemsTable>.categoryStats(forListId: listId).fetchAll(db)
            }
        } catch {
            throw RepositoryError.queryFailed(error)
        }
    }
}
```

**✅ Completion Check:**
- [ ] Repository methods gebruik maken van StructuredQueries
- [ ] Type safety op compile-time gegarandeerd
- [ ] Query compositie werkt correct
- [ ] Performance is geoptimaliseerd

---

## 📚 Lesson 3.5: @FetchAll Property Wrapper Setup

### Task 5: Create SharingGRDB Integration

**Location:** `Library/Sources/AppFeature/DatabaseObservation.swift`

```swift
import SwiftUI
import GRDB
import SharingGRDBCore
import Models

// MARK: - Database Observation Keys
extension SharedReaderKey where Self == DatabaseKey {
    /// Shared database reader for the entire app
    public static var database: DatabaseKey { DatabaseKey() }
}

public struct DatabaseKey: SharedReaderKey {
    public var reader: DatabaseReader { DatabaseManager.shared.reader }
}

// MARK: - Shopping Lists Observation
@propertyWrapper
public struct FetchShoppingLists: DynamicProperty {
    @FetchAll<ShoppingListWithCount> private var lists: [ShoppingListWithCount]
    
    public init() {
        self._lists = FetchAll(
            .database,
            query: QueryInterface<ShoppingListsTable>.withItemCounts()
        )
    }
    
    public var wrappedValue: [ShoppingListWithCount] { lists }
    public var projectedValue: Binding<[ShoppingListWithCount]> {
        Binding(
            get: { lists },
            set: { _ in } // Read-only binding for database-driven data
        )
    }
}

// MARK: - Shopping Items Observation
@propertyWrapper  
public struct FetchShoppingItems: DynamicProperty {
    @FetchAll<ItemWithCategory> private var items: [ItemWithCategory]
    
    public init(listId: String) {
        self._items = FetchAll(
            .database,
            query: QueryInterface<ShoppingItemsTable>.withCategories(forListId: listId)
        )
    }
    
    public var wrappedValue: [ItemWithCategory] { items }
}

// MARK: - Category Statistics Observation
@propertyWrapper
public struct FetchCategoryStats: DynamicProperty {
    @FetchAll<CategoryStats> private var stats: [CategoryStats]
    
    public init(listId: String) {
        self._stats = FetchAll(
            .database, 
            query: QueryInterface<ShoppingItemsTable>.categoryStats(forListId: listId)
        )
    }
    
    public var wrappedValue: [CategoryStats] { stats }
}

// MARK: - Dynamic Search Query
@propertyWrapper
public struct FetchSearchResults: DynamicProperty {
    @State private var searchTerm: String
    @FetchAll<ShoppingItem> private var results: [ShoppingItem]
    
    public init(listId: String, searchTerm: String = "") {
        self._searchTerm = State(initialValue: searchTerm)
        
        if searchTerm.isEmpty {
            self._results = FetchAll(
                .database,
                query: QueryInterface<ShoppingItemsTable>.forList(listId)
            )
        } else {
            self._results = FetchAll(
                .database,
                query: QueryInterface<ShoppingItemsTable>.search(searchTerm, inListId: listId)
            )
        }
    }
    
    public var wrappedValue: [ShoppingItem] { results }
    
    public func updateSearch(_ newSearchTerm: String, listId: String) {
        searchTerm = newSearchTerm
        // Update query dynamically
        _results.query = newSearchTerm.isEmpty 
            ? QueryInterface<ShoppingItemsTable>.forList(listId)
            : QueryInterface<ShoppingItemsTable>.search(newSearchTerm, inListId: listId)
    }
}
```

**✅ Completion Check:**
- [ ] @FetchAll property wrappers geïmplementeerd
- [ ] Database observations real-time updates geven
- [ ] Search functionality is reactive
- [ ] Proper binding patterns voor SwiftUI

---

## 📚 Lesson 3.6: Reactive SwiftUI Views

### Task 6: Create Database-Driven Views

**Location:** `Library/Sources/AppFeature/ReactiveViews.swift`

```swift
import SwiftUI
import Models

// MARK: - Main Content View
public struct ReactiveContentView: View {
    @FetchShoppingLists private var lists
    @State private var selectedList: ShoppingListWithCount?
    @State private var showingAddList = false
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            ReactiveListsView(
                lists: lists,
                selectedList: $selectedList,
                showingAddList: $showingAddList
            )
        } detail: {
            if let selectedList {
                ReactiveListDetailView(list: selectedList)
            } else {
                PlaceholderView()
            }
        }
    }
}

// MARK: - Reactive Lists Overview
struct ReactiveListsView: View {
    let lists: [ShoppingListWithCount]
    @Binding var selectedList: ShoppingListWithCount?
    @Binding var showingAddList: Bool
    
    var body: some View {
        List(selection: $selectedList) {
            ForEach(lists) { list in
                NavigationLink(value: list) {
                    ReactiveListRowView(list: list)
                }
            }
        }
        .navigationTitle("Boodschappenlijsten")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Nieuwe Lijst") {
                    showingAddList = true
                }
            }
        }
        .sheet(isPresented: $showingAddList) {
            AddListView()
        }
    }
}

// MARK: - Reactive List Row with Real-time Updates
struct ReactiveListRowView: View {
    let list: ShoppingListWithCount
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(list.title)
                    .font(.headline)
                
                Spacer()
                
                Text("\\(list.completedCount)/\\(list.itemCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: list.completionPercentage)
                .tint(.green)
            
            Text("Bijgewerkt \\(list.updatedAt.formatted(.relative(presentation: .named)))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Reactive List Detail View
struct ReactiveListDetailView: View {
    let list: ShoppingListWithCount
    @FetchShoppingItems private var items
    @FetchCategoryStats private var categoryStats
    @State private var searchText = ""
    @State private var showingAddItem = false
    
    init(list: ShoppingListWithCount) {
        self.list = list
        self._items = FetchShoppingItems(listId: list.id)
        self._categoryStats = FetchCategoryStats(listId: list.id)
    }
    
    var body: some View {
        List {
            if items.isEmpty {
                EmptyStateView {
                    showingAddItem = true
                }
            } else {
                // Group items by category
                ForEach(categoryStats) { categoryStat in
                    let categoryItems = items.filter { $0.categoryId == categoryStat.id }
                    
                    if !categoryItems.isEmpty {
                        Section {
                            ForEach(categoryItems) { item in
                                ReactiveItemRowView(item: item)
                            }
                        } header: {
                            HStack {
                                Text("\\(categoryStat.emoji) \\(categoryStat.name)")
                                Spacer()
                                if categoryStat.itemCount > 0 {
                                    Text("\\(categoryStat.completedCount)/\\(categoryStat.itemCount)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(list.title)
        .searchable(text: $searchText, prompt: "Zoek items")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button("Voltooide items verwijderen") {
                        Task { await clearCompleted() }
                    }
                    .disabled(list.completedCount == 0)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                
                Button("Item toevoegen") {
                    showingAddItem = true
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemView(listId: list.id)
        }
    }
    
    @MainActor
    private func clearCompleted() async {
        // Repository call - UI will update automatically via @FetchAll
        let itemRepo = ShoppingItemRepository()
        try? await itemRepo.deleteCompletedItems(forListId: list.id)
    }
}

// MARK: - Reactive Item Row
struct ReactiveItemRowView: View {
    let item: ItemWithCategory
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion checkbox
            Button {
                Task { await toggleCompletion() }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // Item content
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                
                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            EditItemView(item: item)
        }
    }
    
    @MainActor
    private func toggleCompletion() async {
        // Repository call - UI will update automatically via @FetchAll
        let itemRepo = ShoppingItemRepository()
        try? await itemRepo.toggleCompletion(itemId: item.id)
    }
}

// MARK: - Placeholder View
struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Selecteer een lijst")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Kies een boodschappenlijst om de items te bekijken")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let onAddItem: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Je lijst is leeg")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Voeg wat items toe om te beginnen")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Button("Item toevoegen") {
                onAddItem()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ReactiveContentView()
}
```

**✅ Completion Check:**
- [ ] SwiftUI views gebruiken @FetchAll voor reactive updates
- [ ] Database changes triggeren automatisch UI updates
- [ ] Search functionality werkt real-time
- [ ] Category grouping wordt dynamisch bijgewerkt

---

## 🧪 Testing Type-Safe Queries

### Task 7: Create StructuredQueries Tests

**Location:** `Library/Tests/LibraryTests/StructuredQueriesTests.swift`

```swift
import XCTest
import GRDB
import StructuredQueriesCore
@testable import Models

final class StructuredQueriesTests: XCTestCase {
    var database: DatabaseManager!
    var shoppingListRepo: ShoppingListRepository!
    var shoppingItemRepo: ShoppingItemRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        
        database = try DatabaseManager()
        shoppingListRepo = ShoppingListRepository(database: database)
        shoppingItemRepo = ShoppingItemRepository(database: database)
        
        // Insert test data
        let list = try await shoppingListRepo.createList(title: "Test List")
        _ = try await shoppingItemRepo.createItem(
            name: "Test Item 1",
            categoryId: 1, // Produce
            shoppingListId: list.id
        )
        _ = try await shoppingItemRepo.createItem(
            name: "Test Item 2", 
            quantity: 3,
            categoryId: 2, // Dairy
            shoppingListId: list.id
        )
    }
    
    func testTypesSafeListQuery() async throws {
        // Test structured query compilation
        let lists = try await shoppingListRepo.fetchAllOrderedByDateStructured()
        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(lists.first?.title, "Test List")
    }
    
    func testListsWithItemCounts() async throws {
        let listsWithCounts = try await shoppingListRepo.fetchListsWithItemCountsStructured()
        XCTAssertEqual(listsWithCounts.count, 1)
        
        let list = listsWithCounts.first!
        XCTAssertEqual(list.itemCount, 2)
        XCTAssertEqual(list.completedCount, 0)
        XCTAssertEqual(list.completionPercentage, 0.0)
    }
    
    func testItemsWithCategoriesJoin() async throws {
        let list = try await shoppingListRepo.createList(title: "Test List")
        let items = try await shoppingItemRepo.fetchItemsWithCategoriesStructured(forListId: list.id)
        
        XCTAssertEqual(items.count, 2)
        
        let firstItem = items.first!
        XCTAssertEqual(firstItem.categoryName, "Produce")
        XCTAssertEqual(firstItem.categoryEmoji, "🥬")
        XCTAssertEqual(firstItem.categorySortOrder, 1)
    }
    
    func testSearchQuery() async throws {
        let list = try await shoppingListRepo.createList(title: "Test List")
        
        // Search should find item with "Test" in name
        let results = try await shoppingItemRepo.searchItems("Test", inListId: list.id)
        XCTAssertEqual(results.count, 2)
        
        // Search for specific item
        let specificResults = try await shoppingItemRepo.searchItems("Item 1", inListId: list.id)
        XCTAssertEqual(specificResults.count, 1)
        XCTAssertEqual(specificResults.first?.name, "Test Item 1")
    }
    
    func testCategoryStatsAggregation() async throws {
        let list = try await shoppingListRepo.createList(title: "Test List")
        let stats = try await shoppingItemRepo.fetchCategoryStatsStructured(forListId: list.id)
        
        // Should have stats for 2 categories (Produce and Dairy)
        XCTAssertEqual(stats.count, 2)
        
        let produceStats = stats.first { $0.name == "Produce" }
        XCTAssertNotNil(produceStats)
        XCTAssertEqual(produceStats?.itemCount, 1)
        XCTAssertEqual(produceStats?.completedCount, 0)
    }
    
    func testQueryComposition() async throws {
        // Test that queries can be composed and still type-check
        let list = try await shoppingListRepo.createList(title: "Search Test")
        
        do {
            let query = QueryInterface<ShoppingItemsTable>
                .forList(list.id)
                .where(shoppingItemsTable.name.like("%Test%"))
                .orderBy(.desc(shoppingItemsTable.createdAt))
            
            let results = try await database.reader.read { db in
                try query.fetchAll(db)
            }
            
            XCTAssertEqual(results.count, 2)
        } catch {
            XCTFail("Query composition failed: \\(error)")
        }
    }
    
    func testCompileTimeTypeSafety() {
        // This test verifies that queries are type-safe at compile time
        // If any of these don't compile, the type safety is working!
        
        let _ = QueryInterface<ShoppingListsTable>
            .allOrderedByDate()
            .where(shoppingListsTable.title == "Test")
            .limit(10)
        
        let _ = QueryInterface<ShoppingItemsTable>
            .forList("test-id")
            .where(shoppingItemsTable.isCompleted == 0)
            .orderBy(.asc(shoppingItemsTable.name))
        
        // These should NOT compile if you uncomment them:
        // let _ = shoppingListsTable.nonExistentColumn  // ❌ Compile error
        // let _ = shoppingItemsTable.title               // ❌ Wrong table
        
        XCTAssertTrue(true, "All queries compiled successfully")
    }
}
```

**✅ Completion Check:**
- [ ] Type-safe query tests pass
- [ ] Complex JOIN queries tested
- [ ] Search functionality verified
- [ ] Compile-time type safety confirmed

---

## 🎉 Chapter 3 Complete!

### Final Checklist

Before moving to Chapter 4, ensure:

- [ ] ✅ StructuredQueries library geïntegreerd
- [ ] ✅ Type-safe table definitions gecreëerd
- [ ] ✅ Query builders voor alle belangrijke operations
- [ ] ✅ Repository methods updated met structured queries
- [ ] ✅ @FetchAll property wrappers werkend
- [ ] ✅ Reactive SwiftUI views geïmplementeerd
- [ ] ✅ Real-time UI updates via database observations
- [ ] ✅ All structured query tests passing

### What You've Built

🎊 **Fantastisch werk!** Je hebt nu:

- **Type-Safe SQL Queries**: Compile-time validatie van alle database queries
- **Reactive UI Architecture**: SwiftUI views die automatisch updaten met database changes
- **Advanced Query Composition**: Complex JOINs, aggregations, en search patterns
- **Real-Time Updates**: @FetchAll property wrapper voor seamless data binding
- **Performance Optimized**: Efficient database observations zonder memory leaks
- **Point-Free Architecture**: Database-driven UI met moderne Swift patterns
- **Compile-Time Safety**: Geen runtime SQL errors meer mogelijk

### Key Learnings

📚 **Je hebt geleerd:**
- StructuredQueries voor type-safe SQL query building
- SharingGRDB voor reactive database observations
- Advanced SwiftUI integration met database state
- Complex query composition patterns
- Real-time UI update architectuur
- Performance optimization voor database-driven apps

### Point-Free Benefits

🌟 **Waarom deze aanpak revolutionair is:**
- **Zero Runtime SQL Errors**: Alle queries gevalideerd tijdens compilation
- **Automatic UI Updates**: Database changes triggeren instant UI updates
- **Type-Safe Composition**: Queries kunnen veilig gecombineerd worden
- **Performance**: Optimale database observations zonder boilerplate
- **Maintainable**: Schema changes worden gevangen door compiler
- **Testable**: Makkelijk testbare query logic

### Next Steps

Ready for **Chapter 4: SQL Triggers & Validatie**? Je gaat business logic naar de database verplaatsen voor ultimate data consistency!

---

**🤔 Vragen over reactive patterns?** Test je queries grondig en experimenteer met advanced compositions!