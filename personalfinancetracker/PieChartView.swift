import SwiftUI
import Charts

struct PieChartView: View {
    let transactions: [Transaction]

    var body: some View {
        VStack {
            Chart(groupedExpenses, id: \.categoryName) {
                SectorMark(
                    angle: .value("Amount", $0.amount),
                    innerRadius: 60,
                    outerRadius: 100
                )
                .foregroundStyle(by: .value("Category", $0.categoryName))
            }
            .frame(height: 300)
            .chartBackground { proxy in
                GeometryReader { geo in
                    if let anchor = proxy.plotFrame {
                        let frame = geo[anchor]
                        VStack {
                            Text("Total")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Text(totalExpenses, format: .currency(code: "MYR"))
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private var groupedExpenses: [CategoryExpense] {
        let expenses = transactions.filter { ($0.amount?.doubleValue ?? 0.0) < 0 }

        let grouped = Dictionary(grouping: expenses) { $0.category?.name ?? "Uncategorized" }

        return grouped.map { (categoryName, transactions) in
            let total = transactions.reduce(0) { $0 + abs($1.amount?.doubleValue ?? 0.0) }
            return CategoryExpense(categoryName: categoryName, amount: total)
        }
        .sorted { $0.amount > $1.amount }
    }

    private var totalExpenses: Double {
        groupedExpenses.reduce(0) { $0 + $1.amount }
    }
}

struct CategoryExpense: Identifiable {
    let id = UUID()
    let categoryName: String
    let amount: Double
}
