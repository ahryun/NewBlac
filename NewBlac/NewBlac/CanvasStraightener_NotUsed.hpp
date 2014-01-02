//
//  CanvasStraightener.hpp
//  NewBlac
//
//  Created by Ahryun Moon on 12/10/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#ifndef __NewBlac__CanvasStraightener_NotUsed__
#define __NewBlac__CanvasStraightener_NotUsed__

#include <iostream>
#include "opencv2/core/core.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"
#include <stdio.h>
#include <stdlib.h>

#endif /* defined(__NewBlac__CanvasStraightener_NotUsed__) */

class CanvasStraightener_NotUsed
{
public:
    struct Images
    {
        cv::Mat photoCopy;
        cv::Mat canvas;
    } images_;
    
    CanvasStraightener_NotUsed(Images images);
    ~ CanvasStraightener_NotUsed() {};
    
    void straighten();
    
private:
    void findSquares(const cv::Mat& image, std::vector<std::vector<cv::Point> >& squares);
    
    void applyGrayscale();
    void applyGaussianBlur(cv::Size kernel_size);
    void convertToBinary();
    void applyHoughTransform();
    double getAngle(cv::Point ptOne, cv::Point ptTwo, cv::Point ptZero);
    void drawSquares(cv::Mat &image, const std::vector<cv::Point> &squares);
    void drawSquaresA(cv::Mat &image, const std::vector<std::vector<cv::Point>> &squares);
    void findCorners();
    void findPolygonal();
    //bool compareContourAreas(std::vector<cv::Point> contour1, std::vector<cv::Point> contour2);
    
    void findEdges();
    void findCanvas();
    void getStraighteningMatrix();
    void applyFloodFill();
    void applyBlobDetection();
    
    //Images images_;
};