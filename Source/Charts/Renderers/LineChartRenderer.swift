//
//  LineChartRenderer.swift
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

open class LineChartRenderer: BarLineScatterRendererProtocol
{
    // MARK: properties
    public var viewPortHandler: ViewPortHandler
    internal var _xBounds = XBounds()
    open weak var dataProvider: LineChartDataProvider?
    
    // MARK: init
    public init(dataProvider: LineChartDataProvider, viewPortHandler: ViewPortHandler) {
        self.viewPortHandler = viewPortHandler
        
        self.dataProvider = dataProvider
    }
    
    // MARK: init helpers
    public func initBuffers() {
        // do nothing
    }
    
    // MARK: drawing
    open func drawData(context: CGContext)
    {
        guard let lineData = dataProvider?.lineData else { return }
        
        for i in 0 ..< lineData.dataSetCount
        {
            guard let set = lineData.getDataSetByIndex(i) else { continue }
            
            if set.isVisible
            {
                if !(set is LineChartDataSetProtocol)
                {
                    fatalError("Datasets for LineChartRenderer must conform to ILineChartDataSet")
                }
                
                drawDataSet(context: context, dataSet: set as! LineChartDataSetProtocol)
            }
        }
    }
    
    open func drawDataSet(context: CGContext, dataSet: LineChartDataSetProtocol)
    {
        if dataSet.entryCount < 1
        {
            return
        }
        
        context.saveGState()
        
        context.setLineWidth(dataSet.lineWidth)
        
        // if drawing cubic lines is enabled
        switch dataSet.mode
        {
        case .linear: fallthrough
        case .stepped:
            drawLinear(context: context, dataSet: dataSet)
            
        case .cubicBezier:
            drawCubicBezier(context: context, dataSet: dataSet)
            
        case .horizontalBezier:
            drawHorizontalBezier(context: context, dataSet: dataSet)
        }
        
        context.restoreGState()
    }
    
    open func drawCubicBezier(context: CGContext, dataSet: LineChartDataSetProtocol)
    {
        guard let dataProvider = dataProvider else { return }
        
        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
        
        _xBounds = XBounds(chart: dataProvider, dataSet: dataSet)
        
        // get the color that is specified for this position from the DataSet
        let drawingColor = dataSet.colors.first!
        
        let intensity = dataSet.cubicIntensity
        
        // the path for the cubic-spline
        let cubicPath = CGMutablePath()
        
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        if _xBounds.range >= 1
        {
            var prevDx: CGFloat = 0.0
            var prevDy: CGFloat = 0.0
            var curDx: CGFloat = 0.0
            var curDy: CGFloat = 0.0
            
            // Take an extra point from the left, and an extra from the right.
            // That's because we need 4 points for a cubic bezier (cubic=4), otherwise we get lines moving and doing weird stuff on the edges of the chart.
            // So in the starting `prev` and `cur`, go -2, -1
            // And in the `lastIndex`, add +1
            
            let firstIndex = _xBounds.min + 1
            let lastIndex = _xBounds.min + _xBounds.range
            
            var prevPrev: ChartDataEntry! = nil
            var prev: ChartDataEntry! = dataSet.entryForIndex(max(firstIndex - 2, 0))
            var cur: ChartDataEntry! = dataSet.entryForIndex(max(firstIndex - 1, 0))
            var next: ChartDataEntry! = cur
            var nextIndex: Int = -1
            
            if cur == nil { return }
            
            // let the spline start
            cubicPath.move(to: CGPoint(x: CGFloat(cur.x), y: CGFloat(cur.y)), transform: valueToPixelMatrix)
            
            for j in stride(from: firstIndex, through: lastIndex, by: 1)
            {
                prevPrev = prev
                prev = cur
                cur = nextIndex == j ? next : dataSet.entryForIndex(j)
                
                nextIndex = j + 1 < dataSet.entryCount ? j + 1 : j
                next = dataSet.entryForIndex(nextIndex)
                
                if next == nil { break }
                
                prevDx = CGFloat(cur.x - prevPrev.x) * intensity
                prevDy = CGFloat(cur.y - prevPrev.y) * intensity
                curDx = CGFloat(next.x - prev.x) * intensity
                curDy = CGFloat(next.y - prev.y) * intensity
                
                cubicPath.addCurve(
                    to: CGPoint(
                        x: CGFloat(cur.x),
                        y: CGFloat(cur.y)),
                    control1: CGPoint(
                        x: CGFloat(prev.x) + prevDx,
                        y: (CGFloat(prev.y) + prevDy)),
                    control2: CGPoint(
                        x: CGFloat(cur.x) - curDx,
                        y: (CGFloat(cur.y) - curDy)),
                    transform: valueToPixelMatrix)
            }
        }
        
        context.saveGState()
        
        if dataSet.isDrawFilledEnabled
        {
            // Copy this path because we make changes to it
            let fillPath = cubicPath.mutableCopy()
            
            drawCubicFill(context: context, dataSet: dataSet, spline: fillPath!, matrix: valueToPixelMatrix, bounds: _xBounds)
        }
        
        context.beginPath()
        context.addPath(cubicPath)
        context.setStrokeColor(drawingColor.cgColor)
        context.strokePath()
        
        context.restoreGState()
    }
    
