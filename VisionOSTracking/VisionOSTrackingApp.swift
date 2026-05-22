//
//  VisionOSTrackingApp.swift
//  VisionOSTracking
//
//  Created by HARES on 5/14/26.
//

import SwiftUI

@main
struct VisionOSImageTrackingSampleApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            HomeView(appState: appState, immersiveSpaceIdentifier: "ImmersiveSpace")
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImageTrackingView(appState: appState)
        }
    }
}
