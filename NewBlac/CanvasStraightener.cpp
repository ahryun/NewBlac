//
//  CanvasStraightener.cpp
//  NewBlac
//
//  Created by Ahryun Moon on 12/10/13.
//  Copyright (c) 2013 Ahryun Moon. All rights reserved.
//

#include "CanvasStraightener.hpp"

using namespace std;
using namespace cv;

CanvasStraightener::CanvasStraightener(Images images)
{
    images_ = images;
    straighten();
}

// comparison function object
bool compareContourAreas ( std::vector<cv::Point> contour1, std::vector<cv::Point> contour2 ) {
    double i = fabs(contourArea(cv::Mat(contour1)));
    double j = fabs(contourArea(cv::Mat(contour2)));
    return ( i < j );
}

void CanvasStraightener::straighten()
{
    applyGrayscale(images_.canvas);
    applyGaussianBlur(images_.canvas, Size(5,5));

    vector<vector<Point>> squares;
    findASquare(images_.canvas, squares, images_.square);
    warpToRectangle(images_.canvas, images_.photoCopy, images_.square, images_.imageWidth, images_.imageHeight, images_.focalLength, images_.sensorWidth);
}

void CanvasStraightener::applyGrayscale(Mat &image)
{
    if (!image.empty()) {
        cvtColor(image, image, CV_BGR2GRAY);
    }
}

void CanvasStraightener::applyGaussianBlur(Mat &image, Size kernel_size)
{
    if (!image.empty()) {
        
        GaussianBlur(image, image, kernel_size, 1.2, 1.2);
    }
}

double CanvasStraightener::getAngle(Point ptOne, Point ptTwo, Point ptZero)
{
    double dxOne = ptOne.x - ptZero.x;
    double dyOne = ptOne.y - ptZero.y;
    double dxTwo = ptTwo.x - ptZero.x;
    double dyTwo = ptTwo.y - ptZero.y;
    return (dxOne * dxTwo + dyOne * dyTwo)/sqrt((dxOne * dxOne + dyOne * dyOne) * (dxTwo * dxTwo + dyTwo * dyTwo) + 1e-10);
}

void CanvasStraightener::drawSquares(Mat &image, const vector<Point> &squares)
{
    const Point* p = &squares[0];
    int n = (int)squares.size();
    polylines(image, &p, &n, 1, true, Scalar(255), 1, CV_AA);
}

void CanvasStraightener::findASquare(const Mat& image, vector<vector<Point>> &squares, vector<Point> &square)
{
    squares.clear();
    square.clear();
    
    Mat pyr, timg, gray;
    
    // Further remove noise
    pyrDown(image, pyr, Size(image.cols/2, image.rows/2));
    pyrUp(pyr, timg, image.size());
    vector<vector<Point>> contours;
    
    // Adapative threshold to find the edges where the derivative of intensity is high
    double const max_BINARY_value = 255.0;
    int const block_size = 3;
    double const constant_value = 1.0;
    adaptiveThreshold(timg,
                      gray,
                      max_BINARY_value,
                      ADAPTIVE_THRESH_GAUSSIAN_C,
                      THRESH_BINARY_INV,
                      block_size,
                      constant_value);

    // find contours and store them all as a list
    findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
    
    vector<Point> approx;
    for( size_t i = 0; i < contours.size(); i++ )
    {
        approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true)*0.02, true);
        
        if( approx.size() == 4 &&
           fabs(contourArea(Mat(approx))) > 1000 &&
           isContourConvex(Mat(approx)) )
        {
            double maxCosine = 0;
            
            for( int j = 2; j < 5; j++ )
            {
                // find cosine of each angle
                double cosine = fabs(getAngle(approx[j%4], approx[j-2], approx[j-1]));
                maxCosine = MAX(maxCosine, cosine);
            }
            
            // At least one of the angles is ~90 degree
            if( maxCosine < 0.3 )
                squares.push_back(approx);
        }
    }
    
    if (squares.size() >= 2) {
        // sort squares
        sort(squares.begin(), squares.end(), compareContourAreas);
        // grab second largest contour
        square = squares[squares.size()-2];
        cout << "Largest contour area is " << square << "\n";
    } else {
        cout << "Hey. No square has been detected. Try again\n";
    }
    
    if (!square.empty()) {
        drawSquares(images_.canvas, square);
    } else {
        // Make the user try again
        cout << "There is no square";
    }
}