    open func drawHorizontalBezier(context: CGContext, dataSet: LineChartDataSetProtocol)
    {
        guard let dataProvider = dataProvider else { return }
        
        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
        
        _xBounds = XBounds(chart: dataProvider, dataSet: dataSet)
        
        // get the color that is specified for this position from the DataSet
        let drawingColor = dataSet.colors.first!
        
        // the path for the cubic-spline
        let cubicPath = CGMutablePath()
        
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        if _xBounds.range >= 1
        {
            var prev: ChartDataEntry! = dataSet.entryForIndex(_xBounds.min)
            var cur: ChartDataEntry! = prev
            
            if cur == nil { return }
            
            // let the spline start
            cubicPath.move(to: CGPoint(x: CGFloat(cur.x), y: CGFloat(cur.y)), transform: valueToPixelMatrix)
            
            for j in stride(from: (_xBounds.min + 1), through: _xBounds.range + _xBounds.min, by: 1)
            {
                prev = cur
                cur = dataSet.entryForIndex(j)
                
                let cpx = CGFloat(prev.x + (cur.x - prev.x) / 2.0)
                
                cubicPath.addCurve(
                    to: CGPoint(
                        x: CGFloat(cur.x),
                        y: CGFloat(cur.y)),
                    control1: CGPoint(
                        x: cpx,
                        y: CGFloat(prev.y)),
                    control2: CGPoint(
                        x: cpx,
                        y: CGFloat(cur.y)),
                    transform: valueToPixelMatrix)
            }
        }
        
        context.saveGState()
        
        if dataSet.isDrawFilledEnabled
        {
            // Copy this path because we make changes to it
            let fillPath = cubicPath.mutableCopy()
            
            drawCubicFill(context: context, dataSet: dataSet, spline: fillPath!, matrix: valueToPixelMatrix, bounds: _xBounds)
        }
        
        context.beginPath()
        context.addPath(cubicPath)
        context.setStrokeColor(drawingColor.cgColor)
        context.strokePath()
        
        context.restoreGState()
    }
    
    /// Draws the provided path in filled mode with the provided drawable.
    open func drawFilledPath(context: CGContext, path: CGPath, fill: Fill, fillAlpha: CGFloat)
    {
        
        context.saveGState()
        context.beginPath()
        context.addPath(path)
        
        // filled is usually drawn with less alpha
        context.setAlpha(fillAlpha)
        
        fill.fillPath(context: context, rect: viewPortHandler.contentRect)
        
        context.restoreGState()
    }
    
    /// Draws the provided path in filled mode with the provided color and alpha.
    open func drawFilledPath(context: CGContext, path: CGPath, fillColor: UIColor, fillAlpha: CGFloat)
    {
        context.saveGState()
        context.beginPath()
        context.addPath(path)
        
        // filled is usually drawn with less alpha
        context.setAlpha(fillAlpha)
        
        context.setFillColor(fillColor.cgColor)
        context.fillPath()
        
        context.restoreGState()
    }
    
    open func drawCubicFill(
        context: CGContext,
                dataSet: LineChartDataSetProtocol,
                spline: CGMutablePath,
                matrix: CGAffineTransform,
                bounds: XBounds)
    {
        guard
            let dataProvider = dataProvider
            else { return }
        
        if bounds.range <= 0
        {
            return
        }
        
        let fillMin = dataSet.fillFormatter?.getFillLinePosition(dataSet: dataSet, dataProvider: dataProvider) ?? 0.0

        var pt1 = CGPoint(x: CGFloat(dataSet.entryForIndex(bounds.min + bounds.range)?.x ?? 0.0), y: fillMin)
        var pt2 = CGPoint(x: CGFloat(dataSet.entryForIndex(bounds.min)?.x ?? 0.0), y: fillMin)
        pt1 = pt1.applying(matrix)
        pt2 = pt2.applying(matrix)
        
        spline.addLine(to: pt1)
        spline.addLine(to: pt2)
        spline.closeSubpath()
        
        if dataSet.fill == .empty {
            drawFilledPath(
                context: context,
                path: spline,
                fillColor: dataSet.fillColor,
                fillAlpha: dataSet.fillAlpha
            )
        } else {
            drawFilledPath(
                context: context,
                path: spline,
                fill: dataSet.fill,
                fillAlpha: dataSet.fillAlpha
            )
        }
    }
    
