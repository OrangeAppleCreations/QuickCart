# QuickCart Schema & Database Setup

## Overview

This implementation follows the exact patterns from Point-Free Episode 323 "Modern Persistence", adapted for a QuickCart shopping list app. We'll create a SQL-first persistence architecture using StructuredQueries and SharingGRDB.

## Core Philosophy

> *"SQLite is the true arbiter of the data in our application"* - Point-Free

- **Database-First Design**: Schema defines app structure
- **Type-Safe Queries**: Compile-time validation via StructuredQueries
- **Value Type Models**: Pure Swift structs instead of reference types
- **Reactive UI Updates**: Real-time SwiftUI updates via SharingGRDB

## Implementation Steps

### 1. Schema Design (Schema.swift)

Create `Library/Sources/Models/Schema.swift` with 4 core data types:

#### ShoppingList
```swift
import Foundation
import SharingGRDB

@Table
struct ShoppingList: Identifiable {
  let id: Int
  var color = 0x4a99ef_ff  // Hex color for list theming
  var title = ""
}
```

#### ShoppingItem
```swift
import Foundation
import SharingGRDB

@Table
struct ShoppingItem: Identifiable {
  let id: Int
  var name = ""
  var notes = ""
  var quantity = ""  // "2kg", "3 pieces", etc.
  var isCompleted = false
  var priority: Priority?
  var shoppingListID: ShoppingList.ID
  @Column(as: Date.ISO8601Representation?.self)
  var dueDate: Date?
  
  enum Priority: Int, QueryBindable {
    case low = 1
    case medium = 2
    case high = 3
  }
}
```

#### Category (for organizing items)
```swift
import SharingGRDB

@Table
struct Category: Identifiable {
  let id: Int
  var title = ""
}
```

#### ShoppingItemCategory (many-to-many join table)
```swift
import SharingGRDB

@Table
struct ShoppingItemCategory {
  let shoppingItemID: ShoppingItem.ID
  let categoryID: Category.ID
}
```

### 2. Database Connection (DatabaseManager.swift)

Create `Library/Sources/Models/DatabaseManager.swift`:

#### Core Function
```swift
import Foundation
import OSLog
import Dependencies
import SharingGRDB

func appDatabase() throws -> any DatabaseWriter {
  @Dependency(\.context) var context
  
  var configuration = Configuration()
  configuration.foreignKeysEnabled = true
  
  configuration.prepareDatabase { db in
    #if DEBUG
      db.trace(options: .profile) {
        logger.debug("\($0.expandedDescription)")
      }
    #endif
  }
  
  let database: any DatabaseWriter
  
  switch context {
  case .live:
    let path = URL.documentsDirectory
      .appending(component: "quickcart.sqlite")
      .path()
    logger.info("open \(path)")
    database = try DatabasePool(path: path, configuration: configuration)
    
  case .preview, .test:
    database = try DatabaseQueue(configuration: configuration)
  }
  
  // Migration setup
  var migrator = DatabaseMigrator()
  
  #if DEBUG
    migrator.eraseDatabaseOnSchemaChange = true
  #endif
  
  migrator.registerMigration("Create tables") { db in
    // ShoppingLists table
    try #sql(
      """
      CREATE TABLE "shoppingLists" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "color" INTEGER NOT NULL DEFAULT \(raw: 0x4a99ef_ff),
        "title" TEXT NOT NULL DEFAULT ''
      ) STRICT
      """
    )
    .execute(db)
    
    // Categories table
    try #sql(
      """
      CREATE TABLE "categories" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "title" TEXT NOT NULL DEFAULT ''
      ) STRICT
      """
    )
    .execute(db)
    
    // ShoppingItems table
    try #sql(
      """
      CREATE TABLE "shoppingItems" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "name" TEXT NOT NULL DEFAULT '',
        "notes" TEXT NOT NULL DEFAULT '',
        "quantity" TEXT NOT NULL DEFAULT '',
        "isCompleted" INTEGER NOT NULL DEFAULT 0,
        "priority" INTEGER,
        "dueDate" TEXT,
        "shoppingListID" INTEGER NOT NULL
          REFERENCES "shoppingLists"("id")
          ON DELETE CASCADE
      ) STRICT
      """
    )
    .execute(db)
    
    // Many-to-many join table
    try #sql(
      """
      CREATE TABLE "shoppingItemCategories" (
        "shoppingItemID" INTEGER NOT NULL
          REFERENCES "shoppingItems"("id")
          ON DELETE CASCADE,
        "categoryID" INTEGER NOT NULL
          REFERENCES "categories"("id")
          ON DELETE CASCADE
      ) STRICT
      """
    )
    .execute(db)
  }
  
  try migrator.migrate(database)
  return database
}

private let logger = Logger(
  subsystem: "QuickCart",
  category: "Database"
)
```

### 3. Package Dependencies

Update `Library/Package.swift` to include required dependencies:

```swift
dependencies: [
  .package(url: "https://github.com/pointfreeco/sharing-grdb.git", from: "1.0.0"),
  .package(url: "https://github.com/pointfreeco/swift-structured-queries.git", from: "0.10.0"),
  .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.0.0"),
],
targets: [
  .target(
    name: "Models",
    dependencies: [
      .product(name: "SharingGRDB", package: "sharing-grdb"),
      .product(name: "Dependencies", package: "swift-dependencies"),
    ]
  )
]
```

### 4. App Integration

Initialize database in `QuickCart/QuickCartApp.swift`:

```swift
@main
struct QuickCartApp: App {
  init() {
    let _ = try! appDatabase()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
```

## Key Features

### Type Safety
- ✅ All SQL queries validated at compile-time
- ✅ No runtime SQL errors possible
- ✅ Refactoring-safe column and table references

### Relationships
- **1-to-many**: ShoppingList → ShoppingItems
- **Many-to-many**: ShoppingItems ↔ Categories
- **CASCADE deletes**: Maintains data integrity

### Development Features
- 🔧 Schema change detection in DEBUG builds
- 📊 Database query tracing with OSLog
- 🧪 In-memory databases for tests and previews
- 💾 Persistent SQLite file in Documents directory

## Next Steps

This foundation enables:
1. Type-safe query building with StructuredQueries
2. Reactive SwiftUI views that auto-update with database changes
3. Repository pattern for business logic
4. Comprehensive testing with in-memory databases

Follow Point-Free Episode 324+ for building the UI layer and query implementations.