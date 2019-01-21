//
//  BarLineChartViewBase.swift
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
import UIKit

/// Base-class of LineChart, BarChart, ScatterChart and CandleStickChart.
open class BarLineChartViewBase: ChartViewBase, BarLineScatterChartDataProvider
{
    /// the maximum number of entries to which values will be drawn
    /// (entry numbers greater than this value will cause value-labels to disappear)
    internal var _maxVisibleCount = 100
    
    /// flag that indicates if auto scaling on the y axis is enabled
    private var _autoScaleMinMaxEnabled = false
    
    /// the color for the background of the chart-drawing area (everything behind the grid lines).
    open var gridBackgroundColor = UIColor(red: 240/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1.0)
    
    open var borderColor = UIColor.black
    open var borderLineWidth: CGFloat = 1.0
    
    /// flag indicating if the grid background should be drawn or not
    open var drawGridBackgroundEnabled = false
    
    /// When enabled, the borders rectangle will be rendered.
    /// If this is enabled, there is no point drawing the axis-lines of x- and y-axis.
    open var drawBordersEnabled = false
    
    /// When enabled, the values will be clipped to contentRect, otherwise they can bleed outside the content rect.
    open var clipValuesToContentEnabled: Bool = false

    /// When disabled, the data will not be clipped to contentRect. Disabling this option can
    /// be useful, when the data lies fully within the content rect, but is drawn in such a way (such as thick lines)
    /// that there is unwanted clipping.
    open var clipDataToContentEnabled: Bool = true

    /// Sets the minimum offset (padding) around the chart, defaults to 10
    open var minOffset = CGFloat(10.0)
    
    /// Sets whether the chart should keep its position (scroll) after a rotation (orientation change)
    /// **default**: false
    open var keepPositionOnRotation: Bool = false
    
    /// The left y-axis object. In the horizontal bar-chart, this is the
    /// top axis.
    open internal(set) var leftAxis = YAxis(position: .left)
    
    /// The right y-axis object. In the horizontal bar-chart, this is the
    /// bottom axis.
    open internal(set) var rightAxis = YAxis(position: .right)

    /// The left Y axis renderer. This is a read-write property so you can set your own custom renderer here.
    /// **default**: An instance of YAxisRenderer
    open lazy var leftYAxisRenderer = YAxisRenderer(viewPortHandler: _viewPortHandler, yAxis: leftAxis, transformer: _leftAxisTransformer)

    /// The right Y axis renderer. This is a read-write property so you can set your own custom renderer here.
    /// **default**: An instance of YAxisRenderer
    open lazy var rightYAxisRenderer = YAxisRenderer(viewPortHandler: _viewPortHandler, yAxis: rightAxis, transformer: _rightAxisTransformer)
    
    internal var _leftAxisTransformer: Transformer!
    internal var _rightAxisTransformer: Transformer!
    
    /// The X axis renderer. This is a read-write property so you can set your own custom renderer here.
    /// **default**: An instance of XAxisRenderer
    open lazy var xAxisRenderer = XAxisRenderer(viewPortHandler: _viewPortHandler, xAxis: _xAxis, transformer: _leftAxisTransformer)
    
