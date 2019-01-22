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

internal protocol BarLineScatterRendererProtocol: DataRenderer
{
    // MARK: properties
    var _xBounds: XBounds { get set } // Reusable XBounds object
}

internal extension BarLineScatterRendererProtocol {
    /// - returns: `true` if the DataSet values should be drawn, `false` if not.
    internal func shouldDrawValues(forDataSet set: ChartDataSetProtocol) -> Bool {
        return set.isVisible && set.isDrawValuesEnabled
    }
}
