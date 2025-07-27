import SwiftUI
import Charts

struct ExpenseDataPoint: Identifiable {
    let id = UUID()
    let month: String
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
            
            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.circle")
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
    @AppStorage("monthStartDate") private var monthStartDate: Int = 1
    @State private var refreshID = UUID() // Add this for forcing view refresh
    
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
    
    private func getCustomMonthRange(for date: Date) -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        
        // Get the components of the given date
        guard let year = calendar.dateComponents([.year, .month], from: date).year,
              let month = calendar.dateComponents([.year, .month], from: date).month else {
            return nil
        }
        
        // Create date components for the custom month start
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = month
        startComponents.day = monthStartDate
        
        // Get the start date
        guard let startDate = calendar.date(from: startComponents) else { return nil }
        
        // Get the end date (same day next month)
        guard let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else { return nil }
        
        return (startDate, endDate)
    }
    
    private var expenseData: [ExpenseDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the current custom month range
        guard let currentRange = getCustomMonthRange(for: now),
              let previousMonth = calendar.date(byAdding: .month, value: -1, to: now),
              let previousRange = getCustomMonthRange(for: previousMonth),
              let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now),
              let twoMonthsAgoRange = getCustomMonthRange(for: twoMonthsAgo) else {
            return []
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        var customMonthlyTotals: [(range: (Date, Date), total: Double)] = [
            (twoMonthsAgoRange, 0),
            (previousRange, 0),
            (currentRange, 0)
        ]
        
        // Calculate monthly totals
        for transaction in transactions {
            guard let date = transaction.date,
                  let amount = transaction.amount as? Double,
                  amount < 0 else { continue }
            
            for (index, monthRange) in customMonthlyTotals.enumerated() {
                if date >= monthRange.range.0 && date < monthRange.range.1 {
                    customMonthlyTotals[index].total += abs(amount)
                }
            }
        }
        
        return customMonthlyTotals.map { range, total in
            let label = "\(dateFormatter.string(from: range.0))"
            return ExpenseDataPoint(month: label, amount: total)
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
                        Text("Monthly Expenses")
                            .font(.headline)
                        
                        Chart(expenseData) { point in
                            BarMark(
                                x: .value("Month", point.month),
                                y: .value("Amount", point.amount)
                            )
                            .foregroundStyle(.red)
                        }
                        .frame(height: 200)
                        .chartYAxis {
                            AxisMarks { value in
                                let amount = value.as(Double.self) ?? 0
                                AxisValueLabel {
                                    Text("\(Int(amount))")
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
            .id(refreshID) // Add this to force view refresh
            .onAppear {
                // Set up notification observer
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("MonthStartDateChanged"),
                    object: nil,
                    queue: .main
                ) { _ in
                    // Force view refresh when month start date changes
                    refreshID = UUID()
                }
            }
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
    
    private func calculateTotalSpent(for category: Category) -> Double {
        let transactions = category.transactions as? Set<Transaction> ?? []
        var total: Double = 0.0
        
        for transaction in transactions {
            if let amount = transaction.amount as? Double {
                total += amount
            }
        }
        
        return total
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(categories) { category in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(category.name ?? "Unnamed")
                                .font(.headline)
                            Spacer()
                            let transactionCount = (category.transactions as? Set<Transaction>)?.count ?? 0
                            Text("\(transactionCount) transactions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let budgetLimit = category.budgetLimit as? Double, budgetLimit > 0 {
                            Text("Budget: $\(budgetLimit, specifier: "%.2f")")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        let totalSpent = calculateTotalSpent(for: category)
                        Text("Total spent: $\(abs(totalSpent), specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(totalSpent < 0 ? .red : .green)
                    }
                    .padding(.vertical, 4)
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

// MARK: - Account View

struct AccountView: View {
    @AppStorage("monthStartDate") private var monthStartDate: Int = 1
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Month Settings")) {
                    Stepper("Start Date: \(monthStartDate)") {
                        if monthStartDate < 28 {
                            monthStartDate += 1
                        }
                    } onDecrement: {
                        if monthStartDate > 1 {
                            monthStartDate -= 1
                        }
                    }
                    .onChange(of: monthStartDate) { _, _ in
                        // This will trigger a refresh of the dashboard when the date changes
                        NotificationCenter.default.post(name: NSNotification.Name("MonthStartDateChanged"), object: nil)
                    }
                    
                    Text("Your monthly period will be from day \(monthStartDate) to day \(monthStartDate) of the next month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Account")
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
