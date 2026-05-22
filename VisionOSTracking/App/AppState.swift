//
//  AppState.swift
//  VisionOSTracking
//
//  Created by HARES on 5/19/26.
//

import ARKit

@MainActor
@Observable
class AppState {
    var isImmersiveSpaceOpened = false
    var selectedFragmentGroup: FragmentGroup?

    let fragmentGroups: [FragmentGroup] = [sampleFragmentGroup]

    var worldSensingAuthorizationStatus = ARKitSession.AuthorizationStatus.notDetermined

    private let arkitSession = ARKitSession()

    var allRequiredAuthorizationsAreGranted: Bool {
        worldSensingAuthorizationStatus == .allowed
    }

    var allRequiredProvidersAreSupported: Bool {
        ImageTrackingProvider.isSupported
    }

    var canEnterImmersiveSpace: Bool {
        allRequiredAuthorizationsAreGranted && allRequiredProvidersAreSupported
    }

    func requestWorldSensingAuthorization() async {
        let result = await arkitSession.requestAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = result[.worldSensing]!
    }

    func didLeaveImmersiveSpace() {
        isImmersiveSpaceOpened = false
    }
}
