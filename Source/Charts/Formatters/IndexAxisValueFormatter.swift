//
//  IndexAxisValueFormatter.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation

/// This formatter is used for passing an array of x-axis labels, on whole x steps.
open class IndexAxisValueFormatter: NSObject, AxisValueFormatterProtocol
{    
    private var _values: [String] = [String]()
    private var _valueCount: Int = 0
    
    public var values: [String]
    {
        get
        {
            return _values
        }
        set
        {
            _values = newValue
            _valueCount = _values.count
        }
    }
    
    public override init()
    {
        super.init()
        
    }
    
    public init(values: [String])
    {
        super.init()
        
        self.values = values
    }
    
    open func stringForValue(_ value: Double,
                             axis: AxisBase?) -> String
    {
        let index = Int(value.rounded())
        guard values.indices.contains(index), index == Int(value) else { return "" }
        return _values[index]
    }
}
