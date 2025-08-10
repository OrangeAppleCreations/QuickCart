# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

QuickCart is a SwiftUI-based iOS application using **Point-Free modern persistence architecture**. This project demonstrates SQL-first development with type-safe queries, reactive UI updates, and production-ready database patterns.

## Modern Persistence Architecture

**🌟 Based on Point-Free Episodes 323-333**: This project implements the revolutionary modern persistence approach with:

- **SQLite as Single Source of Truth**: Database is the arbiter of all data
- **Type-Safe SQL Queries**: Compile-time validation via StructuredQueries
- **Reactive UI Updates**: Real-time SwiftUI updates via SharingGRDB
- **Value Type Models**: Pure Swift structs instead of reference types
- **SQL Triggers**: Business logic implemented in the database
- **Cross-Platform Ready**: Works on iOS, macOS, and Linux

## Project Structure

```
QuickCart/
├── QuickCart/                    # Main executable (minimal)
│   ├── QuickCartApp.swift       # @main entry point only
│   └── Assets.xcassets/         # App assets
├── Library/                     # Modern modular architecture
│   ├── Sources/
│   │   ├── Models/              # SQL-first persistence layer
│   │   │   ├── Schema.sql       # Database schema definition
│   │   │   ├── DatabaseManager.swift        # GRDB connection management
│   │   │   ├── TableDefinitions.swift       # StructuredQueries table definitions
│   │   │   ├── QueryExtensions.swift        # Type-safe query builders
│   │   │   ├── ShoppingModels.swift         # Value type models
│   │   │   ├── DatabaseRecords.swift        # GRDB record mappings
│   │   │   ├── *Repository.swift            # Repository pattern implementations
│   │   │   └── SampleData.swift            # Test data factory
│   │   └── AppFeature/          # SwiftUI reactive components
│   │       ├── DatabaseObservation.swift   # @FetchAll property wrappers
│   │       ├── ReactiveViews.swift          # Database-driven SwiftUI views
│   │       └── Forms/                       # Add/Edit form components
│   └── Tests/                   # Comprehensive test coverage
└── guides/                      # Step-by-step learning curriculum
```

## Core Technologies

### Point-Free Modern Persistence Stack
```swift
// Package.swift dependencies
.package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.0"),
.package(url: "https://github.com/pointfreeco/swift-sharing.git", from: "1.0.0"),
.package(url: "https://github.com/pointfreeco/swift-structured-queries.git", from: "0.10.0"),
```

### Key Libraries
- **GRDB.swift**: Modern SQLite framework with excellent performance
- **StructuredQueries**: Type-safe SQL query builder (compile-time validation)
- **SharingGRDB**: Reactive database observations for SwiftUI
- **SwiftUI**: Declarative UI framework with reactive data binding

## Common Development Commands

### Building the Project
```bash
# Build the modular library
xcodebuild -scheme Library build

# Build full app for iOS Simulator
xcodebuild -scheme QuickCart -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build for Release
xcodebuild -scheme QuickCart -configuration Release build
```

### Testing the Persistence Layer
```bash
# Run all tests including database schema tests
xcodebuild test -scheme Library -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test classes
xcodebuild test -scheme Library -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:LibraryTests/DatabaseSchemaTests
xcodebuild test -scheme Library -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:LibraryTests/RepositoryTests
xcodebuild test -scheme Library -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:LibraryTests/StructuredQueriesTests
```

### Database Operations
```bash
# The app uses SQLite database stored at:
# ~/Documents/QuickCart.sqlite (production)
# In-memory (testing)

# You can inspect the database with:
sqlite3 ~/Documents/QuickCart.sqlite
.schema  # View table structure
.tables  # List all tables
SELECT * FROM shopping_lists;  # Query data
```

## Development Guide

This project includes a comprehensive **Point-Free modern persistence curriculum**:

