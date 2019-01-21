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
    
    private func initialize()
    {
        // default color
        circleColors.append(UIColor(red: 140.0/255.0, green: 234.0/255.0, blue: 255.0/255.0, alpha: 1.0))
    }
    
    public required init()
    {
        super.init()
        initialize()
    }
    
    public override init(values: [ChartDataEntry]?, label: String?)
    {
        super.init(values: values, label: label)
        initialize()
    }
    
    // MARK: - Styling functions and accessors
    
    /// The color that is used for filling the line surface area.
    private var _fillColor = UIColor(red: 140.0/255.0, green: 234.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    
    /// The color that is used for filling the line surface area.
    open var fillColor: UIColor
    {
        get { return _fillColor }
        set
        {
            _fillColor = newValue
            fill = nil
        }
    }
    
    /// The object that is used for filling the area below the line.
    /// **default**: nil
    open var fill: Fill?
    
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
        
    /// The radius of the drawn circles.
    open var circleRadius = CGFloat(8.0)
    
    /// The hole radius of the drawn circles
    open var circleHoleRadius = CGFloat(4.0)
    
    open var circleColors = [UIColor]()
    
    /// - returns: The color at the given index of the DataSet's circle-color array.
    /// Performs a IndexOutOfBounds check by modulus.
    open func getCircleColor(atIndex index: Int) -> UIColor?
    {
        let size = circleColors.count
        let index = index % size
        if index >= size
        {
            return nil
        }
        return circleColors[index]
    }
    
    /// Sets the one and ONLY color that should be used for this DataSet.
    /// Internally, this recreates the colors array and adds the specified color.
    open func setCircleColor(_ color: UIColor)
    {
        circleColors.removeAll(keepingCapacity: false)
        circleColors.append(color)
    }
    
    open func setCircleColors(_ colors: UIColor...)
    {
        circleColors.removeAll(keepingCapacity: false)
        circleColors.append(contentsOf: colors)
    }
    
    /// Resets the circle-colors array and creates a new one
    open func resetCircleColors(_ index: Int)
    {
        circleColors.removeAll(keepingCapacity: false)
    }
    
    /// If true, drawing circles is enabled
    open var drawCirclesEnabled = true
    
    /// - returns: `true` if drawing circles for this DataSet is enabled, `false` ifnot
    open var isDrawCirclesEnabled: Bool { return drawCirclesEnabled }
    
    /// The color of the inner circle (the circle-hole).
    open var circleHoleColor: UIColor? = UIColor.white
    
    /// `true` if drawing circles for this DataSet is enabled, `false` ifnot
    open var drawCircleHoleEnabled = true
    
    /// - returns: `true` if drawing the circle-holes is enabled, `false` ifnot.
    open var isDrawCircleHoleEnabled: Bool { return drawCircleHoleEnabled }
    
    /// This is how much (in pixels) into the dash pattern are we starting from.
    open var lineDashPhase = CGFloat(0.0)
    
    /// This is the actual dash pattern.
    /// I.e. [2, 3] will paint [--   --   ]
    /// [1, 3, 4, 2] will paint [-   ----  -   ----  ]
    open var lineDashLengths: [CGFloat]?
    
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
    
    // MARK: NSCopying
    open override func copyWithZone(_ zone: NSZone?) -> AnyObject
    {
        let copy = super.copyWithZone(zone) as! LineChartDataSet
        copy.fillColor = fillColor
        copy._lineWidth = _lineWidth
        copy.drawFilledEnabled = drawFilledEnabled
        copy.circleColors = circleColors
        copy.circleRadius = circleRadius
        copy.cubicIntensity = cubicIntensity
        copy.lineDashPhase = lineDashPhase
        copy.lineDashLengths = lineDashLengths
        copy.lineCapType = lineCapType
        copy.drawCirclesEnabled = drawCirclesEnabled
        copy.drawCircleHoleEnabled = drawCircleHoleEnabled
        copy.mode = mode
        return copy
    }
}
