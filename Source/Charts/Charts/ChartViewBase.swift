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
import UIKit

public protocol ChartViewDelegate: AnyObject
{
    /// Called when a value has been selected inside the chart.
    /// - parameter entry: The selected Entry.
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry)
    
    // Called when nothing has been selected or an "un-select" has been made.
    func chartValueNothingSelected(_ chartView: ChartViewBase)
}

open class ChartViewBase: UIView, ChartDataProvider
{
    // MARK: - Properties
    
    /// - returns: The object representing all x-labels, this method can be used to
    /// acquire the XAxis object and modify it (e.g. change the position of the
    /// labels)
    open var xAxis: XAxis
    {
        return _xAxis
    }
    
    /// The default IValueFormatter that has been determined by the chart considering the provided minimum and maximum values.
    internal var _defaultValueFormatter: ValueFormatterProtocol? = DefaultValueFormatter(decimals: 0)
    
    /// object that holds all data that was originally set for the chart, before it was modified or any filtering algorithms had been applied
    internal var _data: ChartData?
    
    /// The object representing the labels on the x-axis
    internal var _xAxis: XAxis!
    
    /// The `Description` object of the chart.
    /// This should have been called just "description", but
    open var chartDescription: Description?
    
    /// delegate to receive chart events
    open weak var delegate: ChartViewDelegate?
    
    /// text that is displayed when the chart is empty
    open var noDataText = "No chart data available."
    
    /// Font to be used for the no data text.
    open var noDataFont: UIFont! = UIFont(name: "HelveticaNeue", size: 12.0)
    
    /// color of the no data text
    open var noDataTextColor: UIColor = UIColor.black

    /// alignment of the no data text
    open var noDataTextAlignment: NSTextAlignment = .left
    
    /// object responsible for rendering the data
    open var renderer: DataRenderer?
    
    /// object that manages the bounds and drawing constraints of the chart
    internal var _viewPortHandler: ViewPortHandler!
    
    /// flag that indicates if offsets calculation has already been done or not
    private var _offsetsCalculated = false
    
    private var _interceptTouchEvents = false
    
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
        self.backgroundColor = UIColor.clear

        _viewPortHandler = ViewPortHandler(width: bounds.size.width, height: bounds.size.height)
        
        chartDescription = Description()
        
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
    open func clear()
    {
        _data = nil
        _offsetsCalculated = false
    
        setNeedsDisplay()
    }
    
    /// Removes all DataSets (and thereby Entries) from the chart. Does not set the data object to nil. Also refreshes the chart by calling setNeedsDisplay().
    open func clearValues()
    {
        _data?.clearValues()
        setNeedsDisplay()
    }

    /// - returns: `true` if the chart is empty (meaning it's data object is either null or contains no entries).
    open func isEmpty() -> Bool
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
    open func notifyDataSetChanged()
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
        let optionalContext = UIGraphicsGetCurrentContext()
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
    open var midPoint: CGPoint
    {
        let bounds = self.bounds
        return CGPoint(x: bounds.origin.x + bounds.size.width / 2.0, y: bounds.origin.y + bounds.size.height / 2.0)
    }
    
    /// - returns: The center of the chart taking offsets under consideration. (returns the center of the content rectangle)
    open var centerOffsets: CGPoint
    {
        return _viewPortHandler.contentCenter
    }
    
    /// - returns: The rectangle that defines the borders of the chart-value surface (into which the actual values are drawn).
    open var contentRect: CGRect
    {
        return _viewPortHandler.contentRect
    }
    
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
            }
        }
    }
    
    /// the number of maximum visible drawn values on the chart only active when `drawValuesEnabled` is enabled
    open var maxVisibleCount: Int
    {
        return Int(INT_MAX)
    }
    
    // MARK: - Touches
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if !_interceptTouchEvents
        {
            super.touchesBegan(touches, with: event)
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if !_interceptTouchEvents
        {
            super.touchesMoved(touches, with: event)
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if !_interceptTouchEvents
        {
            super.touchesEnded(touches, with: event)
        }
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if !_interceptTouchEvents
        {
            super.touchesCancelled(touches, with: event)
        }
    }
}
