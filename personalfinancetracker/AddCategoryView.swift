import SwiftUI

struct AddCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    
    @State private var categoryName: String = ""
    @State private var budgetLimit: String = ""
    
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
                        
                        // Save Button
                        Button(action: { saveCategory() }) {
                            Text("Save Category")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(categoryName.isEmpty)
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveCategory() {
        let newCategory = Category(context: viewContext)
        newCategory.name = categoryName
        newCategory.id = UUID()
        
        if let budgetValue = Double(budgetLimit) {
            newCategory.budgetLimit = NSDecimalNumber(value: budgetValue)
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving category: \(error)")
        }
    }
}

#Preview {
    AddCategoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

