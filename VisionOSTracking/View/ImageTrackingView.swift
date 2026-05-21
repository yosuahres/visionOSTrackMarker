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
    
    @State private var imageTrackingProvider:ImageTrackingProvider?
    @State private var entityMap: [UUID: Entity] = [:]
    @State private var contentEntity: Entity?
    private let session = ARKitSession()
    
    var body: some View {
        RealityView { content in
            contentEntity = try! await Entity(named: "Resources/blue-1")
            content.add(contentEntity!)
        }.task {
            await loadImage()
            await runSession()
            await processImageTrackingUpdates()
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
    
    private func updateImage(_ anchor: ImageAnchor) {
        if entityMap[anchor.id] == nil {
            entityMap[anchor.id] = contentEntity
        }
        if anchor.isTracked {
            contentEntity!.isEnabled = true
            let transform = Transform(matrix: anchor.originFromAnchorTransform)
            entityMap[anchor.id]?.transform.translation = transform.translation
            entityMap[anchor.id]?.transform.rotation = transform.rotation
        } else {
            contentEntity!.isEnabled = false
        }
    }
}

//#Preview {
//    ImageTrackingView()
//}
