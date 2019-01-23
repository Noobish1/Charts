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
open class BarLineChartViewBase: UIView, BarLineScatterChartDataProvider
{
    /// - returns: The object representing all x-labels, this method can be used to
    /// acquire the XAxis object and modify it (e.g. change the position of the
    /// labels)
    open var xAxis: XAxis
    {
        return _xAxis
    }
    
    /// The default IValueFormatter that has been determined by the chart considering the provided minimum and maximum values.
    internal var _defaultValueFormatter: ValueFormatterProtocol = DefaultValueFormatter(decimals: 0)
    
    /// object that holds all data that was originally set for the chart, before it was modified or any filtering algorithms had been applied
    internal var _data: ChartData?
    
    /// The object representing the labels on the x-axis
    internal let _xAxis = XAxis()
    
    /// object responsible for rendering the data
    open var renderer: DataRendererProtocol?
    
    /// object that manages the bounds and drawing constraints of the chart
    internal var _viewPortHandler: ViewPortHandler!
    
    /// flag that indicates if offsets calculation has already been done or not
    private var _offsetsCalculated = false
    
    /// An extra offset to be appended to the viewport's top
    open var extraTopOffset: CGFloat = 0.0
    
    /// An extra offset to be appended to the viewport's right
    open var extraRightOffset: CGFloat = 0.0
    
    /// An extra offset to be appended to the viewport's bottom
    open var extraBottomOffset: CGFloat = 0.0
    
    /// An extra offset to be appended to the viewport's left
    open var extraLeftOffset: CGFloat = 0.0
    
    open func setExtraOffsets(left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat)
    {
        extraLeftOffset = left
        extraTopOffset = top
        extraRightOffset = right
        extraBottomOffset = bottom
    }
    
    /// the maximum number of entries to which values will be drawn
    /// (entry numbers greater than this value will cause value-labels to disappear)
    internal var _maxVisibleCount = 100
    
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
        
        initialize()
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    deinit
    {
        self.removeObserver(self, forKeyPath: "bounds")
        self.removeObserver(self, forKeyPath: "frame")
    }
    
    internal func initialize()
    {
        self.backgroundColor = UIColor.clear
        
        _viewPortHandler = ViewPortHandler(width: bounds.size.width, height: bounds.size.height)
        
        self.addObserver(self, forKeyPath: "bounds", options: .new, context: nil)
        self.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
        
        _leftAxisTransformer = Transformer(viewPortHandler: _viewPortHandler)
        _rightAxisTransformer = Transformer(viewPortHandler: _viewPortHandler)
    }
    
    /// The data for the chart
    open var data: ChartData?
    {
        get
        {
            return _data
        }
        set
        {
            _data = newValue
            _offsetsCalculated = false
            
            guard let _data = _data else
            {
                setNeedsDisplay()
                return
            }
            
            // calculate how many digits are needed
            setupDefaultFormatter(min: _data.getYMin(), max: _data.getYMax())
            
            for set in _data.dataSets
            {
                if set.needsFormatter || set.valueFormatter === _defaultValueFormatter
                {
                    set.valueFormatter = _defaultValueFormatter
                }
            }
            
            // let the chart know there is new data
            notifyDataSetChanged()
        }
    }
    
    /// Clears the chart from all data (sets it to null) and refreshes it (by calling setNeedsDisplay()).
    open func clear()
    {
        _data = nil
        _offsetsCalculated = false
    
        setNeedsDisplay()
    }
    
    /// calculates the required number of digits for the values that might be drawn in the chart (if enabled), and creates the default value formatter
    internal func setupDefaultFormatter(min: Double, max: Double)
    {
        // check if a custom formatter is set or not
        var reference = Double(0.0)
        
        if let data = _data , data.entryCount >= 2
        {
            reference = fabs(max - min)
        }
        else
        {
            let absMin = fabs(min)
            let absMax = fabs(max)
            reference = absMin > absMax ? absMin : absMax
        }
        
        
        if _defaultValueFormatter is DefaultValueFormatter
        {
            // setup the formatter with a new number of digits
            let digits = reference.decimalPlaces
            
            (_defaultValueFormatter as? DefaultValueFormatter)?.decimals
                = digits
        }
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
        
        if keyPath == "bounds" || keyPath == "frame"
        {
            let bounds = self.bounds
            
            if (_viewPortHandler !== nil &&
                (bounds.size.width != _viewPortHandler.chartWidth ||
                    bounds.size.height != _viewPortHandler.chartHeight))
            {
                _viewPortHandler.setChartDimens(width: bounds.size.width, height: bounds.size.height)
                
                // This may cause the chart view to mutate properties affecting the view port -- lets do this
                // before we try to run any pending jobs on the view port itself
                notifyDataSetChanged()
            }
        }
        
        // Restoring old position of chart
        if var newPoint = oldPoint , keepPositionOnRotation
        {
            getTransformer(forAxis: .left).pointValueToPixel(&newPoint)
            viewPortHandler.centerViewPort(pt: newPoint, chart: self)
        }
        else
        {
            viewPortHandler.refresh(newMatrix: viewPortHandler.touchMatrix, chart: self)
        }
    }
    
