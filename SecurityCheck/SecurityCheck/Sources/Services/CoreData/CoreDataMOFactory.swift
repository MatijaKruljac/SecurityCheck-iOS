//
//  CoreDataMOFactory.swift
//  SecurityCheck
//
//  Created by Matija Kruljac on 25.04.2023..
//

import CoreData

class CoreDataMOFactory {

    static func create<T: NSManagedObject>(type: T.Type) -> T {
        let entityDescription: NSEntityDescription = getEntityDescription(for: T.self)

        return T(entity: entityDescription, insertInto: CoreDataService.shared.backgroundContext)
    }

    static func getEntityDescription<T: NSManagedObject>(for type: T.Type) -> NSEntityDescription {
        let objectName: String = String(describing: T.self)
        guard let description = NSEntityDescription.entity(
            forEntityName: objectName,
            in: CoreDataService.shared.backgroundContext) else {
            fatalError("CoreData unknown managed object name \(objectName)")
        }

        return description
    }
}
