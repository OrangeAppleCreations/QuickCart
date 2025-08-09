# Chapter 2: Core UI Components

**⏱️ Estimated Time:** 1 Week  
**🎯 Learning Objective:** Build reusable SwiftUI components using your data models

---

## 📋 Prerequisites

Before starting this chapter:
- [ ] ✅ Chapter 1 completed - Data models are working
- [ ] ✅ All Chapter 1 tests passing
- [ ] ✅ Basic SwiftUI knowledge (Views, State, Binding)

---

## 🎯 Chapter Goals

By the end of this chapter, you will have:
- ✅ A beautiful `ItemRowView` component
- ✅ An `AddItemView` for creating new items
- ✅ A complete `ListDetailView` showing all items
- ✅ Navigation structure in your app
- ✅ Basic CRUD operations working in UI
- ✅ SwiftUI previews for all components

---

## 📚 Lesson 2.1: Setup UI Infrastructure

### Task 1: Update AppFeature with Navigation

**Location:** `Library/Sources/AppFeature/ContentView.swift`

Replace the current content with:

```swift
import SwiftUI
import Models

public struct ContentView: View {
    @State private var lists = SampleData.sampleLists
    @State private var selectedList: ShoppingList?
    @State private var showingAddList = false
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            // Master: List of shopping lists
            ListsOverviewView(
                lists: $lists,
                selectedList: $selectedList,
                showingAddList: $showingAddList
            )
        } detail: {
            // Detail: Selected list items
            if let selectedList {
                ListDetailView(
                    list: binding(for: selectedList),
                    lists: $lists
                )
            } else {
                PlaceholderView()
            }
        }
    }
    
    private func binding(for list: ShoppingList) -> Binding<ShoppingList> {
        guard let index = lists.firstIndex(where: { $0.id == list.id }) else {
            fatalError("List not found")
        }
        return $lists[index]
    }
}

#Preview {
    ContentView()
}
```

**✅ Completion Check:**
- [ ] ContentView compiles
- [ ] Navigation structure is set up
- [ ] Preview works

---

## 📚 Lesson 2.2: Lists Overview

### Task 2: Create ListsOverviewView

**Location:** `Library/Sources/AppFeature/ListsOverviewView.swift`

```swift
import SwiftUI
import Models

struct ListsOverviewView: View {
    @Binding var lists: [ShoppingList]
    @Binding var selectedList: ShoppingList?
    @Binding var showingAddList: Bool
    
    var body: some View {
        List(selection: $selectedList) {
            ForEach(lists) { list in
                NavigationLink(value: list) {
                    ListRowView(list: list)
                }
            }
            .onDelete(perform: deleteLists)
        }
        .navigationTitle("Shopping Lists")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddList = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddList) {
            AddListView { newList in
                lists.append(newList)
                selectedList = newList
            }
        }
    }
    
    private func deleteLists(offsets: IndexSet) {
        lists.remove(atOffsets: offsets)
    }
}

struct ListRowView: View {
    let list: ShoppingList
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(list.title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(list.completedItems.count)/\(list.items.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: list.completionPercentage)
                .tint(.green)
            
            Text("Updated \(list.updatedAt.formatted(.relative(presentation: .named)))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview("Lists Overview") {
    NavigationView {
        ListsOverviewView(
            lists: .constant(SampleData.sampleLists),
            selectedList: .constant(nil),
            showingAddList: .constant(false)
        )
    }
}

#Preview("List Row") {
    ListRowView(list: SampleData.sampleLists[0])
        .padding()
}
```

**✅ Completion Check:**
- [ ] Lists are displayed correctly
- [ ] Progress bars show completion
- [ ] Delete functionality works
- [ ] Previews render correctly

---

## 📚 Lesson 2.3: Add List Functionality

### Task 3: Create AddListView

**Location:** `Library/Sources/AppFeature/AddListView.swift`

