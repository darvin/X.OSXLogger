//
//  MetalViewCoordinator.swift
//  OSXLogger
//
//  Created by standard on 4/19/23.
//

import Foundation
import SwiftUI
import MetalKit
import Vision




class Coordinator : NSObject, MTKViewDelegate {
    var parent: MetalView
    var device: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    
    var vertices = [VertexIn]()
    

    
    func update(textObservations:[VNRecognizedTextObservation]) {
        vertices = (textObservations as [VNRectangleObservation]).toVertices()
    }
    
    init(_ parent: MetalView) {
        self.parent = parent
        if let device = MTLCreateSystemDefaultDevice() {
            self.device = device
        }
        self.metalCommandQueue = device.makeCommandQueue()!
        super.init()
    }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    func draw(in view: MTKView) {
//        print("redraw")
        guard let drawable = view.currentDrawable else {
            return
        }
        
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
            return
        }
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
//        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 0, 1)
//        renderPassDescriptor.colorAttachments[0].loadAction = .clear
//        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        if vertices.count > 0 {
            let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<VertexIn>.stride * vertices.count, options: [])

            renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        }
        
        // Create a render pipeline state descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let library = device.makeDefaultLibrary()!

        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main") // Set the vertex function
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "myFragmentShader") // Set the fragment function
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat // Set the pixel format of the color attachment
        
        // Create a render pipeline state object
        let renderPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)

        // Set the render pipeline state on the render command encoder
        renderCommandEncoder.setRenderPipelineState(renderPipelineState)

        if vertices.count > 0 {
            renderCommandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertices.count)
        }

        renderCommandEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

}
