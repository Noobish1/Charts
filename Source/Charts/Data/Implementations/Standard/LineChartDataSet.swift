//
//  LineChartDataSet.swift
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


open class LineChartDataSet: ChartDataSet, LineChartDataSetProtocol
{
    public enum Mode: Int
    {
        case linear
        case stepped
        case cubicBezier
        case horizontalBezier
    }
    
    // MARK: - Styling functions and accessors
    
    /// The color that is used for filling the line surface area.
    open var fillColor = UIColor(
        red: 140.0/255.0, green: 234.0/255.0, blue: 255.0/255.0, alpha: 1.0
    )
    
    /// The object that is used for filling the area below the line.
    /// **default**: nil
    open var fill: Fill = .empty
    
    /// The alpha value that is used for filling the line surface,
    /// **default**: 0.33
    open var fillAlpha = CGFloat(0.33)
    
    private var _lineWidth = CGFloat(1.0)
    
    /// line width of the chart (min = 0.0, max = 10)
    ///
    /// **default**: 1
    open var lineWidth: CGFloat
    {
        get
        {
            return _lineWidth
        }
        set
        {
            if newValue < 0.0
            {
                _lineWidth = 0.0
            }
            else if newValue > 10.0
            {
                _lineWidth = 10.0
            }
            else
            {
                _lineWidth = newValue
            }
        }
    }
    
    /// Set to `true` if the DataSet should be drawn filled (surface), and not just as a line.
    /// Disabling this will give great performance boost.
    /// Please note that this method uses the path clipping for drawing the filled area (with images, gradients and layers).
    open var drawFilledEnabled = false
    
    /// - returns: `true` if filled drawing is enabled, `false` ifnot
    open var isDrawFilledEnabled: Bool
    {
        return drawFilledEnabled
    }
    
    /// The drawing mode for this line dataset
    ///
    /// **default**: Linear
    open var mode: Mode = Mode.linear
    
    private var _cubicIntensity = CGFloat(0.2)
    
    /// Intensity for cubic lines (min = 0.05, max = 1)
    ///
    /// **default**: 0.2
    open var cubicIntensity: CGFloat
    {
        get
        {
            return _cubicIntensity
        }
        set
        {
            _cubicIntensity = newValue
            if _cubicIntensity > 1.0
            {
                _cubicIntensity = 1.0
            }
            if _cubicIntensity < 0.05
            {
                _cubicIntensity = 0.05
            }
        }
    }
    
    /// Line cap type, default is CGLineCap.Butt
    open var lineCapType = CGLineCap.butt
    
    /// formatter for customizing the position of the fill-line
    private var _fillFormatter: FillFormatterProtocol = DefaultFillFormatter()
    
    /// Sets a custom IFillFormatter to the chart that handles the position of the filled-line for each DataSet. Set this to null to use the default logic.
    open var fillFormatter: FillFormatterProtocol?
    {
        get
        {
            return _fillFormatter
        }
        set
        {
            _fillFormatter = newValue ?? DefaultFillFormatter()
        }
    }
}
