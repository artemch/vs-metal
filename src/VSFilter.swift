//
//  VSFilter.swift
//  vs-metal
//
//  Created by SATOSHI NAKAJIMA on 6/22/17.
//  Copyright © 2017 SATOSHI NAKAJIMA. All rights reserved.
//

import Foundation
import MetalKit

struct VSFilter: VSNode {
    private let pipelineState:MTLComputePipelineState
    private let paramBuffers:[MTLBuffer]
    private let sourceCount:Int
    
    private init(pipelineState:MTLComputePipelineState, buffers:[MTLBuffer], sourceCount:Int) {
        self.pipelineState = pipelineState
        self.paramBuffers = buffers
        self.sourceCount = sourceCount
    }

    static func makeNode(name nodeName:String, buffers:[MTLBuffer], sourceCount:Int, context:VSContext) -> VSNode? {
        guard let kernel = context.device.newDefaultLibrary()!.makeFunction(name: nodeName) else {
            print("### VSScript:makeNode failed to create kernel", nodeName)
            return nil
        }
        do {
            let pipelineState = try context.device.makeComputePipelineState(function: kernel)
            return VSFilter(pipelineState: pipelineState, buffers: buffers, sourceCount:sourceCount)
        } catch {
            print("### VSScript:makeNode failed to create pipeline state", nodeName)
        }
        return nil
    }
    
    func encode(commandBuffer:MTLCommandBuffer, context:VSContext) throws {
        let encoder = commandBuffer.makeComputeCommandEncoder()
        encoder.setComputePipelineState(pipelineState)
        for index in 0..<sourceCount {
            encoder.setTexture(try context.pop().texture, at: index)
        }
        let destination = context.getDestination()
        encoder.setTexture(destination.texture, at: sourceCount)
        for (index, buffer) in paramBuffers.enumerated() {
            encoder.setBuffer(buffer, offset: 0, at: sourceCount + 1 + index)
        }
        encoder.dispatchThreadgroups(context.threadGroupCount, threadsPerThreadgroup: context.threadGroupSize)
        encoder.endEncoding()
        context.push(texture:destination)
    }
}
