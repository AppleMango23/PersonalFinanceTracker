//
//  Category+CoreDataProperties.swift
//  personalfinancetracker
//
//  Created by Noah Yek on 27/07/2025.
//
//

import Foundation
import CoreData


extension TransactionCategory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransactionCategory> {
        return NSFetchRequest<TransactionCategory>(entityName: "TransactionCategory")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var budgetLimit: NSDecimalNumber?
    @NSManaged public var transactions: Transaction?

}

extension TransactionCategory : Identifiable {

}
