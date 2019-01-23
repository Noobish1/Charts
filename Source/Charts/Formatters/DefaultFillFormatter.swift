//
//  DefaultFillFormatter.swift
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
import UIKit

/// Default formatter that calculates the position of the filled line.
public class DefaultFillFormatter {}

// MARK: FillFormatterPtrotocol
extension DefaultFillFormatter: FillFormatterProtocol {
    public func getFillLinePosition(
        dataSet: LineChartDataSetProtocol,
        dataProvider: LineChartDataProviderProtocol
    ) -> CGFloat {
        var fillMin: CGFloat = 0.0

        if dataSet.yMax > 0.0 && dataSet.yMin < 0.0 {
            fillMin = 0.0
        }
        else if let data = dataProvider.data {
            let max = data.yMax > 0.0 ? 0.0 : dataProvider.chartYMax
            let min = data.yMin < 0.0 ? 0.0 : dataProvider.chartYMin

            fillMin = CGFloat(dataSet.yMin >= 0.0 ? min : max)
        }

        return fillMin
    }
}
