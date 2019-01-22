//
//  ScatterChartDataSet.swift
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

open class ScatterChartDataSet: ChartDataSet, ScatterChartDataSetProtocol
{
    /// The size the scatter shape will have
    open var scatterShapeSize = CGFloat(10.0)
    
    /// The IShapeRenderer responsible for rendering this DataSet.
    /// This can also be used to set a custom IShapeRenderer aside from the default ones.
    /// **default**: `SquareShapeRenderer`
    open var shapeRenderer: ShapeRendererProtocol = XShapeRenderer()
    
    // MARK: NSCopying
    
    open override func copyWithZone(_ zone: NSZone?) -> AnyObject
    {
        let copy = super.copyWithZone(zone) as! ScatterChartDataSet
        copy.scatterShapeSize = scatterShapeSize
        copy.shapeRenderer = shapeRenderer
        return copy
    }
}
