import Foundation

public struct ShoppingItem: Identifiable, Codable, Sendable {
  public let id: UUID
  public var name: String
  public var quantity: Int
  public var isCompleted: Bool
  public var notes: String
  public var createdAt: Date
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
