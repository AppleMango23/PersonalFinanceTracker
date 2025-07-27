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
    @State private var isExpense: Bool = true

    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Transaction Type Toggle
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Transaction Type")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Picker("Transaction Type", selection: $isExpense) {
                                Text("Expense").tag(true)
                                Text("Income").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .tint(isExpense ? .red : .green)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                        // Amount Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            TextField("Enter amount", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(isExpense ? .red : .green)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                        // Currency Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Currency")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            TextField("Enter currency", text: $currency)
                                .font(.title3)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                        // Category Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Menu {
                                ForEach(fetchCategories(), id: \.self) { category in
                                    Button {
                                        selectedCategory = category
                                    } label: {
                                        Text(category.name ?? "Unnamed")
                                            .foregroundColor(.primary)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedCategory?.name ?? "Select Category")
                                        .foregroundColor(selectedCategory == nil ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                        // Note Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            TextField("Enter note", text: $note)
                                .font(.title3)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                        // Date Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            DatePicker("Select Date", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .tint(.blue)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                        // Photo Section
                        if let photo = photo {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        }

                        Button("Add Photo") {
                            // TODO: Implement photo picker
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        // Save Button
                        Button(action: { saveTransaction() }) {
                            Text("Save Transaction")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Transaction")
            .toolbar {
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
        
        if let amountValue = Double(amount) {
            // Make the amount negative for expenses, positive for income
            newTransaction.amount = NSDecimalNumber(value: isExpense ? -abs(amountValue) : abs(amountValue))
        }
        
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