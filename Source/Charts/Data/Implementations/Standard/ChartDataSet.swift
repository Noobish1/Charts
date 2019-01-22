//
//  ChartDataSet.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation

/// Determines how to round DataSet index values for `ChartDataSet.entryIndex(x, rounding)` when an exact x-value is not found.
public enum ChartDataSetRounding: Int
{
    case up = 0
    case down = 1
    case closest = 2
}

/// The DataSet class represents one group or type of entries (Entry) in the Chart that belong together.
/// It is designed to logically separate different groups of values inside the Chart (e.g. the values for a specific line in the LineChart, or the values of a specific group of bars in the BarChart).
open class ChartDataSet: ChartDataSetProtocol
{        
    // MARK: - Styling functions and accessors
    
    /// All the colors that are used for this DataSet.
    /// Colors are reused as soon as the number of Entries the DataSet represents is higher than the size of the colors array.
    open var colors: [UIColor] = []
    
    /// List representing all colors that are used for drawing the actual values for this DataSet
    open var valueColors: [UIColor] = []
    
    /// The axis this DataSet should be plotted against.
    open var axisDependency = YAxis.AxisDependency.left
    
    /// Custom formatter that is used instead of the auto-formatter if set
    internal var _valueFormatter: ValueFormatterProtocol?
    
    /// Custom formatter that is used instead of the auto-formatter if set
    open var valueFormatter: ValueFormatterProtocol?
    {
        get
        {
            if needsFormatter
            {
                return ChartUtils.defaultValueFormatter()
            }
            
            return _valueFormatter
        }
        set
        {
            if newValue == nil { return }
            
            _valueFormatter = newValue
        }
    }
    
    open var needsFormatter: Bool
    {
        return _valueFormatter == nil
    }
    
    /// the font for the value-text labels
    open var valueFont: UIFont = UIFont.systemFont(ofSize: 7.0)
    
    /// the shadow for the value-text labels
    open var valueShadow = NSShadow()
    
    /// Set this to true to draw y-values on the chart.
    ///
    /// - note: For bar and line charts: if `maxVisibleCount` is reached, no values will be drawn even if this is enabled.
    open var isDrawValuesEnabled = true
    
    /// Set the visibility of this DataSet. If not visible, the DataSet will not be drawn to the chart upon refreshing it.
    open var isVisible = true
    
    // MARK: init
    public init(values: [ChartDataEntry] = [])
    {
        self.values = values

        // default colors
        colors.append(UIColor(red: 140.0/255.0, green: 234.0/255.0, blue: 255.0/255.0, alpha: 1.0))
        valueColors.append(UIColor.black)
        
        self.calcMinMax()
    }
    
    // MARK: - Data functions and accessors

    /// *
    /// - note: Calls `notifyDataSetChanged()` after setting a new value.
    /// - returns: The array of y-values that this DataSet represents.
    /// the entries that this dataset represents / holds together
    open var values: [ChartDataEntry]
        {
        didSet
        {
            if isIndirectValuesCall {
                isIndirectValuesCall = false
                return
            }
            notifyDataSetChanged()
        }
    }
    // TODO: Temporary fix for performance. Will be removed in 4.0
    private var isIndirectValuesCall = false

    /// maximum y-value in the value array
    internal var _yMax: Double = -Double.greatestFiniteMagnitude
    
    /// minimum y-value in the value array
    internal var _yMin: Double = Double.greatestFiniteMagnitude
    
    /// maximum x-value in the value array
    internal var _xMax: Double = -Double.greatestFiniteMagnitude
    
    /// minimum x-value in the value array
    internal var _xMin: Double = Double.greatestFiniteMagnitude
    
    open func calcMinMax()
    {
        _yMax = -Double.greatestFiniteMagnitude
        _yMin = Double.greatestFiniteMagnitude
        _xMax = -Double.greatestFiniteMagnitude
        _xMin = Double.greatestFiniteMagnitude

        guard !values.isEmpty else { return }

        values.forEach { calcMinMax(entry: $0) }
    }
    
    open func calcMinMaxX(entry e: ChartDataEntry)
    {
        if e.x < _xMin
        {
            _xMin = e.x
        }
        if e.x > _xMax
        {
            _xMax = e.x
        }
    }
    
    open func calcMinMaxY(entry e: ChartDataEntry)
    {
        if e.y < _yMin
        {
            _yMin = e.y
        }
        if e.y > _yMax
        {
            _yMax = e.y
        }
    }
    
    /// Updates the min and max x and y value of this DataSet based on the given Entry.
    ///
    /// - parameter e:
    internal func calcMinMax(entry e: ChartDataEntry)
    {
        calcMinMaxX(entry: e)
        calcMinMaxY(entry: e)
    }
    
