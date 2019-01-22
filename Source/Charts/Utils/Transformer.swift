//
//  Transformer.swift
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

/// Transformer class that contains all matrices and is responsible for transforming values into pixels on the screen and backwards.
open class Transformer
{
    /// matrix to map the values to the screen pixels
    internal var _matrixValueToPx = CGAffineTransform.identity

    /// matrix for handling the different offsets of the chart
    internal var _matrixOffset = CGAffineTransform.identity

    internal var _viewPortHandler: ViewPortHandler

    public init(viewPortHandler: ViewPortHandler)
    {
        _viewPortHandler = viewPortHandler
    }

    /// Prepares the matrix that transforms values to pixels. Calculates the scale factors from the charts size and offsets.
    open func prepareMatrixValuePx(chartXMin: Double, deltaX: CGFloat, deltaY: CGFloat, chartYMin: Double)
    {
        var scaleX = (_viewPortHandler.contentWidth / deltaX)
        var scaleY = (_viewPortHandler.contentHeight / deltaY)
        
        if CGFloat.infinity == scaleX
        {
            scaleX = 0.0
        }
        if CGFloat.infinity == scaleY
        {
            scaleY = 0.0
        }

        // setup all matrices
        _matrixValueToPx = CGAffineTransform.identity
        _matrixValueToPx = _matrixValueToPx.scaledBy(x: scaleX, y: -scaleY)
        _matrixValueToPx = _matrixValueToPx.translatedBy(x: CGFloat(-chartXMin), y: CGFloat(-chartYMin))
    }

    /// Prepares the matrix that contains all offsets.
    open func prepareMatrixOffset(inverted: Bool)
    {
        if !inverted
        {
            _matrixOffset = CGAffineTransform(translationX: _viewPortHandler.offsetLeft, y: _viewPortHandler.chartHeight - _viewPortHandler.offsetBottom)
        }
        else
        {
            _matrixOffset = CGAffineTransform(scaleX: 1.0, y: -1.0)
            _matrixOffset = _matrixOffset.translatedBy(x: _viewPortHandler.offsetLeft, y: -_viewPortHandler.offsetTop)
        }
    }

    /// Transform an array of points with all matrices.
    // VERY IMPORTANT: Keep matrix order "value-touch-offset" when transforming.
    open func pointValuesToPixel(_ points: inout [CGPoint])
    {
        let trans = valueToPixelMatrix
        for i in 0 ..< points.count
        {
            points[i] = points[i].applying(trans)
        }
    }
    
    open func pointValueToPixel(_ point: inout CGPoint)
    {
        point = point.applying(valueToPixelMatrix)
    }
    
    open func pixelForValues(x: Double, y: Double) -> CGPoint
    {
        return CGPoint(x: x, y: y).applying(valueToPixelMatrix)
    }
    
    /// Transforms the given touch point (pixels) into a value on the chart.
    open func pixelToValues(_ pixel: inout CGPoint)
    {
        pixel = pixel.applying(pixelToValueMatrix)
    }
    
    /// - returns: The x and y values in the chart at the given touch point
    /// (encapsulated in a CGPoint). This method transforms pixel coordinates to
    /// coordinates / values in the chart.
    open func valueForTouchPoint(_ point: CGPoint) -> CGPoint
    {
        return point.applying(pixelToValueMatrix)
    }
    
    open var valueToPixelMatrix: CGAffineTransform
    {
        return
            _matrixValueToPx.concatenating(_viewPortHandler.touchMatrix
                ).concatenating(_matrixOffset
        )
    }
    
    open var pixelToValueMatrix: CGAffineTransform
    {
        return valueToPixelMatrix.inverted()
    }
}
