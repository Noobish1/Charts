//
//  ILineChartDataSet.swift
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

public protocol LineChartDataSetProtocol: ChartDataSetProtocol
{
    // MARK: - Styling functions and accessors
    
    /// The color that is used for filling the line surface area.
    var fillColor: UIColor { get set }
    
    /// - returns: The object that is used for filling the area below the line.
    /// **default**: nil
    var fill: Fill? { get set }
    
    /// The alpha value that is used for filling the line surface.
    /// **default**: 0.33
    var fillAlpha: CGFloat { get set }
    
    /// line width of the chart (min = 0.0, max = 10)
    ///
    /// **default**: 1
    var lineWidth: CGFloat { get set }
    
    /// Set to `true` if the DataSet should be drawn filled (surface), and not just as a line.
    /// Disabling this will give great performance boost.
    /// Please note that this method uses the path clipping for drawing the filled area (with images, gradients and layers).
    var drawFilledEnabled: Bool { get set }
    
    /// - returns: `true` if filled drawing is enabled, `false` if not
    var isDrawFilledEnabled: Bool { get }
    
    /// The drawing mode for this line dataset
    ///
    /// **default**: Linear
    var mode: LineChartDataSet.Mode { get set }
    
    /// Intensity for cubic lines (min = 0.05, max = 1)
    ///
    /// **default**: 0.2
    var cubicIntensity: CGFloat { get set }
    
    /// This is how much (in pixels) into the dash pattern are we starting from.
    var lineDashPhase: CGFloat { get }
    
    /// This is the actual dash pattern.
    /// I.e. [2, 3] will paint [--   --   ]
    /// [1, 3, 4, 2] will paint [-   ----  -   ----  ]
    var lineDashLengths: [CGFloat]? { get set }
    
    /// Line cap type, default is CGLineCap.Butt
    var lineCapType: CGLineCap { get set }
    
    /// Sets a custom IFillFormatter to the chart that handles the position of the filled-line for each DataSet. Set this to null to use the default logic.
    var fillFormatter: FillFormatterProtocol? { get set }
}
