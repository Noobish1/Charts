//
//  ChartDataEntry.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation

// MARK: ChartDataEntry
open class ChartDataEntry {
    public var x: Double
    public var y: Double
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

// MARK: Equatable
extension ChartDataEntry: Equatable {
    public static func == (lhs: ChartDataEntry, rhs: ChartDataEntry) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}
