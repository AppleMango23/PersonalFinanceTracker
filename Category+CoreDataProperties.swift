//
//  Category+CoreDataProperties.swift
//  personalfinancetracker
//
//  Created by Noah Yek on 27/07/2025.
//
//

import Foundation
import CoreData


extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var budgetLimit: NSDecimalNumber?
    @NSManaged public var transactions: Set<Transaction>?
    
    public var transactionsArray: [Transaction] {
        let set = transactions ?? []
        return set.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
    }
}

extension Category : Identifiable {

}

extension Transaction: Identifiable {
}