    private var _lineSegments = [CGPoint](repeating: CGPoint(), count: 2)
    
    open func drawLinear(context: CGContext, dataSet: LineChartDataSetProtocol)
    {
        guard let dataProvider = dataProvider else { return }
        
        let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
        
        let valueToPixelMatrix = trans.valueToPixelMatrix
        
        let entryCount = dataSet.entryCount
        let isDrawSteppedEnabled = dataSet.mode == .stepped
        let pointsPerEntryPair = isDrawSteppedEnabled ? 4 : 2
        
        _xBounds = XBounds(chart: dataProvider, dataSet: dataSet)
        
        // if drawing filled is enabled
        if dataSet.isDrawFilledEnabled && entryCount > 0
        {
            drawLinearFill(context: context, dataSet: dataSet, trans: trans, bounds: _xBounds)
        }
        
        context.saveGState()
        
        context.setLineCap(dataSet.lineCapType)

        // more than 1 color
        if dataSet.colors.count > 1
        {
            if _lineSegments.count != pointsPerEntryPair
            {
                // Allocate once in correct size
                _lineSegments = [CGPoint](repeating: CGPoint(), count: pointsPerEntryPair)
            }
            
            for j in stride(from: _xBounds.min, through: _xBounds.range + _xBounds.min, by: 1)
            {
                var e: ChartDataEntry! = dataSet.entryForIndex(j)
                
                if e == nil { continue }
                
                _lineSegments[0].x = CGFloat(e.x)
                _lineSegments[0].y = CGFloat(e.y)
                
                if j < _xBounds.max
                {
                    e = dataSet.entryForIndex(j + 1)
                    
                    if e == nil { break }
                    
                    if isDrawSteppedEnabled
                    {
                        _lineSegments[1] = CGPoint(x: CGFloat(e.x), y: _lineSegments[0].y)
                        _lineSegments[2] = _lineSegments[1]
                        _lineSegments[3] = CGPoint(x: CGFloat(e.x), y: CGFloat(e.y))
                    }
                    else
                    {
                        _lineSegments[1] = CGPoint(x: CGFloat(e.x), y: CGFloat(e.y))
                    }
                }
                else
                {
                    _lineSegments[1] = _lineSegments[0]
                }

                for i in 0..<_lineSegments.count
                {
                    _lineSegments[i] = _lineSegments[i].applying(valueToPixelMatrix)
                }
                
                if (!viewPortHandler.isInBoundsRight(_lineSegments[0].x))
                {
                    break
                }
                
                // make sure the lines don't do shitty things outside bounds
                if !viewPortHandler.isInBoundsLeft(_lineSegments[1].x)
                    || (!viewPortHandler.isInBoundsTop(_lineSegments[0].y) && !viewPortHandler.isInBoundsBottom(_lineSegments[1].y))
                {
                    continue
                }
                
                // get the color that is set for this line-segment
                context.setStrokeColor(dataSet.color(atIndex: j).cgColor)
                context.strokeLineSegments(between: _lineSegments)
            }
        }
        else
        { // only one color per dataset
            
            var e1: ChartDataEntry!
            var e2: ChartDataEntry!
            
            e1 = dataSet.entryForIndex(_xBounds.min)
            
            if e1 != nil
            {
                context.beginPath()
                var firstPoint = true
                
                for x in stride(from: _xBounds.min, through: _xBounds.range + _xBounds.min, by: 1)
                {
                    e1 = dataSet.entryForIndex(x == 0 ? 0 : (x - 1))
                    e2 = dataSet.entryForIndex(x)
                    
                    if e1 == nil || e2 == nil { continue }
                    
                    let pt = CGPoint(
                        x: CGFloat(e1.x),
                        y: CGFloat(e1.y)
                        ).applying(valueToPixelMatrix)
                    
                    if firstPoint
                    {
                        context.move(to: pt)
                        firstPoint = false
                    }
                    else
                    {
                        context.addLine(to: pt)
                    }
                    
                    if isDrawSteppedEnabled
                    {
                        context.addLine(to: CGPoint(
                            x: CGFloat(e2.x),
                            y: CGFloat(e1.y)
                            ).applying(valueToPixelMatrix))
                    }
                    
                    context.addLine(to: CGPoint(
                            x: CGFloat(e2.x),
                            y: CGFloat(e2.y)
                        ).applying(valueToPixelMatrix))
                }
                
                if !firstPoint
                {
                    context.setStrokeColor(dataSet.color(atIndex: 0).cgColor)
                    context.strokePath()
                }
            }
        }
        
        context.restoreGState()
    }
    