    open override func draw(_ rect: CGRect)
    {
        if !_offsetsCalculated
        {
            calculateOffsets()
            _offsetsCalculated = true
        }

        guard data != nil, let renderer = renderer else { return }
        
        let optionalContext = UIGraphicsGetCurrentContext()
        guard let context = optionalContext else { return }

        // execute all drawing commands

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
    
    open func notifyDataSetChanged()
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
    
    internal func calcMinMax()
    {
        // calculate / set x-axis range
        _xAxis.calculate(min: _data?.xMin ?? 0.0, max: _data?.xMax ?? 0.0)
        
        // calculate axis range (min / max) according to provided data
        leftAxis.calculate(min: _data?.getYMin(axis: .left) ?? 0.0, max: _data?.getYMax(axis: .left) ?? 0.0)
        rightAxis.calculate(min: _data?.getYMin(axis: .right) ?? 0.0, max: _data?.getYMax(axis: .right) ?? 0.0)
    }
    
    internal func calculateOffsets()
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

    // MARK: - Accessors
    
    /// - returns: The ViewPortHandler of the chart that is responsible for the
    /// content area of the chart and its offsets and dimensions.
    open var viewPortHandler: ViewPortHandler!
    {
        return _viewPortHandler
    }
    
    /// - returns: The bitmap that represents the chart.
    open func getChartImage(transparent: Bool) -> UIImage?
    {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque || !transparent, UIScreen.main.scale)
        
        guard let context = UIGraphicsGetCurrentContext()
            else { return nil }
        
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: bounds.size)
        
        if isOpaque || !transparent
        {
            // Background color may be partially transparent, we must fill with white if we want to output an opaque image
            context.setFillColor(UIColor.white.cgColor)
            context.fill(rect)
            
            if let backgroundColor = self.backgroundColor
            {
                context.setFillColor(backgroundColor.cgColor)
                context.fill(rect)
            }
        }
        
        layer.render(in: context)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image
    }
    
    public enum ImageFormat
    {
        case jpeg
        case png
    }
    
    /// Saves the current chart state with the given name to the given path on
    /// the sdcard leaving the path empty "" will put the saved file directly on
    /// the SD card chart is saved as a PNG image, example:
    /// saveToPath("myfilename", "foldername1/foldername2")
    ///
    /// - parameter to: path to the image to save
    /// - parameter format: the format to save
    /// - parameter compressionQuality: compression quality for lossless formats (JPEG)
    ///
    /// - returns: `true` if the image was saved successfully
    open func save(to path: String, format: ImageFormat, compressionQuality: Double) -> Bool
    {
        guard let image = getChartImage(transparent: format != .jpeg) else { return false }
        
        let imageData: Data?
        switch (format)
        {
            case .png: imageData = UIImagePNGRepresentation(image)
            case .jpeg: imageData = UIImageJPEGRepresentation(image, CGFloat(compressionQuality))
        }
        
        guard let data = imageData else { return false }
        
        do
        {
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        }
        catch
        {
            return false
        }
        
        return true
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

    open var chartYMax: Double
    {
        return max(leftAxis._axisMaximum, rightAxis._axisMaximum)
    }

    open var chartYMin: Double
    {
        return min(leftAxis._axisMinimum, rightAxis._axisMinimum)
    }
    
    /// - returns: `true` if either the left or the right or both axes are inverted.
    open var isAnyAxisInverted: Bool
    {
        return leftAxis.isInverted || rightAxis.isInverted
    }
    
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
    open var maxVisibleCount: Int
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
