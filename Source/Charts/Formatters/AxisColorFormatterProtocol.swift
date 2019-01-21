import Foundation

public protocol AxisColorFormatterProtocol: AnyObject
{
    func colorForValue(_ value: Double,
                       axis: AxisBase?) -> UIColor
}
