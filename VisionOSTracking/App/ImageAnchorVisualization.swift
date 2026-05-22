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
    @Published var isGizmoVisible: Bool = false

    private var lockedTransform: Transform?
    let entity: Entity

    private(set) var gizmoEntity: Entity = Entity()
    private(set) var gizmoAxisX: Entity = Entity()
    private(set) var gizmoAxisY: Entity = Entity()
    private(set) var gizmoAxisZ: Entity = Entity()

    init(overlayEntity: Entity) {
        self.entity = overlayEntity
        let bounds = overlayEntity.visualBounds(relativeTo: overlayEntity)
        let center = bounds.center

        let gizmo = Entity()
        gizmo.position = center
        gizmo.isEnabled = false

        let hX = Self.makeHandle(color: .systemRed,   axis: [1, 0, 0])
        let hY = Self.makeHandle(color: .systemGreen, axis: [0, 1, 0])
        let hZ = Self.makeHandle(color: .systemBlue,  axis: [0, 0, 1])

        gizmo.addChild(hX)
        gizmo.addChild(hY)
        gizmo.addChild(hZ)
        overlayEntity.addChild(gizmo)

        self.gizmoEntity = gizmo
        self.gizmoAxisX = hX
        self.gizmoAxisY = hY
        self.gizmoAxisZ = hZ
    }

    private static func makeHandle(color: UIColor, axis: SIMD3<Float>) -> Entity {
        let shaftLength: Float = 0.06
        let shaftRadius: Float = 0.004
        let coneHeight:  Float = 0.018
        let coneRadius:  Float = 0.010

        let defaultDir = SIMD3<Float>(0, 1, 0)
        let target = normalize(axis)

        let q: simd_quatf
        let cross = simd_cross(defaultDir, target)
        if simd_length(cross) < 1e-5 {
            q = simd_quatf(angle: simd_dot(defaultDir, target) < 0 ? .pi : 0,
                           axis: [1, 0, 0])
        } else {
            q = simd_quatf(from: defaultDir, to: target)
        }

        var shaftMat = UnlitMaterial(color: color.withAlphaComponent(0.85))
        let shaft = ModelEntity(
            mesh: MeshResource.generateCylinder(height: shaftLength, radius: shaftRadius),
            materials: [shaftMat])
        shaft.position = axis * (shaftLength * 0.5)
        shaft.orientation = q

        var coneMat = UnlitMaterial(color: color)
        let cone = ModelEntity(
            mesh: MeshResource.generateCone(height: coneHeight, radius: coneRadius),
            materials: [coneMat])
        cone.position = axis * (shaftLength + coneHeight * 0.5)
        cone.orientation = q

        let handle = Entity()
        handle.addChild(shaft)
        handle.addChild(cone)
        handle.components.set(CollisionComponent(shapes: [
            ShapeResource.generateCapsule(height: shaftLength + coneHeight,
                                          radius: coneRadius)
                .offsetBy(rotation: q,
                          translation: axis * ((shaftLength + coneHeight) * 0.5))
        ]))
        handle.components.set(InputTargetComponent(allowedInputTypes: .all))
        return handle
    }

    func lockPosition() {
        isPositionLocked = true
        lockedTransform = entity.transform
    }

    func unlockPosition() {
        isPositionLocked = false
        lockedTransform = nil
        isGizmoVisible = false
        gizmoEntity.isEnabled = false
    }

    func togglePositionLock() {
        isPositionLocked ? unlockPosition() : lockPosition()
    }

    func toggleGizmo() {
        guard isPositionLocked else { return }
        isGizmoVisible.toggle()
        gizmoEntity.isEnabled = isGizmoVisible
    }

    func translateAlongAxis(_ worldAxis: SIMD3<Float>, delta: Float) {
        guard isPositionLocked else { return }
        let sensitivity: Float = 0.04
        let nudge = normalize(worldAxis) * delta * sensitivity
        entity.position += nudge
        lockedTransform = entity.transform
    }

    func update(with anchor: ImageAnchor) {
        guard anchor.isTracked else {
            entity.isEnabled = false
            return
        }
        entity.isEnabled = true

        if isPositionLocked, let locked = lockedTransform {
            entity.transform = locked
            return
        }

        let transform = Transform(matrix: anchor.originFromAnchorTransform)
        entity.transform.translation = transform.translation
        entity.transform.rotation = transform.rotation
    }
}
