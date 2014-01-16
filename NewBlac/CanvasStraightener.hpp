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
        bool initialStraighteningDone;
        std::vector<cv::Point> square;
        cv::Point2f inputQuad[4]; // coordinate corresponding to pixels in images_photoCopy
    } images_;
    
    CanvasStraightener(Images images);
    ~ CanvasStraightener() {}; // destructor
    
    void straighten();
    
private:
    void findASquare(const cv::Mat& image, std::vector<std::vector<cv::Point>> &squares, std::vector<cv::Point> &square);
    
    void applyGrayscale(cv::Mat &image);
    void applyGaussianBlur(cv::Mat &image, cv::Size kernel_size);
    double getAngle(cv::Point ptOne, cv::Point ptTwo, cv::Point ptZero);
    void drawSquares(cv::Mat &image, const std::vector<cv::Point> &squares);
    cv::Point convertToPixel(float canvasWidth, float canvasHeight, cv::Point &point, const float imageWidth, const float imageHeight);
    double getAspectRatio(float canvasWidth, float canvasHeight, std::vector<cv::Point> &square,  const float imageWidth, const float imageHeight, const float focalLength, const float sensorWidth);
    void warpToRectangle(const cv::Mat&image, const cv::Mat&originalImage, std::vector<cv::Point> &square,  const float imageWidth, const float imageHeight, const float focalLength, const float sensorWidth);
    
    // If a user manually changes the corners
    void straightenToNewRectangle();
    void warpToNewRectangle(const cv::Mat&originalImage, const cv::Point2f inputQuad[],  const float imageWidth, const float imageHeight, const float focalLength, const float sensorWidth);
};