```swift
import SwiftUI
import Models

struct AddListView: View {
    @Environment(\\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedTemplate: ListTemplate?
    
    let onSave: (ShoppingList) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("List Details") {
                    TextField("List name", text: $title)
                        .textInputAutocapitalization(.words)
                }
                
                Section("Templates") {
                    ForEach(ListTemplate.allCases) { template in
                        Button {
                            selectedTemplate = template
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(template.name)
                                        .foregroundColor(.primary)
                                    Text(template.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedTemplate == template {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveList()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveList() {
        let newList = ShoppingList(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            items: selectedTemplate?.items ?? []
        )
        onSave(newList)
        dismiss()
    }
}

// MARK: - List Templates
enum ListTemplate: CaseIterable, Identifiable {
    case empty
    case weekly
    case party
    case quick
    
    var id: Self { self }
    
    var name: String {
        switch self {
        case .empty: return "Empty List"
        case .weekly: return "Weekly Groceries"
        case .party: return "Party Supplies"
        case .quick: return "Quick Run"
        }
    }
    
    var description: String {
        switch self {
        case .empty: return "Start with a blank list"
        case .weekly: return "Common weekly grocery items"
        case .party: return "Everything you need for a party"
        case .quick: return "Quick essentials"
        }
    }
    
    var items: [ShoppingItem] {
        switch self {
        case .empty:
            return []
        case .weekly:
            return [
                ShoppingItem(name: "Milk", category: .dairy),
                ShoppingItem(name: "Bread", category: .pantry),
                ShoppingItem(name: "Eggs", quantity: 12, category: .dairy),
                ShoppingItem(name: "Bananas", category: .produce),
                ShoppingItem(name: "Chicken", category: .meat),
            ]
        case .party:
            return [
                ShoppingItem(name: "Chips", quantity: 3, category: .pantry),
                ShoppingItem(name: "Soda", quantity: 6, category: .other),
                ShoppingItem(name: "Ice", category: .frozen),
                ShoppingItem(name: "Napkins", category: .household),
            ]
        case .quick:
            return [
                ShoppingItem(name: "Milk", category: .dairy),
                ShoppingItem(name: "Bread", category: .pantry),
            ]
        }
    }
}

#Preview {
    AddListView { list in
        print("New list: \\(list.title)")
    }
}
```

**✅ Completion Check:**
- [ ] Can create new lists
- [ ] Templates work correctly
- [ ] Form validation prevents empty titles
- [ ] Preview functions

---

## 📚 Lesson 2.4: List Detail View

### Task 4: Create ListDetailView

**Location:** `Library/Sources/AppFeature/ListDetailView.swift`

```swift
import SwiftUI
import Models

struct ListDetailView: View {
    @Binding var list: ShoppingList
    @Binding var lists: [ShoppingList]
    @State private var showingAddItem = false
    @State private var searchText = ""
    
    private var filteredItems: [ShoppingItem] {
        if searchText.isEmpty {
            return list.items
        } else {
            return list.items.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var groupedItems: [ItemCategory: [ShoppingItem]] {
        Dictionary(grouping: filteredItems) { $0.category }
    }
    
    var body: some View {
        List {
            if list.items.isEmpty {
                EmptyStateView {
                    showingAddItem = true
                }
            } else {
                ForEach(ItemCategory.allCases, id: \\.self) { category in
                    if let items = groupedItems[category], !items.isEmpty {
                        Section(category.rawValue) {
                            ForEach(items) { item in
                                ItemRowView(
                                    item: binding(for: item),
                                    onDelete: { deleteItem(item) }
                                )
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(list.title)
        .searchable(text: $searchText, prompt: "Search items")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button("Clear Completed") {
                        clearCompleted()
                    }
                    .disabled(list.completedItems.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                
                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemView { newItem in
                list.addItem(newItem)
                updateListInArray()
            }
        }
    }
    
    private func binding(for item: ShoppingItem) -> Binding<ShoppingItem> {
        guard let index = list.items.firstIndex(where: { $0.id == item.id }) else {
            fatalError("Item not found")
        }
        return Binding(
            get: { list.items[index] },
            set: { 
                list.items[index] = $0
                updateListInArray()
            }
        )
    }
    
    private func deleteItem(_ item: ShoppingItem) {
        list.removeItem(withId: item.id)
        updateListInArray()
    }
    
    private func clearCompleted() {
        list.clearCompleted()
        updateListInArray()
    }
    
    private func updateListInArray() {
        if let index = lists.firstIndex(where: { $0.id == list.id }) {
            lists[index] = list
        }
    }
}

struct EmptyStateView: View {
    let onAddItem: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Your list is empty")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Add some items to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Button("Add Item") {
                onAddItem()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview("List Detail") {
    NavigationView {
        ListDetailView(
            list: .constant(SampleData.sampleLists[0]),
            lists: .constant(SampleData.sampleLists)
        )
    }
}

#Preview("Empty State") {
    NavigationView {
        List {
            EmptyStateView {
                print("Add item tapped")
            }
        }
        .navigationTitle("Empty List")
    }
}
```