### 📚 Learning Path
- **DEVELOPMENT_GUIDE.md** - Complete roadmap (11 chapters, 3-6 months)
- **guides/** directory - Detailed step-by-step instructions

### 🏗️ Foundation (Weeks 1-6)
1. **Chapter 1**: SQL Schema & Value Types
2. **Chapter 2**: GRDB Repository Pattern  
3. **Chapter 3**: Type-Safe Queries & UI Binding
4. **Chapter 4**: SQL Triggers & Validatie

### ⚡ Advanced Persistence (Weeks 7-12)
5. **Chapter 5**: Advanced Aggregations & Joins
6. **Chapter 6**: Real-time Updates & Change Tracking
7. **Chapter 7**: Database Triggers & Callbacks
8. **Chapter 8**: Migration & Schema Evolution

### 🚀 Production Features (Weeks 13+)
9. **Chapter 9**: CloudKit Synchronization
10. **Chapter 10**: Performance & Optimization
11. **Chapter 11**: Advanced SQL Patterns

## Code Patterns

### Type-Safe Database Queries
```swift
// ✅ Type-safe, compile-time validated
let query = QueryInterface<ShoppingItemsTable>
    .forList(listId)
    .where(shoppingItemsTable.name.like("%search%"))
    .orderBy(.asc(shoppingItemsTable.name))

// ❌ This won't compile - type safety in action!
// .where(shoppingItemsTable.nonExistentColumn == "value")
```

### Reactive SwiftUI Views
```swift
struct ReactiveListView: View {
    @FetchShoppingLists private var lists  // Auto-updates from database
    
    var body: some View {
        List(lists) { list in
            Text(list.title)
            // UI updates automatically when database changes
        }
    }
}
```

### Repository Pattern
```swift
// Business logic in repositories, not in SwiftUI
let repo = ShoppingListRepository()
let lists = try await repo.fetchAllOrderedByDateStructured()
```

## Point-Free Philosophy

> *"SQLite is the true arbiter of the data in our application"*

### Core Principles
- 🎯 **Database-First Design**: Schema defines app structure
- ⚡ **Type-Safe Queries**: Compiler catches SQL errors before runtime
- 🔄 **Reactive UI**: SwiftUI updates automatically with database changes
- 🏗️ **Value Types**: Pure structs for better testability
- 🛡️ **SQL Triggers**: Business logic in database for consistency

### Benefits
- **Zero Runtime SQL Errors**: All queries validated at compile-time
- **Automatic UI Updates**: Database changes trigger instant UI updates
- **Cross-Platform**: Same code works on iOS, macOS, Linux
- **Performance**: Optimal database operations with minimal overhead
- **Maintainable**: Schema changes caught by compiler
- **Testable**: Easy to test with in-memory databases

## Development Notes

- **Swift 6.0+ Required**: Uses modern concurrency (async/await, actors)
- **iOS 17+ Target**: Leverages latest SwiftUI and system features
- **Modular Architecture**: Clean separation between data and UI layers
- **Test-Driven**: Comprehensive test coverage for all database operations
- **Production Ready**: Handles migrations, error recovery, and edge cases

## Quick Start Commands

```bash
# 1. Clone and build
git clone <repo-url>
cd QuickCart
xcodebuild -scheme Library build

# 2. Run tests to verify setup
xcodebuild test -scheme Library -destination 'platform=iOS Simulator,name=iPhone 15'

# 3. Open in Xcode
open QuickCart.xcodeproj

# 4. Follow DEVELOPMENT_GUIDE.md for step-by-step learning
```

## Troubleshooting

### Common Issues
- **Build Errors**: Ensure Xcode 15+ and verify Package.swift dependencies
- **Test Failures**: Check database schema matches value type models
- **Query Compilation**: Verify StructuredQueries syntax and table definitions
- **UI Not Updating**: Ensure @FetchAll property wrappers are properly configured

### Debug Database
```bash
# View database schema
sqlite3 ~/Documents/QuickCart.sqlite ".schema"

# Check sample data
sqlite3 ~/Documents/QuickCart.sqlite "SELECT * FROM shopping_lists LIMIT 5;"
```