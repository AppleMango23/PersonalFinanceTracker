import SwiftUI
import Charts
import CoreData

struct ExpenseDataPoint: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
}

struct ContentView: View {
    var body: some View {
        ZStack {
            // Global background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
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
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .tint(.primary)
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
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary Card
                        HStack(spacing: 20) {
                            // Income Card
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Income")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("$\(totalIncome, specifier: "%.2f")")
                                    .font(.title2).bold()
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .green.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            // Expense Card
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Expense")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("$\(totalExpense, specifier: "%.2f")")
                                    .font(.title2).bold()
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .red.opacity(0.1), radius: 10, x: 0, y: 5)
                        }
                        
                        // Expense Chart Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Monthly Expenses")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Chart(expenseData) { point in
                                BarMark(
                                    x: .value("Month", point.month),
                                    y: .value("Amount", point.amount)
                                )
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [.red.opacity(0.7), .orange.opacity(0.7)],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                            }
                            .frame(height: 200)
                            .chartYAxis {
                                AxisMarks { value in
                                    let amount = value.as(Double.self) ?? 0
                                    AxisValueLabel {
                                        Text("\(Int(amount))")
                                            .foregroundColor(.secondary)
                                    }
                                    AxisTick()
                                    AxisGridLine()
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        // Add Transaction Button
                        Button(action: {
                            isAddTransactionPresented = true
                        }) {
                            Label("Add Transaction", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .sheet(isPresented: $isAddTransactionPresented) {
                            AddTransactionView()
                        }
                    }
                    .padding()
                }
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
        .navigationViewStyle(.stack)
    }
}

// MARK: - Transaction Detail View

struct TransactionDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let transaction: Transaction
    
    @State private var amount: String = ""
    @State private var currency: String = ""
    @State private var selectedCategory: Category?
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Amount Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            TextField("Enter amount", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.primary)
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

                        // Delete Button
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Text("Delete Transaction")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateTransaction()
                    }
                }
            }
            .alert("Delete Transaction", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteTransaction()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this transaction?")
            }
        }
        .onAppear {
            // Initialize state with current transaction values
            if let currentAmount = transaction.amount as? Double {
                amount = String(format: "%.2f", abs(currentAmount))
            }
            currency = transaction.currency ?? "MYR"
            selectedCategory = transaction.category
            note = transaction.note ?? ""
            date = transaction.date ?? Date()
        }
    }
    
    private func fetchCategories() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        return (try? viewContext.fetch(request)) ?? []
    }
    
    private func updateTransaction() {
        if let amountValue = Double(amount) {
            // Keep the sign (positive/negative) of the original amount
            let originalAmount = transaction.amount as? Double ?? 0
            let newAmount = originalAmount < 0 ? -abs(amountValue) : abs(amountValue)
            transaction.amount = NSDecimalNumber(value: newAmount)
        }
        
        transaction.currency = currency
        transaction.category = selectedCategory
        transaction.note = note
        transaction.date = date
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to update transaction: \(error)")
        }
    }
    
    private func deleteTransaction() {
        viewContext.delete(transaction)
        try? viewContext.save()
        dismiss()
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
    @State private var selectedTransaction: Transaction?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(transactions) { transaction in
                            TransactionRow(
                                name: transaction.category?.name ?? "—",
                                note: transaction.note,
                                amount: transaction.amount as? Double ?? 0,
                                date: transaction.date ?? Date()
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTransaction = transaction
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewContext.delete(transaction)
                                        try? viewContext.save()
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                                .tint(.red)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddTransactionPresented = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $isAddTransactionPresented) {
                AddTransactionView()
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailView(transaction: transaction)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct TransactionRow: View {
    let name: String
    let note: String?
    let amount: Double
    let date: Date
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(name.prefix(1))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary.opacity(0.8))
                )
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                if let note = note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("$\(amount, specifier: "%.2f")")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(amount >= 0 ? .green : .red)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
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
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(categories) { category in
                            CategoryCard(category: category, totalSpent: calculateTotalSpent(for: category))
                        }
                        .onDelete(perform: deleteCategories)
                    }
                    .padding()
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddCategoryPresented = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $isAddCategoryPresented) {
                AddCategoryView()
            }
        }
        .navigationViewStyle(.stack)
    }

    private func deleteCategories(offsets: IndexSet) {
        withAnimation {
            offsets.map { categories[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

struct CategoryCard: View {
    let category: Category
    let totalSpent: Double
    
    var transactionCount: Int {
        (category.transactions as? Set<Transaction>)?.count ?? 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Category Icon
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(category.name?.prefix(1) ?? "?")
                            .font(.headline)
                            .foregroundColor(.primary.opacity(0.8))
                    )
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name ?? "Unnamed")
                        .font(.headline)
                    Text("\(transactionCount) transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Divider()
                .background(.ultraThinMaterial)
            
            HStack {
                if let budgetLimit = category.budgetLimit as? Double, budgetLimit > 0 {
                    VStack(alignment: .leading) {
                        Text("Budget")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(budgetLimit, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                
                VStack(alignment: .trailing) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(abs(totalSpent), specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(totalSpent < 0 ? .red : .green)
                }
            }
            
            if let budgetLimit = category.budgetLimit as? Double, budgetLimit > 0 {
                let progress = min(abs(totalSpent) / budgetLimit, 1.0)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.ultraThinMaterial)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progress >= 1.0 ? Color.red : Color.blue)
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @AppStorage("monthStartDate") private var monthStartDate: Int = 1
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Month Settings")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
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
                            NotificationCenter.default.post(name: NSNotification.Name("MonthStartDateChanged"), object: nil)
                        }
                        
                        Text("Your monthly period will be from day \(monthStartDate) to day \(monthStartDate) of the next month")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .padding()
            }
            .navigationTitle("Settings")
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