    public override init(frame: CGRect)
    {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    internal override func initialize()
    {
        super.initialize()

        _leftAxisTransformer = Transformer(viewPortHandler: _viewPortHandler)
        _rightAxisTransformer = Transformer(viewPortHandler: _viewPortHandler)
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        // Saving current position of chart.
        var oldPoint: CGPoint?
        if (keepPositionOnRotation && (keyPath == "frame" || keyPath == "bounds"))
        {
            oldPoint = viewPortHandler.contentRect.origin
            getTransformer(forAxis: .left).pixelToValues(&oldPoint!)
        }
        
        // Superclass transforms chart.
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        
        // Restoring old position of chart
        if var newPoint = oldPoint , keepPositionOnRotation
        {
            getTransformer(forAxis: .left).pointValueToPixel(&newPoint)
            viewPortHandler.centerViewPort(pt: newPoint, chart: self)
        }
        else
        {
            viewPortHandler.refresh(newMatrix: viewPortHandler.touchMatrix, chart: self, invalidate: true)
        }
    }
    
    open override func draw(_ rect: CGRect)
    {
        super.draw(rect)

        guard data != nil, let renderer = renderer else { return }
        
        let optionalContext = UIGraphicsGetCurrentContext()
        guard let context = optionalContext else { return }

        // execute all drawing commands
        drawGridBackground(context: context)
        

        if _autoScaleMinMaxEnabled
        {
            autoScale()
        }

        if leftAxis.isEnabled
        {
            leftYAxisRenderer.computeAxis(min: leftAxis._axisMinimum, max: leftAxis._axisMaximum, inverted: leftAxis.isInverted)
        }
        
        if rightAxis.isEnabled
        {
            rightYAxisRenderer.computeAxis(min: rightAxis._axisMinimum, max: rightAxis._axisMaximum, inverted: rightAxis.isInverted)
        }
        
        if _xAxis.isEnabled
        {
            xAxisRenderer.computeAxis(min: _xAxis._axisMinimum, max: _xAxis._axisMaximum, inverted: false)
        }
        
        xAxisRenderer.renderAxisLine(context: context)
        leftYAxisRenderer.renderAxisLine(context: context)
        rightYAxisRenderer.renderAxisLine(context: context)

        // The renderers are responsible for clipping, to account for line-width center etc.
        xAxisRenderer.renderGridLines(context: context)
        leftYAxisRenderer.renderGridLines(context: context)
        rightYAxisRenderer.renderGridLines(context: context)
        
        context.saveGState()
        // make sure the data cannot be drawn outside the content-rect
        if clipDataToContentEnabled {
            context.clip(to: _viewPortHandler.contentRect)
        }
        renderer.drawData(context: context)
        
        context.restoreGState()
        
        renderer.drawExtras(context: context)
        
        xAxisRenderer.renderAxisLabels(context: context)
        leftYAxisRenderer.renderAxisLabels(context: context)
        rightYAxisRenderer.renderAxisLabels(context: context)

        if clipValuesToContentEnabled
        {
            context.saveGState()
            context.clip(to: _viewPortHandler.contentRect)
            
            renderer.drawValues(context: context)
            
            context.restoreGState()
        }
        else
        {
            renderer.drawValues(context: context)
        }

        drawDescription(context: context)
    }
    
    /// Performs auto scaling of the axis by recalculating the minimum and maximum y-values based on the entries currently in view.
    internal func autoScale()
    {
        guard let data = _data
            else { return }
        
        data.calcMinMaxY(fromX: self.lowestVisibleX, toX: self.highestVisibleX)
        
        _xAxis.calculate(min: data.xMin, max: data.xMax)
        
        // calculate axis range (min / max) according to provided data
        
        if leftAxis.isEnabled
        {
            leftAxis.calculate(min: data.getYMin(axis: .left), max: data.getYMax(axis: .left))
        }
        
        if rightAxis.isEnabled
        {
            rightAxis.calculate(min: data.getYMin(axis: .right), max: data.getYMax(axis: .right))
        }
        
        calculateOffsets()
    }
    
    internal func prepareValuePxMatrix()
    {
        _rightAxisTransformer.prepareMatrixValuePx(chartXMin: _xAxis._axisMinimum, deltaX: CGFloat(xAxis.axisRange), deltaY: CGFloat(rightAxis.axisRange), chartYMin: rightAxis._axisMinimum)
        _leftAxisTransformer.prepareMatrixValuePx(chartXMin: xAxis._axisMinimum, deltaX: CGFloat(xAxis.axisRange), deltaY: CGFloat(leftAxis.axisRange), chartYMin: leftAxis._axisMinimum)
    }
    
    internal func prepareOffsetMatrix()
    {
        _rightAxisTransformer.prepareMatrixOffset(inverted: rightAxis.isInverted)
        _leftAxisTransformer.prepareMatrixOffset(inverted: leftAxis.isInverted)
    }
    
    open override func notifyDataSetChanged()
    {
        renderer?.initBuffers()
        
        calcMinMax()
        
        leftYAxisRenderer.computeAxis(min: leftAxis._axisMinimum, max: leftAxis._axisMaximum, inverted: leftAxis.isInverted)
        rightYAxisRenderer.computeAxis(min: rightAxis._axisMinimum, max: rightAxis._axisMaximum, inverted: rightAxis.isInverted)
        
        if let _ = _data
        {
            xAxisRenderer.computeAxis(
                min: _xAxis._axisMinimum,
                max: _xAxis._axisMaximum,
                inverted: false)
        }
        
        calculateOffsets()
        
        setNeedsDisplay()
    }
    
    internal override func calcMinMax()
    {
        // calculate / set x-axis range
        _xAxis.calculate(min: _data?.xMin ?? 0.0, max: _data?.xMax ?? 0.0)
        
        // calculate axis range (min / max) according to provided data
        leftAxis.calculate(min: _data?.getYMin(axis: .left) ?? 0.0, max: _data?.getYMax(axis: .left) ?? 0.0)
        rightAxis.calculate(min: _data?.getYMin(axis: .right) ?? 0.0, max: _data?.getYMax(axis: .right) ?? 0.0)
    }
    
    internal override func calculateOffsets()
    {
        var offsetLeft = CGFloat(0.0)
        var offsetRight = CGFloat(0.0)
        var offsetTop = CGFloat(0.0)
        var offsetBottom = CGFloat(0.0)
        
        // offsets for y-labels
        if leftAxis.needsOffset
        {
            offsetLeft += leftAxis.requiredSize().width
        }
        
        if rightAxis.needsOffset
        {
            offsetRight += rightAxis.requiredSize().width
        }

        if xAxis.isEnabled && xAxis.isDrawLabelsEnabled
        {
            let xlabelheight = xAxis.labelRotatedHeight + xAxis.yOffset
            
            // offsets for x-labels
            if xAxis.labelPosition == .bottom
            {
                offsetBottom += xlabelheight
            }
            else if xAxis.labelPosition == .top
            {
                offsetTop += xlabelheight
            }
            else if xAxis.labelPosition == .bothSided
            {
                offsetBottom += xlabelheight
                offsetTop += xlabelheight
            }
        }
        
        offsetTop += self.extraTopOffset
        offsetRight += self.extraRightOffset
        offsetBottom += self.extraBottomOffset
        offsetLeft += self.extraLeftOffset

        _viewPortHandler.restrainViewPort(
            offsetLeft: max(self.minOffset, offsetLeft),
            offsetTop: max(self.minOffset, offsetTop),
            offsetRight: max(self.minOffset, offsetRight),
            offsetBottom: max(self.minOffset, offsetBottom))
        
        prepareOffsetMatrix()
        prepareValuePxMatrix()
    }
    
    /// draws the grid background
    internal func drawGridBackground(context: CGContext)
    {
        if drawGridBackgroundEnabled || drawBordersEnabled
        {
            context.saveGState()
        }
        
        if drawGridBackgroundEnabled
        {
            // draw the grid background
            context.setFillColor(gridBackgroundColor.cgColor)
            context.fill(_viewPortHandler.contentRect)
        }
        
        if drawBordersEnabled
        {
            context.setLineWidth(borderLineWidth)
            context.setStrokeColor(borderColor.cgColor)
            context.stroke(_viewPortHandler.contentRect)
        }
        
        if drawGridBackgroundEnabled || drawBordersEnabled
        {
            context.restoreGState()
        }
    }
    
    /// MARK: Viewport modifiers
    
    open var visibleXRange: Double
    {
        return abs(highestVisibleX - lowestVisibleX)
    }

    // MARK: - Accessors
    
    /// - returns: The range of the specified axis.
    open func getAxisRange(axis: YAxis.AxisDependency) -> Double
    {
        if axis == .left
        {
            return leftAxis.axisRange
        }
        else
        {
            return rightAxis.axisRange
        }
    }

    /// - returns: The position (in pixels) the provided Entry has inside the chart view
    open func getPosition(entry e: ChartDataEntry, axis: YAxis.AxisDependency) -> CGPoint
    {
        var vals = CGPoint(x: CGFloat(e.x), y: CGFloat(e.y))

        getTransformer(forAxis: axis).pointValueToPixel(&vals)

        return vals
    }
    
    /// **default**: true
    /// - returns: `true` if drawing the grid background is enabled, `false` ifnot.
    open var isDrawGridBackgroundEnabled: Bool
    {
        return drawGridBackgroundEnabled
    }
    
    /// **default**: false
    /// - returns: `true` if drawing the borders rectangle is enabled, `false` ifnot.
    open var isDrawBordersEnabled: Bool
    {
        return drawBordersEnabled
    }

    /// - returns: The x and y values in the chart at the given touch point
    /// (encapsulated in a `CGPoint`). This method transforms pixel coordinates to
    /// coordinates / values in the chart. This is the opposite method to
    /// `getPixelsForValues(...)`.
    open func valueForTouchPoint(point pt: CGPoint, axis: YAxis.AxisDependency) -> CGPoint
    {
        return getTransformer(forAxis: axis).valueForTouchPoint(pt)
    }

    /// Transforms the given chart values into pixels. This is the opposite
    /// method to `valueForTouchPoint(...)`.
    open func pixelForValues(x: Double, y: Double, axis: YAxis.AxisDependency) -> CGPoint
    {
        return getTransformer(forAxis: axis).pixelForValues(x: x, y: y)
    }

    /// - returns: The y-axis object to the corresponding AxisDependency. In the
    /// horizontal bar-chart, LEFT == top, RIGHT == BOTTOM
    open func getAxis(_ axis: YAxis.AxisDependency) -> YAxis
    {
        if axis == .left
        {
            return leftAxis
        }
        else
        {
            return rightAxis
        }
    }

    open override var chartYMax: Double
    {
        return max(leftAxis._axisMaximum, rightAxis._axisMaximum)
    }

    open override var chartYMin: Double
    {
        return min(leftAxis._axisMinimum, rightAxis._axisMinimum)
    }
    
    /// - returns: `true` if either the left or the right or both axes are inverted.
    open var isAnyAxisInverted: Bool
    {
        return leftAxis.isInverted || rightAxis.isInverted
    }
    
    /// flag that indicates if auto scaling on the y axis is enabled.
    /// if yes, the y axis automatically adjusts to the min and max y values of the current x axis range whenever the viewport changes
    open var autoScaleMinMaxEnabled: Bool
    {
        get { return _autoScaleMinMaxEnabled }
        set { _autoScaleMinMaxEnabled = newValue }
    }
    
    /// **default**: false
    /// - returns: `true` if auto scaling on the y axis is enabled.
    open var isAutoScaleMinMaxEnabled : Bool { return autoScaleMinMaxEnabled }
    
    /// Sets a minimum width to the specified y axis.
    open func setYAxisMinWidth(_ axis: YAxis.AxisDependency, width: CGFloat)
    {
        if axis == .left
        {
            leftAxis.minWidth = width
        }
        else
        {
            rightAxis.minWidth = width
        }
    }
    
    /// **default**: 0.0
    /// - returns: The (custom) minimum width of the specified Y axis.
    open func getYAxisMinWidth(_ axis: YAxis.AxisDependency) -> CGFloat
    {
        if axis == .left
        {
            return leftAxis.minWidth
        }
        else
        {
            return rightAxis.minWidth
        }
    }
    /// Sets a maximum width to the specified y axis.
    /// Zero (0.0) means there's no maximum width
    open func setYAxisMaxWidth(_ axis: YAxis.AxisDependency, width: CGFloat)
    {
        if axis == .left
        {
            leftAxis.maxWidth = width
        }
        else
        {
            rightAxis.maxWidth = width
        }
    }
    
    /// Zero (0.0) means there's no maximum width
    ///
    /// **default**: 0.0 (no maximum specified)
    /// - returns: The (custom) maximum width of the specified Y axis.
    open func getYAxisMaxWidth(_ axis: YAxis.AxisDependency) -> CGFloat
    {
        if axis == .left
        {
            return leftAxis.maxWidth
        }
        else
        {
            return rightAxis.maxWidth
        }
    }

    /// - returns the width of the specified y axis.
    open func getYAxisWidth(_ axis: YAxis.AxisDependency) -> CGFloat
    {
        if axis == .left
        {
            return leftAxis.requiredSize().width
        }
        else
        {
            return rightAxis.requiredSize().width
        }
    }
    
    // MARK: - BarLineScatterCandleBubbleChartDataProvider
    
    /// - returns: The Transformer class that contains all matrices and is
    /// responsible for transforming values into pixels on the screen and
    /// backwards.
    open func getTransformer(forAxis axis: YAxis.AxisDependency) -> Transformer
    {
        if axis == .left
        {
            return _leftAxisTransformer
        }
        else
        {
            return _rightAxisTransformer
        }
    }
    
    /// the number of maximum visible drawn values on the chart only active when `drawValuesEnabled` is enabled
    open override var maxVisibleCount: Int
    {
        get
        {
            return _maxVisibleCount
        }
        set
        {
            _maxVisibleCount = newValue
        }
    }
    
    open func isInverted(axis: YAxis.AxisDependency) -> Bool
    {
        return getAxis(axis).isInverted
    }
    
    /// - returns: The lowest x-index (value on the x-axis) that is still visible on he chart.
    open var lowestVisibleX: Double
    {
        var pt = CGPoint(
            x: viewPortHandler.contentLeft,
            y: viewPortHandler.contentBottom)
        
        getTransformer(forAxis: .left).pixelToValues(&pt)
        
        return max(xAxis._axisMinimum, Double(pt.x))
    }
    
    /// - returns: The highest x-index (value on the x-axis) that is still visible on the chart.
    open var highestVisibleX: Double
    {
        var pt = CGPoint(
            x: viewPortHandler.contentRight,
            y: viewPortHandler.contentBottom)
        
        getTransformer(forAxis: .left).pixelToValues(&pt)

        return min(xAxis._axisMaximum, Double(pt.x))
    }
}
