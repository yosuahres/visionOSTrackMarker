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
    @State private var contentEntity: Entity?
    @State private var isPositionLocked = false
    private let session = ARKitSession()

    var body: some View {
        RealityView { content, attachments in
            let fragmentGroup = appState.selectedFragmentGroup ?? sampleFragmentGroup
            let model = try! await Entity(named: "Resources/\(fragmentGroup.usdzModelName)")
            let overlay = Entity.buildFragmentOverlay(model: model, fragmentGroup: fragmentGroup)
            overlay.isEnabled = false
            contentEntity = overlay
            content.add(overlay)

            if let controlAttachment = attachments.entity(for: "LockControl") {
                let bounds = overlay.visualBounds(relativeTo: overlay)
                controlAttachment.position = [0, bounds.center.y + bounds.extents.y * 0.5 + 0.1, 0]
                controlAttachment.components.set(BillboardComponent())
                controlAttachment.scale = [0.5, 0.5, 0.5]
                overlay.addChild(controlAttachment)
            }
        } attachments: {
            Attachment(id: "LockControl") {
                LockControlView(isLocked: isPositionLocked, onToggle: togglePositionLock)
            }
        }
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
        let referenceImage = ReferenceImage(cgimage: cgImage!, physicalSize: CGSize(width: 1920, height: 1005))
        imageTrackingProvider = ImageTrackingProvider(
            referenceImages: [referenceImage]
        )
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
            updateImage(update.anchor)
        }
    }

    private func togglePositionLock() {
        if isPositionLocked {
            isPositionLocked = false
        } else if let contentEntity, contentEntity.isEnabled {
            isPositionLocked = true
        }
    }

    private func updateImage(_ anchor: ImageAnchor) {
        guard let contentEntity else { return }
        if isPositionLocked {
            contentEntity.isEnabled = true
            return
        }
        if anchor.isTracked {
            contentEntity.isEnabled = true
            let transform = Transform(matrix: anchor.originFromAnchorTransform)
            contentEntity.transform.translation = transform.translation
            contentEntity.transform.rotation = transform.rotation
        } else {
            contentEntity.isEnabled = false
        }
    }
}

struct LockControlView: View {
    let isLocked: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .foregroundColor(isLocked ? .green : .blue)
                    .font(.title2)

                Text(isLocked ? "Locked" : "Tracking")
                    .font(.headline)
                    .foregroundColor(isLocked ? .green : .blue)
            }

            Button(action: onToggle) {
                Text(isLocked ? "Unlock Position" : "Lock Position")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isLocked ? Color.green : Color.blue)
                            .opacity(0.8)
                    )
                    .foregroundColor(.white)
            }
        }
        .padding()
        .glassBackgroundEffect()
    }
}