    open func drawLinearFill(context: CGContext, dataSet: LineChartDataSetProtocol, trans: Transformer, bounds: XBounds)
    {
        guard let dataProvider = dataProvider else { return }
        
        let filled = generateFilledPath(
            dataSet: dataSet,
            fillMin: dataSet.fillFormatter?.getFillLinePosition(dataSet: dataSet, dataProvider: dataProvider) ?? 0.0,
            bounds: bounds,
            matrix: trans.valueToPixelMatrix)
        
        if dataSet.fill == .empty {
            drawFilledPath(
                context: context,
                path: filled,
                fillColor: dataSet.fillColor,
                fillAlpha: dataSet.fillAlpha
            )
        } else {
            drawFilledPath(
                context: context,
                path: filled,
                fill: dataSet.fill,
                fillAlpha: dataSet.fillAlpha
            )
        }
    }
    
    /// Generates the path that is used for filled drawing.
    private func generateFilledPath(dataSet: LineChartDataSetProtocol, fillMin: CGFloat, bounds: XBounds, matrix: CGAffineTransform) -> CGPath
    {
        let isDrawSteppedEnabled = dataSet.mode == .stepped
        let matrix = matrix
        
        var e: ChartDataEntry!
        
        let filled = CGMutablePath()
        
        e = dataSet.entryForIndex(bounds.min)
        if e != nil
        {
            filled.move(to: CGPoint(x: CGFloat(e.x), y: fillMin), transform: matrix)
            filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(e.y)), transform: matrix)
        }
        
        // create a new path
        for x in stride(from: (bounds.min + 1), through: bounds.range + bounds.min, by: 1)
        {
            guard let e = dataSet.entryForIndex(x) else { continue }
            
            if isDrawSteppedEnabled
            {
                guard let ePrev = dataSet.entryForIndex(x-1) else { continue }
                filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(ePrev.y)), transform: matrix)
            }
            
            filled.addLine(to: CGPoint(x: CGFloat(e.x), y: CGFloat(e.y)), transform: matrix)
        }
        
        // close up
        e = dataSet.entryForIndex(bounds.range + bounds.min)
        if e != nil
        {
            filled.addLine(to: CGPoint(x: CGFloat(e.x), y: fillMin), transform: matrix)
        }
        filled.closeSubpath()
        
        return filled
    }
    
    open func drawValues(context: CGContext)
    {
        guard
            let dataProvider = dataProvider,
            let lineData = dataProvider.lineData
            else { return }

        if isDrawingValuesAllowed(dataProvider: dataProvider)
        {
            var dataSets = lineData.dataSets
            
            var pt = CGPoint()
            
            for i in 0 ..< dataSets.count
            {
                guard let dataSet = dataSets[i] as? LineChartDataSetProtocol else { continue }
                
                if !shouldDrawValues(forDataSet: dataSet)
                {
                    continue
                }
                
                let valueFont = dataSet.valueFont
                
                guard let formatter = dataSet.valueFormatter else { continue }
                
                let trans = dataProvider.getTransformer(forAxis: dataSet.axisDependency)
                let valueToPixelMatrix = trans.valueToPixelMatrix
                
                _xBounds = XBounds(chart: dataProvider, dataSet: dataSet)
                
                for j in stride(from: _xBounds.min, through: min(_xBounds.min + _xBounds.range, _xBounds.max), by: 1)
                {
                    guard let e = dataSet.entryForIndex(j) else { break }
                    
                    pt.x = CGFloat(e.x)
                    pt.y = CGFloat(e.y)
                    pt = pt.applying(valueToPixelMatrix)
                    
                    if (!viewPortHandler.isInBoundsRight(pt.x))
                    {
                        break
                    }
                    
                    if (!viewPortHandler.isInBoundsLeft(pt.x) || !viewPortHandler.isInBoundsY(pt.y))
                    {
                        continue
                    }
                    
                    if dataSet.isDrawValuesEnabled {
                        let valueShadow = dataSet.valueShadow
                        
                        ChartUtils.drawText(
                            context: context,
                            text: formatter.stringForValue(
                                e.y,
                                entry: e,
                                dataSetIndex: i,
                                viewPortHandler: viewPortHandler),
                            point: CGPoint(
                                x: pt.x,
                                y: pt.y - valueFont.lineHeight),
                            align: .center,
                            attributes: [NSAttributedStringKey.font: valueFont,
                                         NSAttributedStringKey.foregroundColor: dataSet.valueTextColorAt(j),
                                         NSAttributedStringKey.shadow: valueShadow])
                    }
                }
            }
        }
    }
}
