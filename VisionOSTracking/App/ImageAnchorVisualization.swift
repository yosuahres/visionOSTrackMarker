//
//  ImageAnchorVisualization.swift
//  VisionOSTracking
//
//  Created by HARES on 5/22/26.
//

import ARKit
import RealityKit
import SwiftUI
import Combine

@MainActor
class ImageAnchorVisualization: ObservableObject {
    @Published var isPositionLocked: Bool = false
    @Published var isFreeMoveEnabled: Bool = false

    private var lockedTransform: Transform?

    let entity: Entity
    private(set) var moveHandle: Entity = Entity()

    init(overlayEntity: Entity) {
        self.entity = overlayEntity

        let bounds = overlayEntity.visualBounds(relativeTo: overlayEntity)
        let extents = SIMD3<Float>(
            max(bounds.extents.x, 0.05),
            max(bounds.extents.y, 0.05),
            max(bounds.extents.z, 0.05)
        )

        let handle = Entity()
        handle.position = bounds.center
        handle.components.set(CollisionComponent(shapes: [.generateBox(size: extents)]))
        handle.components.set(InputTargetComponent(allowedInputTypes: .all))
        handle.isEnabled = false
        overlayEntity.addChild(handle)
        self.moveHandle = handle
    }

    func lockPosition() {
        isPositionLocked = true
        lockedTransform = entity.transform
    }

    func unlockPosition() {
        isPositionLocked = false
        lockedTransform = nil
        isFreeMoveEnabled = false
        moveHandle.isEnabled = false
    }

    func togglePositionLock() {
        isPositionLocked ? unlockPosition() : lockPosition()
    }

    func toggleFreeMove() {
        guard isPositionLocked else { return }
        isFreeMoveEnabled.toggle()
        moveHandle.isEnabled = isFreeMoveEnabled
    }

    func moveBy(worldDelta: SIMD3<Float>) {
        guard isPositionLocked else { return }
        entity.position += worldDelta
        lockedTransform = entity.transform
    }

    func rotateAroundX(delta: Float) {
        guard isPositionLocked else { return }
        let rotation = simd_quatf(angle: delta, axis: [1, 0, 0])
        entity.transform.rotation = rotation * entity.transform.rotation
        lockedTransform = entity.transform
    }

    func update(with anchor: ImageAnchor) {
        if isPositionLocked, let locked = lockedTransform {
            entity.isEnabled = true
            entity.transform = locked
            return
        }

        if anchor.isTracked {
            entity.isEnabled = true
            let transform = Transform(matrix: anchor.originFromAnchorTransform)
            let markerOffset = SIMD3<Float>(0.09, 0.055, -0.032)
            var target = transform
            target.translation = transform.translation + markerOffset
            entity.move(to: target, relativeTo: nil, duration: 0.1, timingFunction: .linear)
        } else {
            entity.isEnabled = false
        }
    }
}