**✅ Completion Check:**
- [ ] Items display grouped by category
- [ ] Search functionality works
- [ ] Empty state shows when no items
- [ ] Menu actions work

---

## 📚 Lesson 2.5: Item Row Component

### Task 5: Create ItemRowView

**Location:** `Library/Sources/AppFeature/ItemRowView.swift`

```swift
import SwiftUI
import Models

struct ItemRowView: View {
    @Binding var item: ShoppingItem
    let onDelete: () -> Void
    
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion checkbox
            Button {
                item.toggle()
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // Item content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.displayName)
                        .strikethrough(item.isCompleted)
                        .foregroundColor(item.isCompleted ? .secondary : .primary)
                    
                    Spacer()
                    
                    Text(item.category.emoji)
                }
                
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
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
        .swipeActions(edge: .leading) {
            Button("Edit") {
                showingEditSheet = true
            }
            .tint(.blue)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditItemView(item: $item)
        }
    }
}

#Preview("Item Row - Pending") {
    List {
        ItemRowView(
            item: .constant(SampleData.sampleItems[0]),
            onDelete: { print("Delete tapped") }
        )
    }
}

#Preview("Item Row - Completed") {
    List {
        ItemRowView(
            item: .constant({
                var item = SampleData.sampleItems[1]
                item.toggle()
                return item
            }()),
            onDelete: { print("Delete tapped") }
        )
    }
}
```

**✅ Completion Check:**
- [ ] Checkbox toggles completion state
- [ ] Swipe actions work (delete & edit)
- [ ] Shows item notes when available
- [ ] Visual feedback for completed items

---

## 📚 Lesson 2.6: Add/Edit Item Views

### Task 6: Create AddItemView

**Location:** `Library/Sources/AppFeature/AddItemView.swift`

```swift
import SwiftUI
import Models

struct AddItemView: View {
    @Environment(\\.dismiss) private var dismiss
    @State private var name = ""
    @State private var quantity = 1
    @State private var category = ItemCategory.other
    @State private var notes = ""
    
    let onSave: (ShoppingItem) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Item name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Stepper("Quantity: \\(quantity)", value: $quantity, in: 1...99)
                    
                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases, id: \\.self) { category in
                            HStack {
                                Text(category.emoji)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveItem()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveItem() {
        let newItem = ShoppingItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: quantity,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category
        )
        onSave(newItem)
        dismiss()
    }
}

struct EditItemView: View {
    @Binding var item: ShoppingItem
    @Environment(\\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var quantity: Int
    @State private var category: ItemCategory
    @State private var notes: String
    
    init(item: Binding<ShoppingItem>) {
        self._item = item
        self._name = State(initialValue: item.wrappedValue.name)
        self._quantity = State(initialValue: item.wrappedValue.quantity)
        self._category = State(initialValue: item.wrappedValue.category)
        self._notes = State(initialValue: item.wrappedValue.notes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Item name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Stepper("Quantity: \\(quantity)", value: $quantity, in: 1...99)
                    
                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases, id: \\.self) { category in
                            HStack {
                                Text(category.emoji)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        item.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        item.quantity = quantity
        item.category = category
        item.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        item.updatedAt = Date()
        dismiss()
    }
}

#Preview("Add Item") {
    AddItemView { item in
        print("New item: \\(item.name)")
    }
}

#Preview("Edit Item") {
    EditItemView(item: .constant(SampleData.sampleItems[0]))
}
```

