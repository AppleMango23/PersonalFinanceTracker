import SwiftUI
import CoreData

struct AddCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss

    // If non‑nil, we’re editing this Category; otherwise we’re adding
    var categoryToEdit: Category?

    // Form fields
    @State private var categoryName: String
    @State private var budgetLimit: String

    // Custom initializer to prefill when editing
    init(categoryToEdit: Category? = nil) {
        self.categoryToEdit = categoryToEdit
        _categoryName = State(initialValue: categoryToEdit?.name ?? "")
        if let limit = categoryToEdit?.budgetLimit?.stringValue {
            _budgetLimit = State(initialValue: limit)
        } else {
            _budgetLimit = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Category Name Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category Name")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            TextField("Enter category name", text: $categoryName)
                                .textFieldStyle(.plain)
                                .font(.title3)
                                .padding(.vertical, 8)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                        // Budget Limit Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Budget Limit")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            TextField("Enter budget limit (optional)", text: $budgetLimit)
                                .textFieldStyle(.plain)
                                .keyboardType(.decimalPad)
                                .font(.title3)
                                .padding(.vertical, 8)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                        // Save/Update Button
                        Button(action: saveCategory) {
                            Text(categoryToEdit == nil ? "Save Category" : "Update Category")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(categoryToEdit == nil ? Color.blue : Color.green)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(color: (categoryToEdit == nil ? Color.blue : Color.green).opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(categoryName.isEmpty)

                        // Delete Button (only when editing)
                        if categoryToEdit != nil {
                            Button(role: .destructive) {
                                deleteCategory()
                            } label: {
                                Text("Delete Category")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(categoryToEdit == nil ? "Add Category" : "Edit Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func saveCategory() {
        let cat = categoryToEdit ?? Category(context: viewContext)
        if cat.id == nil { cat.id = UUID() }
        cat.name = categoryName
        if let value = Double(budgetLimit) {
            cat.budgetLimit = NSDecimalNumber(value: value)
        } else {
            cat.budgetLimit = nil
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving category: \(error)")
        }
    }

    private func deleteCategory() {
        if let cat = categoryToEdit {
            viewContext.delete(cat)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting category: \(error)")
            }
        }
        dismiss()
    }
}
