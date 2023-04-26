//
//  CoreDataService.swift
//  SecurityCheck
//
//  Created by Matija Kruljac on 25.04.2023..
//

import Foundation
import CoreData

final class CoreDataService {

    static let shared: CoreDataService = CoreDataService()

    static let dataModelName: String = "DatabaseModel"

    private let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: dataModelName)
        let fileManager = FileManager.default

        if let storeUrl = container.persistentStoreDescriptions.first?.url,
           fileManager.fileExists(atPath: storeUrl.path) {

            // Set file-level protection key if file already exists
            let attributes = [FileAttributeKey.protectionKey: FileProtectionType.complete]
            try? fileManager.setAttributes(attributes, ofItemAtPath: storeUrl.path)
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("CoreData unresolved error \(error), \(error.userInfo)")
            }
        }
        
        return container
    }()

    let mainContext: NSManagedObjectContext
    let backgroundContext: NSManagedObjectContext

    private init() {
        mainContext = persistentContainer.viewContext
        backgroundContext = persistentContainer.newBackgroundContext()
    }
}

// MARK: - CRUD operations
extension CoreDataService {

    func create(_ createBlock: @escaping () -> Void, completionBlock: (() -> Void)? = nil) {
        backgroundContext.perform { [weak self] in
            createBlock()

            // Save the changes to the background context
            self?.saveBackgroundContext()

            // Refresh the main context to reflect the changes
            self?.mainContext.perform {
                self?.mainContext.refreshAllObjects()
                completionBlock?()
            }
        }
    }

    func read<T: NSManagedObject>(type: T.Type, _ completionBlock: @escaping (_ result: [T]) -> Void) {
        // Fetch result on background thread
        backgroundContext.perform { [weak self] in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: T.self))
            let result = try? self?.backgroundContext.fetch(fetchRequest) as? [T]

            // Return result on main thread
            self?.mainContext.perform {
                completionBlock(result ?? [])
            }
        }
    }

    func delete<T: NSManagedObject>(type: T.Type, _ completionBlock: (() -> Void)? = nil) {
        backgroundContext.perform { [weak self] in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: T.self))
            guard let result = try? self?.backgroundContext.fetch(fetchRequest) as? [T] else {
                completionBlock?()
                return
            }

            result.forEach { managedObject in
                // Delete managed object on background context
                self?.backgroundContext.delete(managedObject)
            }

            // Save the changes to the background context
            self?.saveBackgroundContext()

            // Refresh the main context to reflect the changes
            self?.mainContext.perform {
                self?.mainContext.refreshAllObjects()
                completionBlock?()
            }
        }
    }
}

// MARK: - Context operations
private extension CoreDataService {

    // Save changes to the main context
    func saveMainContext() {
        if mainContext.hasChanges {
            do {
                try mainContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("CoreData unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // Save changes to the background context
    func saveBackgroundContext() {
        backgroundContext.perform { [weak self] in
            if self?.backgroundContext.hasChanges ?? false {
                do {
                    try self?.backgroundContext.save()
                } catch {
                    let nserror = error as NSError
                    fatalError("CoreData unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
    }
}
