//
//  CombinedChartRenderer.swift
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

open class CombinedChartRenderer: DataRenderer
{
    open weak var chart: CombinedChartView?
    public var viewPortHandler: ViewPortHandler
    
    internal var _renderers = [DataRenderer]()
    
    internal var _drawOrder: [CombinedChartView.DrawOrder] = [.line, .scatter]
    
    public init(chart: CombinedChartView, viewPortHandler: ViewPortHandler)
    {
        self.viewPortHandler = viewPortHandler
        self.chart = chart
        
        createRenderers()
    }
    
    /// Creates the renderers needed for this combined-renderer in the required order. Also takes the DrawOrder into consideration.
    internal func createRenderers()
    {
        _renderers = [DataRenderer]()
        
        guard let chart = chart else { return }

        for order in drawOrder
        {
            switch (order)
            {
            case .line:
                if chart.lineData !== nil
                {
                    _renderers.append(LineChartRenderer(dataProvider: chart, viewPortHandler: viewPortHandler))
                }
                break
            case .scatter:
                if chart.scatterData !== nil
                {
                    _renderers.append(ScatterChartRenderer(dataProvider: chart, viewPortHandler: viewPortHandler))
                }
                break
            }
        }

    }
    
    open func initBuffers()
    {
        for renderer in _renderers
        {
            renderer.initBuffers()
        }
    }
    
    open func drawData(context: CGContext)
    {
        for renderer in _renderers
        {
            renderer.drawData(context: context)
        }
    }
    
    open func drawValues(context: CGContext)
    {
        for renderer in _renderers
        {
            renderer.drawValues(context: context)
        }
    }

    /// - returns: The sub-renderer object at the specified index.
    open func getSubRenderer(index: Int) -> DataRenderer?
    {
        if index >= _renderers.count || index < 0
        {
            return nil
        }
        else
        {
            return _renderers[index]
        }
    }

    /// - returns: All sub-renderers.
    open var subRenderers: [DataRenderer]
    {
        get { return _renderers }
        set { _renderers = newValue }
    }
    
    // MARK: Accessors
    
    /// the order in which the provided data objects should be drawn.
    /// The earlier you place them in the provided array, the further they will be in the background.
    /// e.g. if you provide [DrawOrder.Bar, DrawOrder.Line], the bars will be drawn behind the lines.
    open var drawOrder: [CombinedChartView.DrawOrder]
    {
        get
        {
            return _drawOrder
        }
        set
        {
            if newValue.count > 0
            {
                _drawOrder = newValue
            }
        }
    }
}
