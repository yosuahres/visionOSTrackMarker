//
//  Fragment.swift
//  VisionOSTracking
//
//  Created by HARES on 5/19/26.
//

import Foundation
import simd
import ARKit
import RealityKit

struct FragmentSlice: Identifiable {
    let id = UUID()
    var distanceFromLeftAnchor: Float
    var xRotationDegrees: Float
    var yRotationDegrees: Float
    var zRotationDegrees: Float
}

struct Fragment: Identifiable {
    var id = UUID()
    var startSlice: FragmentSlice
    var endSlice: FragmentSlice
    var length: Float
}

struct FragmentGroup: Identifiable {
    var id = UUID()
    var name: String
    var description: String
    var usdzModelName: String
    var orientation: String
    var fragments: [Fragment]
}

struct LoadedFragmentGroup: Identifiable {
    let id = UUID()
    let group: FragmentGroup
    let referenceObject: ReferenceObject
    let usdzEntity: Entity?
}
