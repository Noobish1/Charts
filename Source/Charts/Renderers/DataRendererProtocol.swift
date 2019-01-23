//
//  DataRenderer.swift
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

// MARK: DataRendererProtocol
public protocol DataRendererProtocol: RendererProtocol {
    func drawData(context: CGContext)
    func drawValues(context: CGContext)
    
    /// An opportunity for initializing internal buffers used for rendering with a new size.
    /// Since this might do memory allocations, it should only be called if necessary.
    func initBuffers()
}

// MARK: extensions
public extension DataRendererProtocol {
    public func isDrawingValuesAllowed(dataProvider: ChartDataProviderProtocol?) -> Bool {
        guard let data = dataProvider?.data else {
            return false
        }
        
        return data.entryCount < Int(CGFloat(dataProvider?.maxVisibleCount ?? 0))
    }
}
