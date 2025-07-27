import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
            
            CategoriesView()
                .tabItem {
                    Label("Categories", systemImage: "tag.fill")
                }
        }
    }
}

// MARK: - Dashboard

struct DashboardView: View {
    // sample data
    @State private var totalIncome: Double = 4500
    @State private var totalExpense: Double = 3200
    @State private var isAddTransactionPresented: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Income")
                            .font(.caption)
                        Text("$\(totalIncome, specifier: "%.2f")")
                            .font(.title2).bold()
                            .foregroundColor(.green)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Expense")
                            .font(.caption)
                        Text("$\(totalExpense, specifier: "%.2f")")
                            .font(.title2).bold()
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                Spacer()
                
                Button(action: {
                    isAddTransactionPresented = true
                }) {
                    Label("Add Transaction", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(10)
                }
                .sheet(isPresented: $isAddTransactionPresented) {
                    AddTransactionView()
                }
            }
            .padding()
            .navigationTitle("Dashboard")
        }
    }
}

// MARK: - Transactions

struct TransactionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<Transaction>
    @State private var isAddTransactionPresented = false

    var body: some View {
        NavigationView {
            List {
                ForEach(transactions) { tx in
                    TransactionRow(
                        name: tx.category?.name ?? "—",
                        note: tx.note,
                        amount: tx.amount as? Double ?? 0,
                        date: tx.date ?? Date()
                    )
                }
                .onDelete(perform: deleteTransactions)
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddTransactionPresented = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddTransactionPresented) {
                AddTransactionView()
            }
        }
    }

    private func deleteTransactions(offsets: IndexSet) {
        withAnimation {
            offsets.map { transactions[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

struct TransactionRow: View {
    let name: String
    let note: String?
    let amount: Double
    let date: Date
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                if let note = note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("$\(amount, specifier: "%.2f")")
                .foregroundColor(amount >= 0 ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Categories

struct CategoriesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category>
    @State private var isAddCategoryPresented = false

    var body: some View {
        NavigationView {
            List {
                ForEach(categories) { cat in
                    Text(cat.name ?? "Unnamed")
                }
                .onDelete(perform: deleteCategories)
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddCategoryPresented = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddCategoryPresented) {
                AddCategoryView()
            }
        }
    }

    private func deleteCategories(offsets: IndexSet) {
        withAnimation {
            offsets.map { categories[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
