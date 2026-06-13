//
//  ImageTrackingView.swift
//  VisionOSTracking
//
//  Created by HARES on 5/14/26.
//

import ARKit
import Spatial
import SwiftUI
import RealityKit

struct ImageTrackingView: View {
    var appState: AppState

    @State private var imageTrackingProvider: ImageTrackingProvider? = nil
    @State private var visualization: ImageAnchorVisualization? = nil
    @State private var dragStart: SIMD3<Float>? = nil
    @State private var rotateStartAngle: Double? = nil

    private let session = ARKitSession()

    private func isMoveHandle(_ entity: Entity) -> Bool {
        guard let vis = visualization else { return false }
        var e: Entity? = entity
        while let cur = e {
            if cur === vis.moveHandle { return true }
            e = cur.parent
        }
        return false
    }

    private var freeMoveGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .targetedToAnyEntity()
            .onChanged { value in
                guard isMoveHandle(value.entity) else { return }
                let worldDelta = value.convert(value.translation3D, from: .local, to: .scene)
                let delta = SIMD3<Float>(Float(worldDelta.x), Float(worldDelta.y), Float(worldDelta.z))
                let start = dragStart ?? .zero
                if dragStart == nil { dragStart = delta }
                visualization?.moveBy(worldDelta: delta - start)
                dragStart = delta
            }
            .onEnded { _ in
                dragStart = nil
            }
    }

    private var rotateGesture: some Gesture {
        RotateGesture3D(constrainedToAxis: .x)
            .targetedToAnyEntity()
            .onChanged { value in
                guard isMoveHandle(value.entity) else { return }
                // Extract cumulative X-axis angle from the quaternion.
                // For X-constrained rotation q ≈ (sin(θ/2), 0, 0, cos(θ/2)) in (x,y,z,w).
                let q = value.rotation.quaternion
                let cumulativeAngle = 2.0 * atan2(q.vector.x, q.vector.w)
                let prev = rotateStartAngle ?? cumulativeAngle
                if rotateStartAngle == nil { rotateStartAngle = cumulativeAngle }
                visualization?.rotateAroundX(delta: Float(cumulativeAngle - prev))
                rotateStartAngle = cumulativeAngle
            }
            .onEnded { _ in
                rotateStartAngle = nil
            }
    }

    var body: some View {
        RealityView { content, attachments in
            let fragmentGroup = appState.selectedFragmentGroup ?? sampleFragmentGroup

            let model: Entity
            do {
                model = try await ReferenceObjectLoader.loadEntity(fromReferenceObject: "fibula")
            } catch {
                print("Failed to load fibula from referenceobject: \(error.localizedDescription)")
                return
            }

            let overlay = Entity.buildFragmentOverlay(model: model, fragmentGroup: fragmentGroup)
            overlay.isEnabled = false

            let vis = await MainActor.run {
                ImageAnchorVisualization(overlayEntity: overlay)
            }
            visualization = vis
            content.add(overlay)

            if let controlAttachment = attachments.entity(for: "LockControl") {
                let bounds = overlay.visualBounds(relativeTo: overlay)
                controlAttachment.position = [
                    0,
                    bounds.center.y + bounds.extents.y * 0.5 + 0.1,
                    0
                ]
                controlAttachment.components.set(BillboardComponent())
                controlAttachment.scale = [0.5, 0.5, 0.5]
                overlay.addChild(controlAttachment)
            }
        } attachments: {
            Attachment(id: "LockControl") {
                if let vis = visualization {
                    LockControlView(visualization: vis)
                }
            }
        }
        .gesture(freeMoveGesture.simultaneously(with: rotateGesture))
        .task {
            await loadImage()
            await runSession()
            await processImageTrackingUpdates()
        }
        .onAppear {
            appState.isImmersiveSpaceOpened = true
        }
        .onDisappear {
            session.stop()
            appState.didLeaveImmersiveSpace()
        }
    }

    func loadImage() async {
        let uiImage = UIImage(named: "marker_set")
        let cgImage = uiImage?.cgImage
        let referenceImage = ReferenceImage(
            cgimage: cgImage!,
            physicalSize: CGSize(width: 0.07, height: 0.07))
        imageTrackingProvider = ImageTrackingProvider(
            referenceImages: [referenceImage])
    }

    func runSession() async {
        do {
            if ImageTrackingProvider.isSupported {
                try await session.run([imageTrackingProvider!])
                print("image tracking initializing in progress.")
            } else {
                print("image tracking is not supported.")
            }
        } catch {
            print("Error during initialization of image tracking. [\(type(of: self))] [\(#function)] \(error)")
        }
    }

    func processImageTrackingUpdates() async {
        for await update in imageTrackingProvider!.anchorUpdates {
            await MainActor.run {
                visualization?.update(with: update.anchor)
            }
        }
    }
}

struct LockControlView: View {
    @ObservedObject var visualization: ImageAnchorVisualization

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: visualization.isPositionLocked ? "lock.fill" : "lock.open")
                    .foregroundColor(visualization.isPositionLocked ? .green : .blue)
                    .font(.title2)

                Text(visualization.isPositionLocked ? "Locked" : "Tracking")
                    .font(.headline)
                    .foregroundColor(visualization.isPositionLocked ? .green : .blue)
            }

            Button(action: { visualization.togglePositionLock() }) {
                Text(visualization.isPositionLocked ? "Unlock Position" : "Lock Position")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(visualization.isPositionLocked ? Color.green : Color.blue)
                            .opacity(0.8)
                    )
                    .foregroundColor(.white)
            }

            if visualization.isPositionLocked {
                Button(action: { visualization.toggleFreeMove() }) {
                    HStack(spacing: 6) {
                        Image(systemName: visualization.isFreeMoveEnabled ? "hand.draw.fill" : "hand.draw")
                        Text(visualization.isFreeMoveEnabled ? "Free Move: On" : "Free Move")
                    }
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(visualization.isFreeMoveEnabled ? Color.purple : Color.gray)
                            .opacity(0.8)
                    )
                    .foregroundColor(.white)
                }
            }
        }
        .padding()
        .glassBackgroundEffect()
    }
}