struct ySortFunction {
    bool operator() (Point pt1, Point pt2) { return (pt1.y < pt2.y);}
} vectorSorter_y;

Point CanvasStraightener::convertToPixel(const cv::Mat &image, Point &point, const float imageWidth, const float imageHeight)
{
    Point convertedPoint;
    convertedPoint.x = point.x / (double)image.size().width * (double)imageWidth;
    convertedPoint.y = point.y / (double)image.size().height * (double)imageHeight;
    cout << "Point x here is " << convertedPoint.x << "\n";
    cout << "Point y here is " << convertedPoint.y << "\n";
    return convertedPoint;
}

double CanvasStraightener::getAspectRatio(const cv::Mat &image, vector<Point> &square, const float imageWidth, const float imageHeight, const float focalLength, const float sensorWidth)
{
    cout << "Image width is " << imageWidth << "\n";
    cout << "Image height is " << imageHeight << "\n";
    
    // get each corner of the square in order
    Point corner1, corner2, corner3, corner4;
    sort(square.begin(), square.end(), vectorSorter_y);
    if (square[2].x < square[3].x) {
        corner1 = convertToPixel(image, square[2], imageWidth, imageHeight);
        corner2 = convertToPixel(image, square[3], imageWidth, imageHeight);
    } else {
        corner1 = convertToPixel(image, square[3], imageWidth, imageHeight);
        corner2 = convertToPixel(image, square[2], imageWidth, imageHeight);
    }
    if (square[0].x < square[1].x) {
        corner3 = convertToPixel(image, square[0], imageWidth, imageHeight);
        corner4 = convertToPixel(image, square[1], imageWidth, imageHeight);
    } else {
        corner3 = convertToPixel(image, square[1], imageWidth, imageHeight);
        corner4 = convertToPixel(image, square[0], imageWidth, imageHeight);
    }
    
    cout << "Corner 1 is " << corner1 << "\n";
    cout << "Corner 2 is " << corner2 << "\n";
    cout << "Corner 3 is " << corner3 << "\n";
    cout << "Corner 4 is " << corner4 << "\n";
    
    // Get the matrix form of ordered corners
    // The order is kinda weird. BottomLeft -> BottomRight -> TopLeft -> TopRight
    cv::Mat m1 = (cv::Mat_<float>(3,1) << corner1.x, corner1.y, 1);
    cv::Mat m2 = (cv::Mat_<float>(3,1) << corner2.x, corner2.y, 1);
    cv::Mat m3 = (cv::Mat_<float>(3,1) << corner3.x, corner3.y, 1);
    cv::Mat m4 = (cv::Mat_<float>(3,1) << corner4.x, corner4.y, 1);
    
    cout << "Corner 1 matrix is " << m1 << "\n";
    cout << "Corner 2 matrix is " << m2 << "\n";
    cout << "Corner 3 matrix is " << m3 << "\n";
    cout << "Corner 4 matrix is " << m4 << "\n";
    
    float k2, k3, u0, v0, focalLengthinPixel, s, aspectRatio;
    Mat n2, n3, ratioMat;
    
    // Get k2 and k3
    k2 = (m1.cross(m4).dot(m3)) / ((m2.cross(m4)).dot(m3));
    k3 = (m1.cross(m4).dot(m2)) / ((m3.cross(m4)).dot(m2));
    
    // Get n2 and n3
    n2 = (k2*m2) - m1;
    n3 = (k3*m3) - m1;
    
    // Estimate focal length
    s = 1.0; // ratio of a pixel is usually 1 with modern cameras
    u0 = imageWidth / 2;
    v0 = imageHeight / 2;
    
    cout << "The focal point is " << u0 << " & " << v0 << "\n";
    
    // Assuming the device is either iPhone or iPad, preload xml with all devices' focal length in pixels
    focalLengthinPixel = focalLength / sensorWidth * MAX(imageWidth, imageHeight);
    
    Mat A = (cv::Mat_<float>(3,3) <<
         focalLength, 0, u0,
         0, focalLength, v0,
         0,0,1);
    
    cout << "Matrix A is " << A;
    
    ratioMat = (n2.t()*(A.inv().t())*(A.inv())*n2) / (n3.t()*(A.inv().t())*(A.inv())*n3);
    aspectRatio = sqrt(ratioMat.at<float>(0,0));
    
    cout << "The aspect ratio is " << aspectRatio << "\n";
    
    return aspectRatio; // width / height
}

