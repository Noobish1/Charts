import Foundation

public protocol AxisColorFormatterProtocol: class
{
    func colorForValue(_ value: Double,
                       axis: AxisBase?) -> UIColor
}
