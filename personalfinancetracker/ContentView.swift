import SwiftUI
import Charts

struct ExpenseDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

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
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<Transaction>
    
    private var totalIncome: Double {
        transactions
            .compactMap { $0.amount as? Double }
            .filter { $0 > 0 }
            .reduce(0, +)
    }
    
    private var totalExpense: Double {
        transactions
            .compactMap { $0.amount as? Double }
            .filter { $0 < 0 }
            .map(abs)
            .reduce(0, +)
    }
    
    @State private var isAddTransactionPresented: Bool = false
    
    private var expenseData: [ExpenseDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the start and end of the current month
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return []
        }
        
        var dailyTotals: [Date: Double] = [:]
        
        // Initialize all days of the month with zero
        var currentDate = monthStart
        while currentDate <= monthEnd {
            dailyTotals[currentDate] = 0
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // Calculate daily totals
        for transaction in transactions {
            guard let date = transaction.date,
                  let amount = transaction.amount as? Double,
                  amount < 0, // Only expenses (negative amounts)
                  date >= monthStart,
                  date <= monthEnd else { continue }
            
            // Get start of the day for this transaction
            let dayStart = calendar.startOfDay(for: date)
            dailyTotals[dayStart, default: 0] += abs(amount)
        }
        
        return dailyTotals.sorted(by: { $0.key < $1.key }).map { date, amount in
            ExpenseDataPoint(date: date, amount: amount)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
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
                    
                    // Expense Chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Expenses")
                            .font(.headline)
                        
                        Chart(expenseData) { point in
                            LineMark(
                                x: .value("Day", point.date, unit: .day),
                                y: .value("Amount", point.amount)
                            )
                            .foregroundStyle(.red)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisGridLine()
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                let amount = value.as(Double.self) ?? 0
                                AxisValueLabel {
                                    Text(amount.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                                }
                                AxisTick()
                                AxisGridLine()
                            }
                        }
                        .chartPlotStyle { plotArea in
                            plotArea
                                .background(Color.gray.opacity(0.1))
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
            }
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