    /// - returns: The minimum y-value this DataSet holds
    open var yMin: Double { return _yMin }
    
    /// - returns: The maximum y-value this DataSet holds
    open var yMax: Double { return _yMax }
    
    /// - returns: The minimum x-value this DataSet holds
    open var xMin: Double { return _xMin }
    
    /// - returns: The maximum x-value this DataSet holds
    open var xMax: Double { return _xMax }
    
    /// - returns: The number of y-values this DataSet represents
    open var entryCount: Int { return values.count }
    
    /// - returns: The entry object found at the given index (not x-value!)
    /// - throws: out of bounds
    /// if `i` is out of bounds, it may throw an out-of-bounds exception
    open func entryForIndex(_ i: Int) -> ChartDataEntry?
    {
        guard i >= values.startIndex, i < values.endIndex else {
            return nil
        }
        return values[i]
    }
    
    /// - returns: The first Entry object found at the given x-value with binary search.
    /// If the no Entry at the specified x-value is found, this method returns the Entry at the closest x-value according to the rounding.
    /// nil if no Entry object at that x-value.
    /// - parameter xValue: the x-value
    /// - parameter closestToY: If there are multiple y-values for the specified x-value,
    /// - parameter rounding: determine whether to round up/down/closest if there is no Entry matching the provided x-value
    open func entryForXValue(
        _ xValue: Double,
        closestToY yValue: Double,
        rounding: ChartDataSetRounding) -> ChartDataEntry?
    {
        let index = entryIndex(x: xValue, closestToY: yValue, rounding: rounding)
        if index > -1
        {
            return values[index]
        }
        return nil
    }
    
    /// - returns: The array-index of the specified entry.
    /// If the no Entry at the specified x-value is found, this method returns the index of the Entry at the closest x-value according to the rounding.
    ///
    /// - parameter xValue: x-value of the entry to search for
    /// - parameter closestToY: If there are multiple y-values for the specified x-value,
    /// - parameter rounding: Rounding method if exact value was not found
    open func entryIndex(
        x xValue: Double,
        closestToY yValue: Double,
        rounding: ChartDataSetRounding) -> Int
    {
        var low = values.startIndex
        var high = values.endIndex - 1
        var closest = high
        
        while low < high
        {
            let m = (low + high) / 2
            
            let d1 = values[m].x - xValue
            let d2 = values[m + 1].x - xValue
            let ad1 = abs(d1), ad2 = abs(d2)
            
            if ad2 < ad1
            {
                // [m + 1] is closer to xValue
                // Search in an higher place
                low = m + 1
            }
            else if ad1 < ad2
            {
                // [m] is closer to xValue
                // Search in a lower place
                high = m
            }
            else
            {
                // We have multiple sequential x-value with same distance
                
                if d1 >= 0.0
                {
                    // Search in a lower place
                    high = m
                }
                else if d1 < 0.0
                {
                    // Search in an higher place
                    low = m + 1
                }
            }
            
            closest = high
        }
        
        if closest != -1
        {
            let closestXValue = values[closest].x
            
            if rounding == .up
            {
                // If rounding up, and found x-value is lower than specified x, and we can go upper...
                if closestXValue < xValue && closest < values.endIndex - 1
                {
                    closest += 1
                }
            }
            else if rounding == .down
            {
                // If rounding down, and found x-value is upper than specified x, and we can go lower...
                if closestXValue > xValue && closest > 0
                {
                    closest -= 1
                }
            }
            
            // Search by closest to y-value
            if !yValue.isNaN
            {
                while closest > 0 && values[closest - 1].x == closestXValue
                {
                    closest -= 1
                }
                
                var closestYValue = values[closest].y
                var closestYIndex = closest
                
                while true
                {
                    closest += 1
                    if closest >= values.endIndex { break }
                    
                    let value = values[closest]
                    
                    if value.x != closestXValue { break }
                    if abs(value.y - yValue) < abs(closestYValue - yValue)
                    {
                        closestYValue = yValue
                        closestYIndex = closest
                    }
                }
                
                closest = closestYIndex
            }
        }
        
        return closest
    }
    
    /// - returns: The array-index of the specified entry
    ///
    /// - parameter e: the entry to search for
    open func entryIndex(entry e: ChartDataEntry) -> Int
    {
        for i in 0 ..< values.count
        {
            if values[i] == e
            {
                return i
            }
        }
        
        return -1
    }
    
    /// Removes all values from this DataSet and recalculates min and max value.
    open func clear()
    {
        values.removeAll(keepingCapacity: true)
    }
}
