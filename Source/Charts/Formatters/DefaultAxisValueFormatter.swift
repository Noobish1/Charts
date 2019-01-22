//
//  DefaultAxisValueFormatter.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation

open class DefaultAxisValueFormatter {
    // MARK: properties
    open var hasAutoDecimals: Bool
    open var formatter: NumberFormatter {
        didSet {
            hasAutoDecimals = false
        }
    }
    open var decimals: Int {
        didSet {
            self.formatter.minimumFractionDigits = decimals
            self.formatter.maximumFractionDigits = decimals
            self.formatter.usesGroupingSeparator = true
        }
    }
    
    // MARK: init
    public init(decimals: Int) {
        self.decimals = decimals
        self.formatter = NumberFormatter()
        self.formatter.usesGroupingSeparator = true
        self.hasAutoDecimals = true
    }
}

// MARK: AxisValueFormatterProtocol
extension DefaultAxisValueFormatter: AxisValueFormatterProtocol {
    open func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return formatter.string(from: NSNumber(floatLiteral: value)) ?? ""
    }
}