**✅ Completion Check:**
- [ ] Can add new items with all fields
- [ ] Can edit existing items
- [ ] Form validation works
- [ ] Quantity stepper functions correctly

---

## 📚 Lesson 2.7: Placeholder View

### Task 7: Create PlaceholderView

**Location:** `Library/Sources/AppFeature/PlaceholderView.swift`

```swift
import SwiftUI

struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Select a List")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Choose a shopping list from the sidebar to view its items")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    PlaceholderView()
}
```

---

## 🧪 Testing Your UI

### Task 8: Test All Components

Run your app and test:

1. **Navigation**: 
   - [ ] Can select lists from sidebar
   - [ ] Detail view updates when selecting different lists

2. **List Management**:
   - [ ] Can create new lists
   - [ ] Templates work
   - [ ] Can delete lists

3. **Item Management**:
   - [ ] Can add items to lists
   - [ ] Can edit existing items
   - [ ] Can toggle completion
   - [ ] Can delete items
   - [ ] Search works

4. **Visual Polish**:
   - [ ] Categories group items correctly
   - [ ] Progress bars show completion
   - [ ] Swipe actions work
   - [ ] Empty states display properly

### Create UI Tests

**Location:** `Library/Tests/LibraryTests/UIComponentTests.swift`

```swift
import XCTest
import SwiftUI
@testable import AppFeature
@testable import Models

final class UIComponentTests: XCTestCase {
    func testItemRowToggle() {
        var item = ShoppingItem(name: "Test Item")
        
        XCTAssertFalse(item.isCompleted)
        item.toggle()
        XCTAssertTrue(item.isCompleted)
    }
    
    func testListCompletion() {
        var list = ShoppingList(title: "Test")
        list.addItem(ShoppingItem(name: "Item 1"))
        list.addItem(ShoppingItem(name: "Item 2"))
        
        XCTAssertEqual(list.completionPercentage, 0.0)
        
        list.items[0].toggle()
        XCTAssertEqual(list.completionPercentage, 0.5)
        
        list.items[1].toggle()
        XCTAssertEqual(list.completionPercentage, 1.0)
    }
}
```

---

## 🎉 Chapter 2 Complete!

### Final Checklist

Before moving to Chapter 3, ensure:

- [ ] ✅ All UI components compile and run
- [ ] ✅ Navigation works between master/detail
- [ ] ✅ Can perform full CRUD operations on lists and items
- [ ] ✅ Search and filtering works
- [ ] ✅ Categories display correctly with emojis
- [ ] ✅ Empty states provide good UX
- [ ] ✅ All SwiftUI previews work
- [ ] ✅ No runtime crashes or warnings

### What You've Built

🎊 **Amazing progress!** You now have:

- **Complete UI**: All core screens and components
- **Full Functionality**: CRUD operations for lists and items  
- **Great UX**: Search, categories, empty states, swipe actions
- **Modern SwiftUI**: Navigation, sheets, forms, proper state management

### Next Steps

Ready for **Chapter 3: Local Storage**? You'll add persistent data storage with SwiftData!

---

**🤔 Questions?** Test everything thoroughly and ask Claude Code if you run into issues!