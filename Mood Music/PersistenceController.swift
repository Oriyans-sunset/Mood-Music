//
//  PersistenceController.swift
//  Mood Music
//
//  Created by Codex on 2025-XX-XX.
//

import CoreData
import Foundation

/// Lightweight Core Data stack built programmatically so we don't need an .xcdatamodeld file.
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = PersistenceController.makeModel()
        container = NSPersistentContainer(name: "SongHistoryModel", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    /// In‑memory container helper for tests.
    static func makeInMemoryContainer() -> NSPersistentContainer {
        PersistenceController(inMemory: true).container
    }

    /// Programmatically define the Core Data model with a single `SongHistory` entity.
    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = "title"
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = false

        let artistAttribute = NSAttributeDescription()
        artistAttribute.name = "artist"
        artistAttribute.attributeType = .stringAttributeType
        artistAttribute.isOptional = false

        let dateAttribute = NSAttributeDescription()
        dateAttribute.name = "date"
        dateAttribute.attributeType = .dateAttributeType
        dateAttribute.isOptional = false

        let emojiAttribute = NSAttributeDescription()
        emojiAttribute.name = "emoji"
        emojiAttribute.attributeType = .stringAttributeType
        emojiAttribute.isOptional = false

        let entity = NSEntityDescription()
        entity.name = "SongHistory"
        entity.managedObjectClassName = NSStringFromClass(SongHistory.self)
        entity.properties = [titleAttribute, artistAttribute, dateAttribute, emojiAttribute]

        model.entities = [entity]
        return model
    }
}
