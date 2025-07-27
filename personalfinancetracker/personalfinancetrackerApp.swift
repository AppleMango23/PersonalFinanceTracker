import CoreData
import SwiftUICore
import SwiftUI

struct PersistenceController {
    static let shared = PersistenceController()

    // Use an in-memory store for previews or testing if needed
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Create sample data for previews
        let sampleCategory = Category(context: viewContext)
        sampleCategory.id = UUID()
        sampleCategory.name = "Sample"
        sampleCategory.budgetLimit = 0

        let sampleTransaction = Transaction(context: viewContext)
        sampleTransaction.id = UUID()
        sampleTransaction.amount = 12.34
        sampleTransaction.date = Date()
        sampleTransaction.note = "Preview"
        sampleTransaction.category = sampleCategory

        try? viewContext.save()
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FinanceTrackerModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unresolved Core Data error: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

@main
struct CroissantTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
