import SwiftUI

struct AddCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    
    @State private var categoryName: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Category Name", text: $categoryName)
                }
            }
            .navigationTitle("Add Category")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveCategory()
                }
                .disabled(categoryName.isEmpty)
            )
        }
    }
    
    private func saveCategory() {
        let newCategory = Category(context: viewContext)
        newCategory.name = categoryName
        newCategory.id = UUID()
        
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

