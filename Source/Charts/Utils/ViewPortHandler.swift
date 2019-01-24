//
//  ViewPortHandler.swift
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

/// Class that contains information about the charts current viewport settings, including offsets, scale & translation levels, ...
open class ViewPortHandler {
    /// matrix used for touch events
    private var _touchMatrix = CGAffineTransform.identity
    
    /// this rectangle defines the area in which graph values can be drawn
    private var _contentRect = CGRect()
    
    private var _chartWidth = CGFloat(0.0)
    private var _chartHeight = CGFloat(0.0)
    
    /// Constructor - don't forget calling setChartDimens(...)
    public init(width: CGFloat, height: CGFloat)
    {
        setChartDimens(width: width, height: height)
    }
    
    open func setChartDimens(width: CGFloat, height: CGFloat)
    {
        let offsetLeft = self.offsetLeft
        let offsetTop = self.offsetTop
        let offsetRight = self.offsetRight
        let offsetBottom = self.offsetBottom
        
        _chartHeight = height
        _chartWidth = width
        
        restrainViewPort(offsetLeft: offsetLeft, offsetTop: offsetTop, offsetRight: offsetRight, offsetBottom: offsetBottom)
    }

    open func restrainViewPort(offsetLeft: CGFloat, offsetTop: CGFloat, offsetRight: CGFloat, offsetBottom: CGFloat)
    {
        _contentRect.origin.x = offsetLeft
        _contentRect.origin.y = offsetTop
        _contentRect.size.width = _chartWidth - offsetLeft - offsetRight
        _contentRect.size.height = _chartHeight - offsetBottom - offsetTop
    }
    
    open var offsetLeft: CGFloat
    {
        return _contentRect.origin.x
    }
    
    open var offsetRight: CGFloat
    {
        return _chartWidth - _contentRect.size.width - _contentRect.origin.x
    }
    
    open var offsetTop: CGFloat
    {
        return _contentRect.origin.y
    }
    
    open var offsetBottom: CGFloat
    {
        return _chartHeight - _contentRect.size.height - _contentRect.origin.y
    }
    
    open var contentTop: CGFloat
    {
        return _contentRect.origin.y
    }
    
    open var contentLeft: CGFloat
    {
        return _contentRect.origin.x
    }
    
    open var contentRight: CGFloat
    {
        return _contentRect.origin.x + _contentRect.size.width
    }
    
    open var contentBottom: CGFloat
    {
        return _contentRect.origin.y + _contentRect.size.height
    }
    
    open var contentWidth: CGFloat
    {
        return _contentRect.size.width
    }
    
    open var contentHeight: CGFloat
    {
        return _contentRect.size.height
    }
    
    open var contentRect: CGRect
    {
        return _contentRect
    }
    
    open var chartHeight: CGFloat
    { 
        return _chartHeight
    }
    
    open var chartWidth: CGFloat
    { 
        return _chartWidth
    }

    // MARK: - Scaling/Panning etc.
    
    /// Centers the viewport around the specified position (x-index and y-value) in the chart.
    /// Centering the viewport outside the bounds of the chart is not possible.
    /// Makes most sense in combination with the setScaleMinima(...) method.
    open func centerViewPort(pt: CGPoint, chart: BarLineChartViewBase)
    {
        let translateX = pt.x - offsetLeft
        let translateY = pt.y - offsetTop
        
        let matrix = _touchMatrix.concatenating(CGAffineTransform(translationX: -translateX, y: -translateY))
        refresh(newMatrix: matrix, chart: chart)
    }
    
    /// call this method to refresh the graph with a given matrix
     @discardableResult open func refresh(newMatrix: CGAffineTransform, chart: BarLineChartViewBase) -> CGAffineTransform
    {
        _touchMatrix = newMatrix
        
        chart.setNeedsDisplay()
        
        return _touchMatrix
    }

    open var touchMatrix: CGAffineTransform
    {
        return _touchMatrix
    }
    
    // MARK: - Boundaries Check
    
    open func isInBoundsX(_ x: CGFloat) -> Bool
    {
        return isInBoundsLeft(x) && isInBoundsRight(x)
    }
    
    open func isInBoundsY(_ y: CGFloat) -> Bool
    {
        return isInBoundsTop(y) && isInBoundsBottom(y)
    }
    
    open func isInBoundsLeft(_ x: CGFloat) -> Bool
    {
        return _contentRect.origin.x <= x + 1.0
    }
    
    open func isInBoundsRight(_ x: CGFloat) -> Bool
    {
        let x = floor(x * 100.0) / 100.0
        return (_contentRect.origin.x + _contentRect.size.width) >= x - 1.0
    }
    
    open func isInBoundsTop(_ y: CGFloat) -> Bool
    {
        return _contentRect.origin.y <= y
    }
    
    open func isInBoundsBottom(_ y: CGFloat) -> Bool
    {
        let normalizedY = floor(y * 100.0) / 100.0
        return (_contentRect.origin.y + _contentRect.size.height) >= normalizedY
    }
}
