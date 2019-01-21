//
//  ChartDataProvider.swift
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

public protocol ChartDataProvider: AnyObject
{
    /// - returns: The minimum x-value of the chart.
    var chartXMin: Double { get }
    
    /// - returns: The maximum x-value of the chart.
    var chartXMax: Double { get }
    
    /// - returns: The minimum y-value of the chart.
    var chartYMin: Double { get }
    
    /// - returns: The maximum y-value of the chart.
    var chartYMax: Double { get }
    
    var xRange: Double { get }
    
    var centerOffsets: CGPoint { get }
    
    var data: ChartData? { get }
    
    var maxVisibleCount: Int { get }
}
