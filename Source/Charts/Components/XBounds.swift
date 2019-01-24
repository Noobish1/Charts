//
//  XBounds.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//
import Foundation

/// Class representing the bounds of the current viewport in terms of indices in the values array of a DataSet.
public struct XBounds {
    // MARK: properties
    public let min: Int
    public let max: Int
    public let range: Int
    
    // MARK: init
    public init() {
        self.min = 0
        self.max = 0
        self.range = 0
    }
    
    public init(
        chart: BarLineScatterChartDataProviderProtocol,
        dataSet: ChartDataSetProtocol
    ) {
        let entryFrom = dataSet.entryForXValue(
            chart.lowestVisibleX,
            closestToY: .nan,
            rounding: .down
        )
        let entryTo = dataSet.entryForXValue(
            chart.highestVisibleX,
            closestToY: .nan,
            rounding: .up
        )
        
        self.min = entryFrom == nil ? 0 : dataSet.entryIndex(entry: entryFrom!)
        self.max = entryTo == nil ? 0 : dataSet.entryIndex(entry: entryTo!)
        self.range = Int(Double(self.max - self.min))
    }
}
