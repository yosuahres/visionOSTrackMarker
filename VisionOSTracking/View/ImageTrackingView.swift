//
//  ImageTrackingView.swift
//  VisionOSTracking
//
//  Created by HARES on 5/14/26.
//

import ARKit
import SwiftUI
import RealityKit

struct ImageTrackingView: View {
    var appState: AppState

    @State private var imageTrackingProvider: ImageTrackingProvider?
    @State private var visualization: ImageAnchorVisualization?
    @State private var gizmoDragStart: SIMD3<Float>? = nil

    private let session = ARKitSession()

    private var gizmoGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .targetedToAnyEntity()
            .onChanged { value in
                guard let vis = visualization else { return }

                let axis: SIMD3<Float>
                if      value.entity === vis.gizmoAxisX { axis = [1, 0, 0] }
                else if value.entity === vis.gizmoAxisY { axis = [0, 1, 0] }
                else if value.entity === vis.gizmoAxisZ { axis = [0, 0, 1] }
                else { return }

                let worldDelta = value.convert(value.translation3D,
                                               from: .local, to: .scene)
                let delta = SIMD3<Float>(Float(worldDelta.x),
                                         Float(worldDelta.y),
                                         Float(worldDelta.z))
                let projected = simd_dot(delta, normalize(axis))
                let start = gizmoDragStart ?? SIMD3<Float>.zero
                if gizmoDragStart == nil { gizmoDragStart = delta }
                let frameDelta = projected - simd_dot(start, normalize(axis))
                vis.translateAlongAxis(axis, delta: frameDelta)
                gizmoDragStart = delta
            }
            .onEnded { _ in
                gizmoDragStart = nil
            }
    }

    var body: some View {
        RealityView { content, attachments in
            let fragmentGroup = appState.selectedFragmentGroup ?? sampleFragmentGroup
            let model = try! await Entity(named: "Resources/\(fragmentGroup.usdzModelName)")
            let overlay = Entity.buildFragmentOverlay(model: model,
                                                      fragmentGroup: fragmentGroup)
            overlay.isEnabled = false

            let vis = ImageAnchorVisualization(overlayEntity: overlay)
            await MainActor.run { self.visualization = vis }

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
        .gesture(gizmoGesture)
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
            physicalSize: CGSize(width: 1920, height: 1005))
        imageTrackingProvider = ImageTrackingProvider(referenceImages: [referenceImage])
    }

    func runSession() async {
        do {
            if ImageTrackingProvider.isSupported {
                try await session.run([imageTrackingProvider!])
                print("Image tracking initializing.")
            } else {
                print("Image tracking not supported.")
            }
        } catch {
            print("Error during initialization of image tracking. [\(type(of: self))] [\(#function)] \(error)")
        }
    }

    func processImageTrackingUpdates() async {
        for await update in imageTrackingProvider!.anchorUpdates {
            visualization?.update(with: update.anchor)
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
                Button(action: { visualization.toggleGizmo() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "move.3d")
                            .symbolVariant(visualization.isGizmoVisible ? .fill : .none)
                        Text(visualization.isGizmoVisible ? "Hide Gizmo" : "Show Gizmo")
                    }
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(visualization.isGizmoVisible ? Color.orange : Color.gray)
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
