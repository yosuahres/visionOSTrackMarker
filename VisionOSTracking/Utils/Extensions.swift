//
//  Extensions.swift
//  VisionOSTracking
//
//  Created by HARES on 5/19/26.
//

import RealityKit
import SwiftUI

extension Entity {
    static func createText(_ string: String, height: Float, color: UIColor = .white) -> ModelEntity {
        guard let font = MeshResource.Font(name: "Helvetica", size: CGFloat(height)) else {
            fatalError("Couldn't load font.")
        }
        
        let mesh = MeshResource.generateText(string, extrusionDepth: height * 0.05, font: font)
        let material = UnlitMaterial(color: color)
        let text = ModelEntity(mesh: mesh, materials: [material])
        return text
    }
    
    // create origin axis visualization
    static func createAxes(axisScale: Float, alpha: CGFloat = 1.0) -> Entity {
        let axisEntity = Entity()
        let mesh = MeshResource.generateBox(size: [1.0, 1.0, 1.0])
        
        let xAxis = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1).withAlphaComponent(alpha))])
        let yAxis = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1).withAlphaComponent(alpha))])
        let zAxis = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1).withAlphaComponent(alpha))])
        axisEntity.children.append(contentsOf: [xAxis, yAxis, zAxis])
        
        let axisMinorScale = axisScale / 20
        let axisAxisOffset = axisScale / 2.0 + axisMinorScale / 2.0
        
        xAxis.position = [axisAxisOffset, 0, 0]
        xAxis.scale = [axisScale, axisMinorScale, axisMinorScale]
        yAxis.position = [0, axisAxisOffset, 0]
        yAxis.scale = [axisMinorScale, axisScale, axisMinorScale]
        zAxis.position = [0, 0, axisAxisOffset]
        zAxis.scale = [axisMinorScale, axisMinorScale, axisScale]
        return axisEntity
    }
    
    func applyMaterialRecursively(_ material: RealityFoundation.Material) {
        if let modelEntity = self as? ModelEntity {
            modelEntity.model?.materials = [material]
        }
        
        for child in children {
            child.applyMaterialRecursively(material)
        }
    }
}

extension Entity {
    @MainActor
    static func buildFragmentOverlay(model: Entity, fragmentGroup: FragmentGroup) -> Entity {
        let container = Entity()

        model.components.set(OpacityComponent(opacity: 0.7))
        container.addChild(model)

        let bounds = container.visualBounds(relativeTo: container)

        let fragmentColors: [SimpleMaterial.Color] = [
            SimpleMaterial.Color(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0),
            SimpleMaterial.Color(red: 0.1, green: 0.7, blue: 0.1, alpha: 1.0),
            SimpleMaterial.Color(red: 0.0, green: 0.9, blue: 0.2, alpha: 1.0),
            SimpleMaterial.Color(red: 0.2, green: 0.6, blue: 0.0, alpha: 1.0),
            SimpleMaterial.Color(red: 0.0, green: 1.0, blue: 0.3, alpha: 1.0),
            SimpleMaterial.Color(red: 0.1, green: 0.75, blue: 0.1, alpha: 1.0)
        ]

        let xAxisLeftMostPoint = bounds.center - SIMD3<Float>(bounds.extents.x / 2, 0, 0)
        let yAxisLeftMostPoint = bounds.center - SIMD3<Float>(0, bounds.extents.y / 2, 0)
        let zAxisLeftMostPoint = bounds.center - SIMD3<Float>(0, 0, bounds.extents.z / 2)

        for (index, fragment) in fragmentGroup.fragments.enumerated() {
            let color = fragmentColors[index % fragmentColors.count]

            for slice in [fragment.startSlice, fragment.endSlice] {
                let (width, height, depth): (Float, Float, Float) = {
                    switch fragmentGroup.orientation {
                    case "x": return (0.035, 0.035, 0.0005)
                    case "y": return (0.035, 0.0005, 0.035)
                    case "z": return (0.0005, 0.035, 0.035)
                    default:
                        print("⚠️ Invalid orientation, defaulting to thin X")
                        return (0.035, 0.035, 0.0005)
                    }
                }()

                let mesh = MeshResource.generateBox(width: width, height: height, depth: depth)
                let material = SimpleMaterial(color: color, roughness: 0.5, isMetallic: false)
                let sliceModel = ModelEntity(mesh: mesh, materials: [material])

                let sliceEntity = Entity()
                sliceEntity.addChild(sliceModel)

                let (leftMostPoint, direction): (SIMD3<Float>, SIMD3<Float>) = {
                    switch fragmentGroup.orientation {
                    case "x": return (xAxisLeftMostPoint, SIMD3<Float>(1, 0, 0))
                    case "y": return (yAxisLeftMostPoint, SIMD3<Float>(0, 1, 0))
                    case "z": return (zAxisLeftMostPoint, SIMD3<Float>(0, 0, 1))
                    default:
                        print("⚠️ Invalid orientation, defaulting to X-axis")
                        return (xAxisLeftMostPoint, SIMD3<Float>(1, 0, 0))
                    }
                }()

                sliceEntity.position = leftMostPoint + direction * slice.distanceFromLeftAnchor
                sliceEntity.orientation = quaternionFromEuler(
                    xDeg: slice.xRotationDegrees,
                    yDeg: slice.yRotationDegrees,
                    zDeg: slice.zRotationDegrees
                )

                container.addChild(sliceEntity)
            }
        }

        return container
    }
}

extension Float {
    var degreesToRadians: Float { self * .pi / 180 }
}

func quaternionFromEuler(xDeg: Float, yDeg: Float, zDeg: Float) -> simd_quatf {
    let x = simd_quatf(angle: xDeg.degreesToRadians, axis: [1, 0, 0])
    let y = simd_quatf(angle: yDeg.degreesToRadians, axis: [0, 1, 0])
    let z = simd_quatf(angle: zDeg.degreesToRadians, axis: [0, 0, 1])
    return z * y * x // match with data from blender
}
