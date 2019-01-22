//
//  IScatterChartDataSet.swift
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

public protocol ScatterChartDataSetProtocol: ChartDataSetProtocol
{
    // MARK: - Styling functions and accessors
    
    /// - returns: The size the scatter shape will have
    var scatterShapeSize: CGFloat { get }
    
    /// - returns: The IShapeRenderer responsible for rendering this DataSet.
    var shapeRenderer: ShapeRendererProtocol { get }
}
