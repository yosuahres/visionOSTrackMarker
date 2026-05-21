//
//  FragmentGroupLoader.swift
//  VisionOSTracking
//
//  Created by HARES on 5/19/26.
//

import Foundation
import ARKit
import RealityKit

@MainActor
@Observable
final class FragmentGroupLoader {
    private(set) var loadedFragmentGroups = [LoadedFragmentGroup]()
    private var didStartLoading = false

    func loadFragmentGroups(_ fragmentGroups: [FragmentGroup]) async {
        guard !didStartLoading else { return }
        didStartLoading = true

        await withTaskGroup(of: LoadedFragmentGroup?.self) { group in
            for fragmentGroup in fragmentGroups {
                group.addTask {
                    // Load .referenceobject
                    guard let url = Bundle.main.url(
                        forResource: fragmentGroup.usdzModelName,
                        withExtension: "referenceobject"
                    ) else {
                        print("Reference object not found for \(fragmentGroup.usdzModelName)")
                        return nil
                    }

                    do {
                        let referenceObject = try await ReferenceObject(from: url)

                        var usdzEntity: Entity? = nil
                        if let usdzURL = referenceObject.usdzFile {
                            do {
                                usdzEntity = try await Entity(contentsOf: usdzURL)
                            } catch {
                                print("Failed to load USDZ model \(fragmentGroup.usdzModelName)")
                            }
                        }

                        return LoadedFragmentGroup(
                            group: fragmentGroup,
                            referenceObject: referenceObject,
                            usdzEntity: usdzEntity
                        )
                    } catch {
                        print("Failed to load reference object for \(fragmentGroup.usdzModelName): \(error)")
                        return nil
                    }
                }
            }

            // Collect results
            for await result in group {
                if let loadedGroup = result {
                    loadedFragmentGroups.append(loadedGroup)
                }
            }
        }

        // Sort by name
        loadedFragmentGroups.sort { $0.group.name < $1.group.name }
    }
}
