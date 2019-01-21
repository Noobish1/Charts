//
//  BarLineScatterCandleBubbleRenderer.swift
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

open class BarLineScatterCandleBubbleRenderer: DataRenderer
{
    internal var _xBounds = XBounds() // Reusable XBounds object
    
    public override init(viewPortHandler: ViewPortHandler)
    {
        super.init(viewPortHandler: viewPortHandler)
    }
    
    /// - returns: `true` if the DataSet values should be drawn, `false` if not.
    internal func shouldDrawValues(forDataSet set: ChartDataSetProtocol) -> Bool
    {
        return set.isVisible && (set.isDrawValuesEnabled || set.isDrawIconsEnabled)
    }

    /// Class representing the bounds of the current viewport in terms of indices in the values array of a DataSet.
    open class XBounds
    {
        /// minimum visible entry index
        open var min: Int = 0

        /// maximum visible entry index
        open var max: Int = 0

        /// range of visible entry indices
        open var range: Int = 0

        public init()
        {
            
        }
        
        public init(chart: BarLineScatterCandleBubbleChartDataProvider,
                    dataSet: ChartDataSetProtocol)
        {
            self.set(chart: chart, dataSet: dataSet)
        }
        
        /// Calculates the minimum and maximum x values as well as the range between them.
        open func set(chart: BarLineScatterCandleBubbleChartDataProvider,
                      dataSet: ChartDataSetProtocol)
        {
            let phaseX = Swift.max(0.0, 1.0)
            
            let low = chart.lowestVisibleX
            let high = chart.highestVisibleX
            
            let entryFrom = dataSet.entryForXValue(low, closestToY: Double.nan, rounding: ChartDataSetRounding.down)
            let entryTo = dataSet.entryForXValue(high, closestToY: Double.nan, rounding: ChartDataSetRounding.up)
            
            self.min = entryFrom == nil ? 0 : dataSet.entryIndex(entry: entryFrom!)
            self.max = entryTo == nil ? 0 : dataSet.entryIndex(entry: entryTo!)
            range = Int(Double(self.max - self.min) * phaseX)
        }
    }
}