void CanvasStraightener::warpToRectangle(const Mat &image, const cv::Mat&originalImage, vector<Point> &square,  const float imageWidth, const float imageHeight, const float focalLength, const float sensorWidth)
{
    if (!square.empty() && !image.empty() && !originalImage.empty()) {
        // get each corner of the square in order
        Point2f inputQuad[4];
        Point2f outputQuad[4];
        sort(square.begin(), square.end(), vectorSorter_y);
        float ratioToOriginalImageWidth = (float)originalImage.size().width / (float)image.size().width;
        float ratioToOriginalImageHeight = (float)originalImage.size().height / (float)image.size().height;
        
        cout << "Original image width ratio is " << ratioToOriginalImageWidth << "\n";
        cout << "Original image height ratio is " << ratioToOriginalImageHeight << "\n";
        
        if (square[2].x < square[3].x) {
            inputQuad[0] = Point2f(square[2].x * ratioToOriginalImageWidth,
                                   square[2].y * ratioToOriginalImageHeight);
            inputQuad[1] = Point2f(square[3].x * ratioToOriginalImageWidth,
                                   square[3].y * ratioToOriginalImageHeight);
        } else {
            inputQuad[0] = Point2f(square[3].x * ratioToOriginalImageWidth,
                                   square[3].y * ratioToOriginalImageHeight);
            inputQuad[1] = Point2f(square[2].x * ratioToOriginalImageWidth,
                                   square[2].y * ratioToOriginalImageHeight);
        }
        if (square[0].x < square[1].x) {
            inputQuad[2] = Point2f(square[0].x * ratioToOriginalImageWidth,
                                   square[0].y * ratioToOriginalImageHeight);
            inputQuad[3] = Point2f(square[1].x * ratioToOriginalImageWidth,
                                   square[1].y * ratioToOriginalImageHeight);
        } else {
            inputQuad[2] = Point2f(square[1].x * ratioToOriginalImageWidth,
                                   square[1].y * ratioToOriginalImageHeight);
            inputQuad[3] = Point2f(square[0].x * ratioToOriginalImageWidth,
                                   square[0].y * ratioToOriginalImageHeight);
        }
        
        for (int i = 0; i < 4; i ++) {
            images_.inputQuad[i] = inputQuad[i];
        }
        
        float aspectRatio = getAspectRatio(image, square, imageWidth, imageHeight, focalLength, sensorWidth);
        
        // Depending on whether the paper is wider or longer, max(width, height) is 1000.0
        float rectWidth, rectHeight;
        if (aspectRatio > 1.0) {
            rectWidth = 1000.0;
            rectHeight = rectWidth / aspectRatio;
        } else {
            rectHeight = 1000.0;
            rectWidth = rectHeight * aspectRatio;
        }
        
        outputQuad[0] = Point2f(0,rectHeight);
        outputQuad[1] = Point2f(rectWidth,rectHeight);
        outputQuad[2] = Point2f(0,0);
        outputQuad[3] = Point2f(rectWidth,0);
        
        cout << "New square points are ";
        for ( int i = 0; i < 4; i++ ) {
            cout << inputQuad[i] << ' ';
        }
        cout << endl;
        cout << "Destination points are ";
        for ( int i = 0; i < 4; i++ ) {
            cout << outputQuad[i] << ' ';
        }
        cout << endl;
        
        Mat transformationMatrix = getPerspectiveTransform(inputQuad, outputQuad);
        cout << "Transformation matrix is " << transformationMatrix << "\n";
        Mat dstImage;
        warpPerspective(originalImage, dstImage, transformationMatrix, Size(rectWidth, rectHeight), INTER_NEAREST);
        images_.photoCopy = dstImage;
    }
}







