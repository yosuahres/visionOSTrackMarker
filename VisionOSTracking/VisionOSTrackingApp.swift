//
//  VisionOSTrackingApp.swift
//  VisionOSTracking
//
//  Created by HARES on 5/14/26.
//

import SwiftUI

@main
struct VisionOSImageTrackingSampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImageTrackingView()
        }
    }
}
