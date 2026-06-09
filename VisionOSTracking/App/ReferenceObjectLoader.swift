//
//  ReferenceObjectLoader.swift
//  VisionOSTracking
//
//  Created by HARES on 5/22/26.
//

import Foundation
import ARKit
import RealityKit

struct ReferenceObjectLoader {

    /// Loads the USDZ model embedded inside a .referenceobject file
    /// using ReferenceObject.usdzFile — returns a URL directly.
    static func loadEntity(fromReferenceObject name: String) async throws -> Entity {
        guard let refObjURL = Bundle.main.url(
            forResource: name,
            withExtension: "referenceobject"
        ) else {
            throw LoadError.fileNotFound(name)
        }

        // Load the ReferenceObject
        let referenceObject = try await ReferenceObject(from: refObjURL)

        // usdzFile is a URL? pointing to the embedded USDZ
        guard let usdzURL = referenceObject.usdzFile else {
            throw LoadError.usdzNotEmbedded(name)
        }

        // Load entity directly from the URL
        let entity = try await Entity(contentsOf: usdzURL)
        return entity
    }

    enum LoadError: Error, LocalizedError {
        case fileNotFound(String)
        case usdzNotEmbedded(String)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let name):
                return "Could not find \(name).referenceobject in bundle."
            case .usdzNotEmbedded(let name):
                return "No USDZ model embedded in \(name).referenceobject."
            }
        }
    }
}
