import SwiftUI
import CoreData

struct AddTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var amount: String = ""
    @State private var currency: String = "MYR"
    @State private var selectedCategory: Category?
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var photo: UIImage? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Amount")) {
                    TextField("Enter amount", text: $amount)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Currency")) {
                    TextField("Enter currency", text: $currency)
                }

                Section(header: Text("Category")) {
                    Picker("Select Category", selection: $selectedCategory) {
                        ForEach(fetchCategories(), id: \ .self) { category in
                            Text(category.name ?? "Unnamed").tag(category as Category?)
                        }
                    }
                }

                Section(header: Text("Note")) {
                    TextField("Enter note", text: $note)
                }

                Section(header: Text("Date")) {
                    DatePicker("Select Date", selection: $date, displayedComponents: .date)
                }

                Section(header: Text("Photo")) {
                    if let photo = photo {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    Button("Add Photo") {
                        // TODO: Implement photo picker
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTransaction()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func fetchCategories() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        return (try? viewContext.fetch(request)) ?? []
    }

    private func saveTransaction() {
        let newTransaction = Transaction(context: viewContext)
        newTransaction.id = UUID()
        newTransaction.amount = NSDecimalNumber(value: Double(amount) ?? 0)
        newTransaction.currency = currency
        newTransaction.category = selectedCategory
        newTransaction.note = note
        newTransaction.date = date
        // TODO: Save photo if needed

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to save transaction: \(error)")
        }
    }
}

struct AddTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        AddTransactionView()
    }
}