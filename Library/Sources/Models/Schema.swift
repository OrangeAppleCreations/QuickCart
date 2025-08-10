import Foundation
import OSLog
import Dependencies
import SharingGRDB

// MARK: - Data Types

@Table
public struct ShoppingList: Identifiable {
  public let id: Int
  // Hex color for list theming
  public var color = 0x4a99ef_ff
  public var title = ""
  
  public init(
    id: Int = 0,
    color: Int = 0x4a99ef_ff,
    title: String = ""
  ) {
    self.id = id
    self.color = color
    self.title = title
  }
}

@Table
public struct ShoppingItem: Identifiable {
  public let id: Int
  public var name = ""
  public var notes = ""
  // "2kg", "3 pieces", etc.
  public var quantity = ""
  public var isCompleted = false
  public var priority: Priority?
  public var shopingListID: ShoppingList.ID
  public var dueDate: Date?
  
  public init(
    id: Int = 0,
    name: String = "",
    notes: String = "",
    quantity: String = "",
    isCompleted: Bool = false,
    priority: Priority? = nil,
    shopingListID: ShoppingList.ID,
    dueDate: Date? = nil
  ) {
    self.id = id
    self.name = name
    self.notes = notes
    self.quantity = quantity
    self.isCompleted = isCompleted
    self.priority = priority
    self.shopingListID = shopingListID
    self.dueDate = dueDate
  }
  
  public enum Priority: Int, QueryBindable {
    case low = 1
    case medium = 2
    case high = 3
  }
}

@Table
public struct Category: Identifiable {
  public let id: Int
  public var title = ""
  
  public init(
    id: Int = 0,
    title: String = ""
  ) {
    self.id = id
    self.title = title
  }
}

@Table
public struct ShoppingItemCategory {
  public let shoppingItemID: ShoppingItem.ID
  public let categoryID: Category.ID
  
  public init(
    shoppingItemID: ShoppingItem.ID,
    categoryID: Category.ID
  ) {
    self.shoppingItemID = shoppingItemID
    self.categoryID = categoryID
  }
}

// MARK: - Database Setup

public func appDatabase() throws -> any DatabaseWriter {
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
      "shoppingListID" INTEGER NOT NULL REFERENCES "shoppingLists"("id") ON DELETE CASCADE
      ) STRICT
      """
    )
    .execute(db)
    
    // Many-to-many join table
    try #sql(
      """
      CREATE TABLE "shoppingItemCategories" (
      "shoppingItemID" INTEGER NOT NULL REFERENCES "shoppingItems"("id") ON DELETE CASCADE,
      "categoryID" INTEGER NOT NULL REFERENCES "categories"("id") ON DELETE CASCADE
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
