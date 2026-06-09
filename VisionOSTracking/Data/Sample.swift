//
//  Sample.swift
//  VisionOSTracking
//
//  Created by HARES on 5/19/26.
//

import Foundation

let sampleFragmentGroup = FragmentGroup(
    name: "Test Case B",
    description: "Quad-point fragment setup from quaternion tracking data.",
    usdzModelName: "bone-white-1",
    orientation: "x",
    fragments: [
        Fragment(
            startSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.139387, // [0] pos.x = 13.9387cm
                xRotationDegrees: -160.911,
                yRotationDegrees: -83.0456,
                zRotationDegrees: 144.811
            ),
            endSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.087842, // [1] pos.x = 8.7842cm
                xRotationDegrees: -1.97443,
                yRotationDegrees: 55.9448,
                zRotationDegrees: 1.21357
            ),
            length: 0.051545 // 0.139387 - 0.087842
        ),
        Fragment(
            startSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.086907, // [2] pos.x = 8.6907cm
                xRotationDegrees: -18.093,
                yRotationDegrees: -58.4248,
                zRotationDegrees: 5.21148
            ),
            endSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.044515, // [3] pos.x = 4.4515cm
                xRotationDegrees: -27.5019,
                yRotationDegrees: 87.2228,
                zRotationDegrees: -24.0868
            ),
            length: 0.042392 // 0.086907 - 0.044515
        )
    ]
)
