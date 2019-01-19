//
//  ChartViewBase.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//
//  Based on https://github.com/PhilJay/MPAndroidChart/commit/c42b880

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif

@objc
public protocol ChartViewDelegate
{
    /// Called when a value has been selected inside the chart.
    /// - parameter entry: The selected Entry.
    @objc optional func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry)
    
    // Called when nothing has been selected or an "un-select" has been made.
    @objc optional func chartValueNothingSelected(_ chartView: ChartViewBase)
    
    // Callbacks when the chart is scaled / zoomed via pinch zoom gesture.
    @objc optional func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat)
    
    // Callbacks when the chart is moved / translated via drag gesture.
    @objc optional func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat)
}

open class ChartViewBase: NSUIView, ChartDataProvider, AnimatorDelegate
{
    // MARK: - Properties
    
    /// - returns: The object representing all x-labels, this method can be used to
    /// acquire the XAxis object and modify it (e.g. change the position of the
    /// labels)
    @objc open var xAxis: XAxis
    {
        return _xAxis
    }
    
    /// The default IValueFormatter that has been determined by the chart considering the provided minimum and maximum values.
    internal var _defaultValueFormatter: IValueFormatter? = DefaultValueFormatter(decimals: 0)
    
    /// object that holds all data that was originally set for the chart, before it was modified or any filtering algorithms had been applied
    internal var _data: ChartData?
    
    /// If set to true, chart continues to scroll after touch up
    @objc open var dragDecelerationEnabled = true
    
    /// Deceleration friction coefficient in [0 ; 1] interval, higher values indicate that speed will decrease slowly, for example if it set to 0, it will stop immediately.
    /// 1 is an invalid value, and will be converted to 0.999 automatically.
    private var _dragDecelerationFrictionCoef: CGFloat = 0.9
    
    /// if true, units are drawn next to the values in the chart
    internal var _drawUnitInChart = false
    
    /// The object representing the labels on the x-axis
    internal var _xAxis: XAxis!
    
    /// The `Description` object of the chart.
    /// This should have been called just "description", but
    @objc open var chartDescription: Description?
        
    /// The legend object containing all data associated with the legend
    internal var _legend: Legend!
    
    /// delegate to receive chart events
    @objc open weak var delegate: ChartViewDelegate?
    
    /// text that is displayed when the chart is empty
    @objc open var noDataText = "No chart data available."
    
    /// Font to be used for the no data text.
    @objc open var noDataFont: NSUIFont! = NSUIFont(name: "HelveticaNeue", size: 12.0)
    
    /// color of the no data text
    @objc open var noDataTextColor: NSUIColor = NSUIColor.black

    /// alignment of the no data text
    open var noDataTextAlignment: NSTextAlignment = .left

    internal var _legendRenderer: LegendRenderer!
    
    /// object responsible for rendering the data
    @objc open var renderer: DataRenderer?
    
    /// object that manages the bounds and drawing constraints of the chart
    internal var _viewPortHandler: ViewPortHandler!
    
    /// object responsible for animations
    internal var _animator: Animator!
    
    /// flag that indicates if offsets calculation has already been done or not
    private var _offsetsCalculated = false
    
    /// `true` if drawing the marker is enabled when tapping on values
    /// (use the `marker` property to specify a marker)
    @objc open var drawMarkers = true
    
    /// - returns: `true` if drawing the marker is enabled when tapping on values
    /// (use the `marker` property to specify a marker)
    @objc open var isDrawMarkersEnabled: Bool { return drawMarkers }
    
    private var _interceptTouchEvents = false
    
    /// An extra offset to be appended to the viewport's top
    @objc open var extraTopOffset: CGFloat = 0.0
    
    /// An extra offset to be appended to the viewport's right
    @objc open var extraRightOffset: CGFloat = 0.0
    
    /// An extra offset to be appended to the viewport's bottom
    @objc open var extraBottomOffset: CGFloat = 0.0
    
