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
    
    let fragmentGroupLoader = FragmentGroupLoader()
    
    var selectedFragmentGroup: LoadedFragmentGroup?
    
    func didLeaveImmersiveSpace() {
        // Stop the provider; the provider that just ran in the
        // immersive space is now in a paused state and isn't needed
        // anymore. When a person reenters the immersive space,
        // run a new provider.
        arkitSession.stop()
        isImmersiveSpaceOpened = false
    }
    
    private let arkitSession = ARKitSession()
    
    private var objectTracking: ObjectTrackingProvider? = nil
    
    var worldSensingAuthorizationStatus = ARKitSession.AuthorizationStatus.notDetermined
    
    var allRequiredAuthorizationsAreGranted: Bool {
        // support world sensing
        worldSensingAuthorizationStatus == .allowed
    }
    
    var allRequiredProvidersAreSupported: Bool {
        // support object tracking
        ObjectTrackingProvider.isSupported
    }
    
    var canEnterImmersiveSpace: Bool {
        allRequiredAuthorizationsAreGranted && allRequiredProvidersAreSupported
    }
    
    func requestWorldSensingAuthorization() async {
        let authorizationResult = await arkitSession.requestAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing]!
    }
    
    func queryWorldSensingAuthorization() async {
        let authorizationResult = await arkitSession.queryAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing]!
    }
    
    func startTracking() async -> ObjectTrackingProvider? {
        guard let selectedFragmentGroup else {
            fatalError("No selected fragment group to start tracking")
        }
        
        // Run a new provider every time when entering the immersive space.
        let objectTracking = ObjectTrackingProvider(referenceObjects: [selectedFragmentGroup.referenceObject])
        
        do {
            try await arkitSession.run([objectTracking])
        } catch {
            print("Error: \(error)" )
            return nil
        }
        
        self.objectTracking = objectTracking
        
        return objectTracking
    }
}
