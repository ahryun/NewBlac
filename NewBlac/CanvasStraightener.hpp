//
//  CanvasStraightener.hpp
//  NewBlac
//
//  Created by Ahryun Moon on 12/10/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#ifndef __NewBlac__CanvasStraightener__
#define __NewBlac__CanvasStraightener__

#include <iostream>
#include "opencv2/core/core.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "opencv2/highgui/highgui.hpp"
#include <stdio.h>
#include <stdlib.h>

#endif /* defined(__NewBlac__CanvasStraightener__) */

class CanvasStraightener
{
public:
    struct Images
    {
        cv::Mat photoCopy;
        cv::Mat canvas;
        float imageWidth;
        float imageHeight;
        float focalLength;
        float sensorWidth;
        std::vector<cv::Point> square;
    } images_;
    
    CanvasStraightener(Images images);
    ~ CanvasStraightener() {};
    
    void straighten();
    
private:
    void findASquare(const cv::Mat& image, std::vector<std::vector<cv::Point>> &squares, std::vector<cv::Point> &square);
    
    void applyGrayscale(cv::Mat &image);
    void applyGaussianBlur(cv::Mat &image, cv::Size kernel_size);
    double getAngle(cv::Point ptOne, cv::Point ptTwo, cv::Point ptZero);
    void drawSquares(cv::Mat &image, const std::vector<cv::Point> &squares);
    cv::Point convertToPixel(const cv::Mat &image, cv::Point &point, const float imageWidth, const float imageHeight);
    double getAspectRatio(const cv::Mat &image, std::vector<cv::Point> &square,  const float imageWidth, const float imageHeight, const float focalLength, const float sensorWidth);
    void warpToRectangle(const cv::Mat&image, const cv::Mat&originalImage, std::vector<cv::Point> &square,  const float imageWidth, const float imageHeight, const float focalLength, const float sensorWidth);
};