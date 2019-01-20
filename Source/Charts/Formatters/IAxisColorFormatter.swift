import Foundation

public protocol IAxisColorFormatter: class
{
    func colorForValue(_ value: Double,
                       axis: AxisBase?) -> UIColor
}
