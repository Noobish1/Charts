//
//  ChartData.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation

open class ChartData
{
    internal var _yMax: Double = -Double.greatestFiniteMagnitude
    internal var _yMin: Double = Double.greatestFiniteMagnitude
    internal var _xMax: Double = -Double.greatestFiniteMagnitude
    internal var _xMin: Double = Double.greatestFiniteMagnitude
    internal var _leftAxisMax: Double = -Double.greatestFiniteMagnitude
    internal var _leftAxisMin: Double = Double.greatestFiniteMagnitude
    internal var _rightAxisMax: Double = -Double.greatestFiniteMagnitude
    internal var _rightAxisMin: Double = Double.greatestFiniteMagnitude
    
    internal var _dataSets: [ChartDataSetProtocol]
    
    public init(dataSets: [ChartDataSetProtocol] = [])
    {
        self._dataSets = dataSets
        
        notifyDataChanged()
    }
    
    /// Call this method to let the ChartData know that the underlying data has changed.
    /// Calling this performs all necessary recalculations needed when the contained data has changed.
    open func notifyDataChanged()
    {
        calcMinMax()
    }
    
    /// calc minimum and maximum y value over all datasets
    open func calcMinMax()
    {
        _yMax = -Double.greatestFiniteMagnitude
        _yMin = Double.greatestFiniteMagnitude
        _xMax = -Double.greatestFiniteMagnitude
        _xMin = Double.greatestFiniteMagnitude
        
        for set in _dataSets
        {
            calcMinMax(dataSet: set)
        }
        
        _leftAxisMax = -Double.greatestFiniteMagnitude
        _leftAxisMin = Double.greatestFiniteMagnitude
        _rightAxisMax = -Double.greatestFiniteMagnitude
        _rightAxisMin = Double.greatestFiniteMagnitude
        
        // left axis
        let firstLeft = getFirstLeft(dataSets: dataSets)
        
        if firstLeft !== nil
        {
            _leftAxisMax = firstLeft!.yMax
            _leftAxisMin = firstLeft!.yMin
            
            for dataSet in _dataSets
            {
                if dataSet.axisDependency == .left
                {
                    if dataSet.yMin < _leftAxisMin
                    {
                        _leftAxisMin = dataSet.yMin
                    }
                    
                    if dataSet.yMax > _leftAxisMax
                    {
                        _leftAxisMax = dataSet.yMax
                    }
                }
            }
        }
        
        // right axis
        let firstRight = getFirstRight(dataSets: dataSets)
        
        if firstRight !== nil
        {
            _rightAxisMax = firstRight!.yMax
            _rightAxisMin = firstRight!.yMin
            
            for dataSet in _dataSets
            {
                if dataSet.axisDependency == .right
                {
                    if dataSet.yMin < _rightAxisMin
                    {
                        _rightAxisMin = dataSet.yMin
                    }
                    
                    if dataSet.yMax > _rightAxisMax
                    {
                        _rightAxisMax = dataSet.yMax
                    }
                }
            }
        }
    }
    
    /// Adjusts the minimum and maximum values based on the given DataSet.
    open func calcMinMax(dataSet d: ChartDataSetProtocol)
    {
        if _yMax < d.yMax
        {
            _yMax = d.yMax
        }
        
        if _yMin > d.yMin
        {
            _yMin = d.yMin
        }
        
        if _xMax < d.xMax
        {
            _xMax = d.xMax
        }
        
        if _xMin > d.xMin
        {
            _xMin = d.xMin
        }
        
        if d.axisDependency == .left
        {
            if _leftAxisMax < d.yMax
            {
                _leftAxisMax = d.yMax
            }
            
            if _leftAxisMin > d.yMin
            {
                _leftAxisMin = d.yMin
            }
        }
        else
        {
            if _rightAxisMax < d.yMax
            {
                _rightAxisMax = d.yMax
            }
            
            if _rightAxisMin > d.yMin
            {
                _rightAxisMin = d.yMin
            }
        }
    }
    
    /// - returns: The number of LineDataSets this object contains
    open var dataSetCount: Int
    {
        return _dataSets.count
    }
    
    /// - returns: The smallest y-value the data object contains.
    open var yMin: Double
    {
        return _yMin
    }
    
    @nonobjc
    open func getYMin() -> Double
    {
        return _yMin
    }
    
    open func getYMin(axis: YAxis.AxisDependency) -> Double
    {
        if axis == .left
        {
            if _leftAxisMin == Double.greatestFiniteMagnitude
            {
                return _rightAxisMin
            }
            else
            {
                return _leftAxisMin
            }
        }
        else
        {
            if _rightAxisMin == Double.greatestFiniteMagnitude
            {
                return _leftAxisMin
            }
            else
            {
                return _rightAxisMin
            }
        }
    }
    
    /// - returns: The greatest y-value the data object contains.
    open var yMax: Double
    {
        return _yMax
    }
    
    @nonobjc
    open func getYMax() -> Double
    {
        return _yMax
    }
    
    open func getYMax(axis: YAxis.AxisDependency) -> Double
    {
        if axis == .left
        {
            if _leftAxisMax == -Double.greatestFiniteMagnitude
            {
                return _rightAxisMax
            }
            else
            {
                return _leftAxisMax
            }
        }
        else
        {
            if _rightAxisMax == -Double.greatestFiniteMagnitude
            {
                return _leftAxisMax
            }
            else
            {
                return _rightAxisMax
            }
        }
    }
    
    /// - returns: The minimum x-value the data object contains.
    open var xMin: Double
    {
        return _xMin
    }
    /// - returns: The maximum x-value the data object contains.
    open var xMax: Double
    {
        return _xMax
    }
    
    /// - returns: All DataSet objects this ChartData object holds.
    open var dataSets: [ChartDataSetProtocol]
    {
        get
        {
            return _dataSets
        }
        set
        {
            _dataSets = newValue
            notifyDataChanged()
        }
    }
    
    open func getDataSetByIndex(_ index: Int) -> ChartDataSetProtocol!
    {
        if index < 0 || index >= _dataSets.count
        {
            return nil
        }
        
        return _dataSets[index]
    }
    
    /// - returns: The first DataSet from the datasets-array that has it's dependency on the left axis. Returns null if no DataSet with left dependency could be found.
    open func getFirstLeft(dataSets: [ChartDataSetProtocol]) -> ChartDataSetProtocol?
    {
        for dataSet in dataSets
        {
            if dataSet.axisDependency == .left
            {
                return dataSet
            }
        }
        
        return nil
    }
    
    /// - returns: The first DataSet from the datasets-array that has it's dependency on the right axis. Returns null if no DataSet with right dependency could be found.
    open func getFirstRight(dataSets: [ChartDataSetProtocol]) -> ChartDataSetProtocol?
    {
        for dataSet in _dataSets
        {
            if dataSet.axisDependency == .right
            {
                return dataSet
            }
        }
        
        return nil
    }
    
    /// - returns: The total entry count across all DataSet objects this data object contains.
    open var entryCount: Int
    {
        var count = 0
        
        for set in _dataSets
        {
            count += set.entryCount
        }
        
        return count
    }
}
