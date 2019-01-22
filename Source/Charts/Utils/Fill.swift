//
//  Fill.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

public enum Fill: Equatable {
    case empty
    case color(CGColor)
    case linearGradient(CGGradient, angle: CGFloat)
    case image(CGImage, tiled: Bool)
    case layer(CGLayer)
    
    // MARK: Drawing code
    public func fillColorPath(color: CGColor, context: CGContext, rect: CGRect) {
        context.saveGState()
        context.setFillColor(color)
        context.fillPath()
        context.restoreGState()
    }
    
    public func fillImagePath(image: CGImage, tiled: Bool, context: CGContext, rect: CGRect) {
        context.saveGState()
        context.clip()
        context.draw(image, in: rect, byTiling: tiled)
        context.restoreGState()
    }
    
    public func fillLayerPath(layer: CGLayer, context: CGContext, rect: CGRect) {
        context.saveGState()
        context.clip()
        context.draw(layer, in: rect)
        context.restoreGState()
    }
    
    public func fillLinearGradient(
        gradient: CGGradient,
        angle: CGFloat,
        context: CGContext,
        rect: CGRect
    ) {
        context.saveGState()
        
        let radians = (360.0 - angle).DEG2RAD
        let centerPoint = CGPoint(x: rect.midX, y: rect.midY)
        let xAngleDelta = cos(radians) * rect.width / 2.0
        let yAngleDelta = sin(radians) * rect.height / 2.0
        let startPoint = CGPoint(
            x: centerPoint.x - xAngleDelta,
            y: centerPoint.y - yAngleDelta
        )
        let endPoint = CGPoint(
            x: centerPoint.x + xAngleDelta,
            y: centerPoint.y + yAngleDelta
        )
        
        context.clip()
        context.drawLinearGradient(
            gradient,
            start: startPoint,
            end: endPoint,
            options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
        )
        context.restoreGState()
    }
    
    public func fillPath(context: CGContext, rect: CGRect) {
        switch self {
            case .empty:
                break
            case .color(let color):
                fillColorPath(color: color, context: context, rect: rect)
            case .image(let image, tiled: let tiled):
                fillImagePath(image: image, tiled: tiled, context: context, rect: rect)
            case .layer(let layer):
                fillLayerPath(layer: layer, context: context, rect: rect)
            case .linearGradient(let gradient, let angle):
                fillLinearGradient(
                    gradient: gradient, angle: angle, context: context, rect: rect
                )
        }
    }
}
