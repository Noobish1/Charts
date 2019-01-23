//
//  CombinedChartView.swift
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

/// This chart class allows the combination of lines, bars, scatter and candle data all displayed in one chart area.
open class CombinedChartView: BarLineChartViewBase, CombinedChartDataProviderProtocol
{
    /// the fill-formatter used for determining the position of the fill-line
    open var fillFormatter: FillFormatterProtocol = DefaultFillFormatter()
    
    /// enum that allows to specify the order in which the different data objects for the combined-chart are drawn
    public enum DrawOrder: Int
    {
        case line
        case scatter
    }
    
    open override func initialize()
    {
        super.initialize()
        
        renderer = CombinedChartRenderer(chart: self, viewPortHandler: _viewPortHandler)
    }
    
    open override var data: ChartData?
    {
        get
        {
            return super.data
        }
        set
        {
            super.data = newValue
            
            (renderer as? CombinedChartRenderer)?.createRenderers()
            renderer?.initBuffers()
        }
    }
    
    // MARK: - CombinedChartDataProvider
    
    open var combinedData: CombinedChartData?
    {
        get
        {
            return _data as? CombinedChartData
        }
    }
    
    // MARK: - LineChartDataProvider
    
    open var lineData: LineChartData?
    {
        get
        {
            return combinedData?.lineData
        }
    }
    
    // MARK: - ScatterChartDataProvider
    
    open var scatterData: ScatterChartData?
    {
        get
        {
            return combinedData?.scatterData
        }
    }
    
    // MARK: - Accessors
    
    /// the order in which the provided data objects should be drawn.
    /// The earlier you place them in the provided array, the further they will be in the background. 
    /// e.g. if you provide [DrawOrder.Bar, DrawOrder.Line], the bars will be drawn behind the lines.
    open var drawOrder: [Int]
    {
        get
        {
            return (renderer as! CombinedChartRenderer).drawOrder.map { $0.rawValue }
        }
        set
        {
            (renderer as! CombinedChartRenderer).drawOrder = newValue.map { DrawOrder(rawValue: $0)! }
        }
    }
}