    /// An extra offset to be appended to the viewport's left
    @objc open var extraLeftOffset: CGFloat = 0.0
    
    @objc open func setExtraOffsets(left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat)
    {
        extraLeftOffset = left
        extraTopOffset = top
        extraRightOffset = right
        extraBottomOffset = bottom
    }
    
    // MARK: - Initializers
    
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
        #if os(iOS)
            self.backgroundColor = NSUIColor.clear
        #endif

        _animator = Animator()
        _animator.delegate = self

        _viewPortHandler = ViewPortHandler(width: bounds.size.width, height: bounds.size.height)
        
        chartDescription = Description()
        
        _legend = Legend()
        _legendRenderer = LegendRenderer(viewPortHandler: _viewPortHandler, legend: _legend)
        
        _xAxis = XAxis()
        
        self.addObserver(self, forKeyPath: "bounds", options: .new, context: nil)
        self.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
    }
    
    // MARK: - ChartViewBase
    
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
    @objc open func clear()
    {
        _data = nil
        _offsetsCalculated = false
    
        setNeedsDisplay()
    }
    
    /// Removes all DataSets (and thereby Entries) from the chart. Does not set the data object to nil. Also refreshes the chart by calling setNeedsDisplay().
    @objc open func clearValues()
    {
        _data?.clearValues()
        setNeedsDisplay()
    }

    /// - returns: `true` if the chart is empty (meaning it's data object is either null or contains no entries).
    @objc open func isEmpty() -> Bool
    {
        guard let data = _data else { return true }

        if data.entryCount <= 0
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    /// Lets the chart know its underlying data has changed and should perform all necessary recalculations.
    /// It is crucial that this method is called everytime data is changed dynamically. Not calling this method can lead to crashes or unexpected behaviour.
    @objc open func notifyDataSetChanged()
    {
        fatalError("notifyDataSetChanged() cannot be called on ChartViewBase")
    }
    
    /// Calculates the offsets of the chart to the border depending on the position of an eventual legend or depending on the length of the y-axis and x-axis labels and their position
    internal func calculateOffsets()
    {
        fatalError("calculateOffsets() cannot be called on ChartViewBase")
    }
    
    /// calcualtes the y-min and y-max value and the y-delta and x-delta value
    internal func calcMinMax()
    {
        fatalError("calcMinMax() cannot be called on ChartViewBase")
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
    
    open override func draw(_ rect: CGRect)
    {
        let optionalContext = NSUIGraphicsGetCurrentContext()
        guard let context = optionalContext else { return }
        
        let frame = self.bounds

        if _data === nil && noDataText.count > 0
        {
            context.saveGState()
            defer { context.restoreGState() }

            let paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.minimumLineHeight = noDataFont.lineHeight
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.alignment = noDataTextAlignment

            ChartUtils.drawMultilineText(
                context: context,
                text: noDataText,
                point: CGPoint(x: frame.width / 2.0, y: frame.height / 2.0),
                attributes:
                [.font: noDataFont,
                 .foregroundColor: noDataTextColor,
                 .paragraphStyle: paragraphStyle],
                constrainedToSize: self.bounds.size,
                anchor: CGPoint(x: 0.5, y: 0.5),
                angleRadians: 0.0)
            
            return
        }
        
        if !_offsetsCalculated
        {
            calculateOffsets()
            _offsetsCalculated = true
        }
    }
    
    /// Draws the description text in the bottom right corner of the chart (per default)
    internal func drawDescription(context: CGContext)
    {
        // check if description should be drawn
        guard
            let description = chartDescription,
            description.isEnabled,
            let descriptionText = description.text,
            descriptionText.count > 0
            else { return }
        
        let position = description.position ?? CGPoint(x: bounds.width - _viewPortHandler.offsetRight - description.xOffset,
                                                       y: bounds.height - _viewPortHandler.offsetBottom - description.yOffset - description.font.lineHeight)
        
        var attrs = [NSAttributedStringKey : Any]()
        
        attrs[NSAttributedStringKey.font] = description.font
        attrs[NSAttributedStringKey.foregroundColor] = description.textColor

        ChartUtils.drawText(
            context: context,
            text: descriptionText,
            point: position,
            align: description.textAlign,
            attributes: attrs)
    }
    
    // MARK: - Animation
    
    /// - returns: The animator responsible for animating chart values.
    @objc open var chartAnimator: Animator!
    {
        return _animator
    }
    
    /// Animates the drawing / rendering of the chart on both x- and y-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    /// - parameter xAxisDuration: duration for animating the x axis
    /// - parameter yAxisDuration: duration for animating the y axis
    /// - parameter easingX: an easing function for the animation on the x axis
    /// - parameter easingY: an easing function for the animation on the y axis
    @objc open func animate(xAxisDuration: TimeInterval, yAxisDuration: TimeInterval, easingX: ChartEasingFunctionBlock?, easingY: ChartEasingFunctionBlock?)
    {
        _animator.animate(xAxisDuration: xAxisDuration, yAxisDuration: yAxisDuration, easingX: easingX, easingY: easingY)
    }
    
    /// Animates the drawing / rendering of the chart on both x- and y-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    /// - parameter xAxisDuration: duration for animating the x axis
    /// - parameter yAxisDuration: duration for animating the y axis
    /// - parameter easingOptionX: the easing function for the animation on the x axis
    /// - parameter easingOptionY: the easing function for the animation on the y axis
    @objc open func animate(xAxisDuration: TimeInterval, yAxisDuration: TimeInterval, easingOptionX: ChartEasingOption, easingOptionY: ChartEasingOption)
    {
        _animator.animate(xAxisDuration: xAxisDuration, yAxisDuration: yAxisDuration, easingOptionX: easingOptionX, easingOptionY: easingOptionY)
    }
    
    /// Animates the drawing / rendering of the chart on both x- and y-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    /// - parameter xAxisDuration: duration for animating the x axis
    /// - parameter yAxisDuration: duration for animating the y axis
    /// - parameter easing: an easing function for the animation
    @objc open func animate(xAxisDuration: TimeInterval, yAxisDuration: TimeInterval, easing: ChartEasingFunctionBlock?)
    {
        _animator.animate(xAxisDuration: xAxisDuration, yAxisDuration: yAxisDuration, easing: easing)
    }
    
    /// Animates the drawing / rendering of the chart on both x- and y-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    /// - parameter xAxisDuration: duration for animating the x axis
    /// - parameter yAxisDuration: duration for animating the y axis
    /// - parameter easingOption: the easing function for the animation
    @objc open func animate(xAxisDuration: TimeInterval, yAxisDuration: TimeInterval, easingOption: ChartEasingOption)
    {
        _animator.animate(xAxisDuration: xAxisDuration, yAxisDuration: yAxisDuration, easingOption: easingOption)
    }
    
    /// Animates the drawing / rendering of the chart on both x- and y-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    /// - parameter xAxisDuration: duration for animating the x axis
    /// - parameter yAxisDuration: duration for animating the y axis
    @objc open func animate(xAxisDuration: TimeInterval, yAxisDuration: TimeInterval)
    {
        _animator.animate(xAxisDuration: xAxisDuration, yAxisDuration: yAxisDuration)
    }
    
    /// Animates the drawing / rendering of the chart the x-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    /// - parameter xAxisDuration: duration for animating the x axis
    /// - parameter easing: an easing function for the animation
    @objc open func animate(xAxisDuration: TimeInterval, easing: ChartEasingFunctionBlock?)
    {
        _animator.animate(xAxisDuration: xAxisDuration, easing: easing)
    }
    
    /// Animates the drawing / rendering of the chart the x-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    /// - parameter xAxisDuration: duration for animating the x axis
    /// - parameter easingOption: the easing function for the animation
    @objc open func animate(xAxisDuration: TimeInterval, easingOption: ChartEasingOption)
    {
        _animator.animate(xAxisDuration: xAxisDuration, easingOption: easingOption)
    }
    
    /// Animates the drawing / rendering of the chart the x-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    /// - parameter xAxisDuration: duration for animating the x axis
    @objc open func animate(xAxisDuration: TimeInterval)
    {
        _animator.animate(xAxisDuration: xAxisDuration)
    }
    
    /// Animates the drawing / rendering of the chart the y-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    /// - parameter yAxisDuration: duration for animating the y axis
    /// - parameter easing: an easing function for the animation
    @objc open func animate(yAxisDuration: TimeInterval, easing: ChartEasingFunctionBlock?)
    {
        _animator.animate(yAxisDuration: yAxisDuration, easing: easing)
    }
    
    /// Animates the drawing / rendering of the chart the y-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    /// - parameter yAxisDuration: duration for animating the y axis
    /// - parameter easingOption: the easing function for the animation
    @objc open func animate(yAxisDuration: TimeInterval, easingOption: ChartEasingOption)
    {
        _animator.animate(yAxisDuration: yAxisDuration, easingOption: easingOption)
    }
    
    /// Animates the drawing / rendering of the chart the y-axis with the specified animation time.
    /// If `animate(...)` is called, no further calling of `invalidate()` is necessary to refresh the chart.
    /// - parameter yAxisDuration: duration for animating the y axis
    @objc open func animate(yAxisDuration: TimeInterval)
    {
        _animator.animate(yAxisDuration: yAxisDuration)
    }
    
    // MARK: - Accessors

    /// - returns: The current y-max value across all DataSets
    open var chartYMax: Double
    {
        return _data?.yMax ?? 0.0
    }

    /// - returns: The current y-min value across all DataSets
    open var chartYMin: Double
    {
        return _data?.yMin ?? 0.0
    }
    
    open var chartXMax: Double
    {
        return _xAxis._axisMaximum
    }
    
    open var chartXMin: Double
    {
        return _xAxis._axisMinimum
    }
    
    open var xRange: Double
    {
        return _xAxis.axisRange
    }
    
    /// *
    /// - note: (Equivalent of getCenter() in MPAndroidChart, as center is already a standard in iOS that returns the center point relative to superview, and MPAndroidChart returns relative to self)*
    /// - returns: The center point of the chart (the whole View) in pixels.
    @objc open var midPoint: CGPoint
    {
        let bounds = self.bounds
        return CGPoint(x: bounds.origin.x + bounds.size.width / 2.0, y: bounds.origin.y + bounds.size.height / 2.0)
    }
    
    /// - returns: The center of the chart taking offsets under consideration. (returns the center of the content rectangle)
    open var centerOffsets: CGPoint
    {
        return _viewPortHandler.contentCenter
    }
    
    /// - returns: The Legend object of the chart. This method can be used to get an instance of the legend in order to customize the automatically generated Legend.
    @objc open var legend: Legend
    {
        return _legend
    }
    
    /// - returns: The renderer object responsible for rendering / drawing the Legend.
    @objc open var legendRenderer: LegendRenderer!
    {
        return _legendRenderer
    }
    
    /// - returns: The rectangle that defines the borders of the chart-value surface (into which the actual values are drawn).
    @objc open var contentRect: CGRect
    {
        return _viewPortHandler.contentRect
    }
    
    /// - returns: The ViewPortHandler of the chart that is responsible for the
    /// content area of the chart and its offsets and dimensions.
    @objc open var viewPortHandler: ViewPortHandler!
    {
        return _viewPortHandler
    }
    
    /// - returns: The bitmap that represents the chart.
    @objc open func getChartImage(transparent: Bool) -> NSUIImage?
    {
        NSUIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque || !transparent, NSUIMainScreen()?.nsuiScale ?? 1.0)
        
        guard let context = NSUIGraphicsGetCurrentContext()
            else { return nil }
        
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: bounds.size)
        
        if isOpaque || !transparent
        {
            // Background color may be partially transparent, we must fill with white if we want to output an opaque image
            context.setFillColor(NSUIColor.white.cgColor)
            context.fill(rect)
            
            if let backgroundColor = self.backgroundColor
            {
                context.setFillColor(backgroundColor.cgColor)
                context.fill(rect)
            }
        }
        
        nsuiLayer?.render(in: context)
        
        let image = NSUIGraphicsGetImageFromCurrentImageContext()
        
        NSUIGraphicsEndImageContext()
        
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
        case .png: imageData = NSUIImagePNGRepresentation(image)
        case .jpeg: imageData = NSUIImageJPEGRepresentation(image, CGFloat(compressionQuality))
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
    
    internal var _viewportJobs = [ViewPortJob]()
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
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

                // Finish any pending viewport changes
                while (!_viewportJobs.isEmpty)
                {
                    let job = _viewportJobs.remove(at: 0)
                    job.doJob()
                }
            }
        }
    }
    
    @objc open func removeViewportJob(_ job: ViewPortJob)
    {
        if let index = _viewportJobs.index(where: { $0 === job })
        {
            _viewportJobs.remove(at: index)
        }
    }
    
    @objc open func clearAllViewportJobs()
    {
        _viewportJobs.removeAll(keepingCapacity: false)
    }
    
    @objc open func addViewportJob(_ job: ViewPortJob)
    {
        if _viewPortHandler.hasChartDimens
        {
            job.doJob()
        }
        else
        {
            _viewportJobs.append(job)
        }
    }
    
    /// **default**: true
    /// - returns: `true` if chart continues to scroll after touch up, `false` ifnot.
    @objc open var isDragDecelerationEnabled: Bool
        {
            return dragDecelerationEnabled
    }
    
    /// Deceleration friction coefficient in [0 ; 1] interval, higher values indicate that speed will decrease slowly, for example if it set to 0, it will stop immediately.
    /// 1 is an invalid value, and will be converted to 0.999 automatically.
    /// 
    /// **default**: true
    @objc open var dragDecelerationFrictionCoef: CGFloat
    {
        get
        {
            return _dragDecelerationFrictionCoef
        }
        set
        {
            var val = newValue
            if val < 0.0
            {
                val = 0.0
            }
            if val >= 1.0
            {
                val = 0.999
            }
            
            _dragDecelerationFrictionCoef = val
        }
    }
    
    /// the number of maximum visible drawn values on the chart only active when `drawValuesEnabled` is enabled
    open var maxVisibleCount: Int
    {
        return Int(INT_MAX)
    }
    
    // MARK: - AnimatorDelegate
    
    open func animatorUpdated(_ chartAnimator: Animator)
    {
        setNeedsDisplay()
    }
    
    open func animatorStopped(_ chartAnimator: Animator)
    {
        
    }
    
    // MARK: - Touches
    
    open override func nsuiTouchesBegan(_ touches: Set<NSUITouch>, withEvent event: NSUIEvent?)
    {
        if !_interceptTouchEvents
        {
            super.nsuiTouchesBegan(touches, withEvent: event)
        }
    }
    
    open override func nsuiTouchesMoved(_ touches: Set<NSUITouch>, withEvent event: NSUIEvent?)
    {
        if !_interceptTouchEvents
        {
            super.nsuiTouchesMoved(touches, withEvent: event)
        }
    }
    
    open override func nsuiTouchesEnded(_ touches: Set<NSUITouch>, withEvent event: NSUIEvent?)
    {
        if !_interceptTouchEvents
        {
            super.nsuiTouchesEnded(touches, withEvent: event)
        }
    }
    
    open override func nsuiTouchesCancelled(_ touches: Set<NSUITouch>?, withEvent event: NSUIEvent?)
    {
        if !_interceptTouchEvents
        {
            super.nsuiTouchesCancelled(touches, withEvent: event)
        }
    }
}
