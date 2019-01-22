//
//  IChartDataSet.swift
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

// MARK: ChartDataSetProtocol
public protocol ChartDataSetProtocol: AnyObject
{
    // MARK: - Data functions and accessors
    
    /// Use this method to tell the data set that the underlying data has changed
    func notifyDataSetChanged()
    
    /// Calculates the minimum and maximum x and y values (_xMin, _xMax, _yMin, _yMax).
    func calcMinMax()
    
    /// - returns: The minimum y-value this DataSet holds
    var yMin: Double { get }
    
    /// - returns: The maximum y-value this DataSet holds
    var yMax: Double { get }
    
    /// - returns: The minimum x-value this DataSet holds
    var xMin: Double { get }
    
    /// - returns: The maximum x-value this DataSet holds
    var xMax: Double { get }
    
    /// - returns: The number of y-values this DataSet represents
    var entryCount: Int { get }
    
    /// - returns: The entry object found at the given index (not x-value!)
    /// - throws: out of bounds
    /// if `i` is out of bounds, it may throw an out-of-bounds exception
    func entryForIndex(_ i: Int) -> ChartDataEntry?
    
    /// - returns: The first Entry object found at the given x-value with binary search.
    /// If the no Entry at the specified x-value is found, this method returns the Entry at the closest x-value according to the rounding.
    /// nil if no Entry object at that x-value.
    /// - parameter xValue: the x-value
    /// - parameter closestToY: If there are multiple y-values for the specified x-value,
    /// - parameter rounding: determine whether to round up/down/closest if there is no Entry matching the provided x-value
    func entryForXValue(
        _ xValue: Double,
        closestToY yValue: Double,
        rounding: ChartDataSetRounding) -> ChartDataEntry?
    
    /// - returns: The array-index of the specified entry.
    /// If the no Entry at the specified x-value is found, this method returns the index of the Entry at the closest x-value according to the rounding.
    ///
    /// - parameter xValue: x-value of the entry to search for
    /// - parameter closestToY: If there are multiple y-values for the specified x-value,
    /// - parameter rounding: Rounding method if exact value was not found
    func entryIndex(
        x xValue: Double,
        closestToY yValue: Double,
        rounding: ChartDataSetRounding) -> Int
    
    /// - returns: The array-index of the specified entry
    ///
    /// - parameter e: the entry to search for
    func entryIndex(entry e: ChartDataEntry) -> Int
    
    /// Removes all values from this DataSet and does all necessary recalculations.
    ///
    /// *optional feature, could throw if not implemented*
    func clear()
    
    // MARK: - Styling functions and accessors
    
    /// The axis this DataSet should be plotted against.
    var axisDependency: YAxis.AxisDependency { get }
    
    /// List representing all colors that are used for drawing the actual values for this DataSet
    var valueColors: [UIColor] { get set }
    
    /// All the colors that are used for this DataSet.
    /// Colors are reused as soon as the number of Entries the DataSet represents is higher than the size of the colors array.
    var colors: [UIColor] { get set }
    
    /// - returns: The color at the given index of the DataSet's color array.
    /// This prevents out-of-bounds by performing a modulus on the color index, so colours will repeat themselves.
    func color(atIndex: Int) -> UIColor
    
    func resetColors()
    
    func addColor(_ color: UIColor)
    
    func setColor(_ color: UIColor)
    
    /// Custom formatter that is used instead of the auto-formatter if set
    var valueFormatter: ValueFormatterProtocol? { get set }
    
    /// - returns: `true` if the valueFormatter object of this DataSet is null.
    var needsFormatter: Bool { get }
    
    /// Sets/get a single color for value text.
    /// Setting the color clears the colors array and adds a single color.
    /// Getting will return the first color in the array.
    var valueTextColor: UIColor { get set }
    
    /// - returns: The color at the specified index that is used for drawing the values inside the chart. Uses modulus internally.
    func valueTextColorAt(_ index: Int) -> UIColor
    
    /// the font for the value-text labels
    var valueFont: UIFont { get set }
    
    /// the shadow for the value-text labels
    var valueShadow: NSShadow { get set }
    
    /// - returns: `true` if y-value drawing is enabled, `false` ifnot
    var isDrawValuesEnabled: Bool { get set }
    
    /// - returns: `true` if this DataSet is visible inside the chart, or `false` ifit is currently hidden.
    var isVisible: Bool { get set }
}

// MARK: extensions
public extension ChartDataSetProtocol {
    // MARK: - Data functions and accessors
    
    /// Use this method to tell the data set that the underlying data has changed
    public func notifyDataSetChanged()
    {
        calcMinMax()
    }
    
    // MARK: - Styling functions and accessors
    
    /// - returns: The color at the given index of the DataSet's color array.
    /// This prevents out-of-bounds by performing a modulus on the color index, so colours will repeat themselves.
    public func color(atIndex index: Int) -> UIColor
    {
        var index = index
        if index < 0
        {
            index = 0
        }
        return colors[index % colors.count]
    }
    
    /// Resets all colors of this DataSet and recreates the colors array.
    public func resetColors()
    {
        colors.removeAll(keepingCapacity: false)
    }
    
    /// Adds a new color to the colors array of the DataSet.
    /// - parameter color: the color to add
    public func addColor(_ color: UIColor)
    {
        colors.append(color)
    }
    
    /// Sets the one and **only** color that should be used for this DataSet.
    /// Internally, this recreates the colors array and adds the specified color.
    /// - parameter color: the color to set
    public func setColor(_ color: UIColor)
    {
        colors.removeAll(keepingCapacity: false)
        colors.append(color)
    }
    
    /// Sets colors to a single color a specific alpha value.
    /// - parameter color: the color to set
    /// - parameter alpha: alpha to apply to the set `color`
    public func setColor(_ color: UIColor, alpha: CGFloat)
    {
        setColor(color.withAlphaComponent(alpha))
    }
    
    /// Sets colors with a specific alpha value.
    /// - parameter colors: the colors to set
    /// - parameter alpha: alpha to apply to the set `colors`
    public func setColors(_ colors: [UIColor], alpha: CGFloat)
    {
        var colorsWithAlpha = colors
        
        for i in 0 ..< colorsWithAlpha.count
        {
            colorsWithAlpha[i] = colorsWithAlpha[i] .withAlphaComponent(alpha)
        }
        
        self.colors = colorsWithAlpha
    }
    
    /// Sets colors with a specific alpha value.
    /// - parameter colors: the colors to set
    /// - parameter alpha: alpha to apply to the set `colors`
    public func setColors(_ colors: UIColor...)
    {
        self.colors = colors
    }
    
    /// Sets/get a single color for value text.
    /// Setting the color clears the colors array and adds a single color.
    /// Getting will return the first color in the array.
    public var valueTextColor: UIColor
    {
        get
        {
            return valueColors[0]
        }
        set
        {
            valueColors.removeAll(keepingCapacity: false)
            valueColors.append(newValue)
        }
    }
    
    /// - returns: The color at the specified index that is used for drawing the values inside the chart. Uses modulus internally.
    public func valueTextColorAt(_ index: Int) -> UIColor
    {
        var index = index
        if index < 0
        {
            index = 0
        }
        return valueColors[index % valueColors.count]
    }
}
