////
////  CanvasStraightener_NotUsed.cpp
////  NewBlac
////
////  Created by Ahryun Moon on 12/10/13.
////  Copyright (c) 2013 Ahryun Moon. All rights reserved.
////
//
//#include "CanvasStraightener_NotUsed.hpp"
//
//using namespace std;
//using namespace cv;
//
//CanvasStraightener_NotUsed::CanvasStraightener_NotUsed(Images images)
//{
//    images_ = images;
//    straighten();
//}
//
//// comparison function object
//bool compareContourAreas ( std::vector<cv::Point> contour1, std::vector<cv::Point> contour2 ) {
//    double i = fabs( contourArea(cv::Mat(contour1)) );
//    double j = fabs( contourArea(cv::Mat(contour2)) );
//    return ( i < j );
//}
//
//void CanvasStraightener_NotUsed::straighten()
//{
//    applyGrayscale();
//    applyGaussianBlur(cv::Size(5,5));
//    
//    vector<vector<Point> > squares;
//    findSquares(images_.canvas, squares);
//    //    drawSquaresA(images_.canvas, squares);
//    
//    //    convertToBinary();
//    //    findPolygonal();
//    
//    //    applyHoughTransform();
//    //    findCorners();
//    //    findEdges();
//    //    applyBlobDetection();
//    //    applyFloodFill();
//    //    findCorners();
//    //    findCanvas();
//    //    getStraighteningMatrix();
//    
//    // Apply straightening to the color copy of the photo
//}
//
//void CanvasStraightener_NotUsed::applyGrayscale()
//{
//    if (!images_.canvas.empty()) {
//        cvtColor(images_.canvas, images_.canvas, CV_BGR2GRAY);
//    }
//}
//
//void CanvasStraightener_NotUsed::applyGaussianBlur(cv::Size kernel_size)
//{
//    if (!images_.canvas.empty()) {
//        
//        GaussianBlur(images_.canvas, images_.canvas, kernel_size, 1.2, 1.2);
//    }
//}
//
//void CanvasStraightener_NotUsed::convertToBinary()
//{
//    if (!images_.canvas.empty()) {
//        double const max_BINARY_value = 255.0;
//        int const block_size = 3;
//        double const constant_value = 1.0;
//        
//        /*  Adaptive Method
//         0: ADAPTIVE_THRESH_MEAN_C
//         1: ADAPTIVE_THRESH_GAUSSIAN_C
//         */
//        /*  Threshold Type
//         0: THRESH_BINARY
//         1: THRESH_BINARY_INV
//         */
//        
//        adaptiveThreshold(images_.canvas,
//                          images_.canvas,
//                          max_BINARY_value,
//                          ADAPTIVE_THRESH_GAUSSIAN_C,
//                          THRESH_BINARY_INV,
//                          block_size,
//                          constant_value);
//        
//        medianBlur(images_.canvas, images_.canvas, 3);
//        
//        //        int dilate_size = 2;
//        //        int erode_size = 1;
//        //        Mat dilate_element = getStructuringElement(MORPH_RECT,
//        //                                            Size(2 * dilate_size + 1, 2 * dilate_size+1),
//        //                                            Point(dilate_size, dilate_size));
//        //        Mat erode_element = getStructuringElement(MORPH_RECT,
//        //                                                   Size(2 * erode_size + 1, 2 * erode_size+1),
//        //                                                   Point(erode_size, erode_size));
//        //
//        //        dilate(images_.canvas, images_.canvas, dilate_element);
//        //        erode(images_.canvas, images_.canvas, erode_element);
//    }
//}
//
//void CanvasStraightener_NotUsed::applyHoughTransform()
//{
//    if (!images_.canvas.empty()) {
//        vector<Vec4i> lines;
//        HoughLinesP(images_.canvas,
//                    lines,
//                    1,
//                    CV_PI/180,
//                    100,
//                    100,
//                    10);
//        
//        images_.canvas.setTo(cv::Scalar(255));
//        for(size_t i = 0; i < lines.size(); i++)
//        {
//            Vec4i l = lines[i];
//            line(images_.canvas,
//                 Point(l[0], l[1]),
//                 Point(l[2], l[3]),
//                 Scalar(150),
//                 1,
//                 CV_AA);
//        }
//    }
//}
//
//void CanvasStraightener_NotUsed::findPolygonal()
//{
//    vector<vector<Point>> contours;
//    vector<Vec4i> hierarchy;
//    
//    findContours(images_.canvas,
//                 contours,
//                 hierarchy,
//                 CV_RETR_EXTERNAL,
//                 CV_CHAIN_APPROX_SIMPLE,
//                 Point(10,10));
//    
//    // Get the largest contour
//    double contourAreaPixel = contourArea(Mat(contours[0]));
//    int ithContour = 0;
//    for (int i = 0; i < contours.size(); i++)
//    {
//        if (contourArea(Mat(contours[i])) > contourAreaPixel) {
//            contourAreaPixel = contourArea(Mat(contours[i]));
//            ithContour = i;
//        }
//    }
//    cout << "Largest contour area is " << contourAreaPixel << "\n";
//    cout << "ithContour is " << ithContour <<"\n";
//    images_.canvas.setTo(cv::Scalar::all(255));
//    drawContours(images_.canvas, contours, ithContour, Scalar(0), 1, 8, vector<Vec4i>(), 0, Point());
//    
//    std::vector<Point> contours_poly;
//    approxPolyDP(Mat(contours[ithContour]),
//                 contours_poly,
//                 arcLength(Mat(contours[ithContour]), true)*0.02,
//                 true);
//    
//    if (contours_poly.size() == 4 &&
//        fabs(contourArea(Mat(contours_poly))) > 1000 &&
//        isContourConvex(Mat(contours_poly))) {
//        
//        double maxCosine = 0;
//        for(int j = 2; j < 5; j++)
//        {
//            // find the maximum cosine of the angle between joint edges
//            double cosine = fabs(getAngle(contours_poly[j%4],
//                                          contours_poly[j-2],
//                                          contours_poly[j-1]));
//            maxCosine = MAX(maxCosine, cosine);
//        }
//        
//        // if cosines of all angles are small
//        // (all angles are ~90 degree) then write quandrange
//        // vertices to resultant sequence
//        if( maxCosine < 0.3) drawSquares(images_.canvas, contours_poly);
//    } else {
//        cout << "Oops! There is not large rectangle\n";
//    }
//}
//
//double CanvasStraightener_NotUsed::getAngle(Point ptOne, Point ptTwo, Point ptZero)
//{
//    double dxOne = ptOne.x - ptZero.x;
//    double dyOne = ptOne.y - ptZero.y;
//    double dxTwo = ptTwo.x - ptZero.x;
//    double dyTwo = ptTwo.y - ptZero.y;
//    return (dxOne * dxTwo + dyOne * dyTwo)/sqrt((dxOne * dxOne + dyOne * dyOne) * (dxTwo * dxTwo + dyTwo * dyTwo) + 1e-10);
//}
//
//// the function draws all the squares in the image
//void CanvasStraightener_NotUsed::drawSquares(Mat &image, const vector<Point> &squares)
//{
//    const Point* p = &squares[0];
//    int n = (int)squares.size();
//    polylines(image, &p, &n, 1, true, Scalar(0), 1, CV_AA);
//}
//
//void CanvasStraightener_NotUsed::findCorners()
//{
//    if (!images_.canvas.empty()) {
//        
//        ///////////////////
//        /* HARRIS CORNER */
//        ///////////////////
//        
//        Mat dst, dst_norm, dst_norm_scaled, mask;
//        //        int blockSize = 3;
//        //        double k = 0.04;
//        //        dst = Mat::zeros(images_.canvas.size(), CV_32FC1);
//        //        int apertureSize = 5;
//        //        int thresh = 0;
//        //
//        //        // Detecting corners
//        //        cornerHarris(images_.canvas,
//        //                     dst,
//        //                     blockSize,
//        //                     apertureSize,
//        //                     k,
//        //                     BORDER_DEFAULT);
//        //
//        //        // Normalizing
//        //        normalize(dst,
//        //                  dst_norm,
//        //                  0,
//        //                  255,
//        //                  NORM_MINMAX,
//        //                  CV_32FC1,
//        //                  Mat());
//        //
//        //        convertScaleAbs( dst_norm, dst_norm_scaled );
//        //
//        //        // Drawing a circle around corners
//        //        for( int j = 0; j < dst_norm.rows ; j++ )
//        //        {
//        //            for( int i = 0; i < dst_norm.cols; i++ )
//        //            {
//        //                if( (int) dst_norm.at<float>(j,i) > thresh )
//        //                {
//        //                    circle(images_.canvas,
//        //                           Point( i, j ),
//        //                           2,
//        //                           Scalar((int)dst_norm.at<float>(j,i)),
//        //                           2,
//        //                           8,
//        //                           0);
//        //                    cout << Point(j,i) << "\n";
//        //                }
//        //            }
//        //        }
//        
//        
//        ////////////////////////////
//        /* GOOD FEATURES TO TRACK */
//        ////////////////////////////
//        
//        vector<Point2f> features;
//        int min_distance, no_corners;
//        double quality_level;
//        bool use_Harris;
//        no_corners = 4;
//        use_Harris = true;
//        quality_level = 0.1;
//        mask = Mat::zeros(images_.canvas.size(), CV_8UC1);
//        min_distance = images_.canvas.size().width / 3;
//        goodFeaturesToTrack(images_.canvas,
//                            features,
//                            no_corners,
//                            quality_level,
//                            min_distance
//                            //                            mask,
//                            //                            blockSize,
//                            //                            use_Harris,
//                            //                            k
//                            );
//        
//        cout << features << "\n";
//        
//        for (int i = 0; i < features.size(); i++) {
//            circle(images_.canvas,
//                   Point(features[i].x, features[i].y),
//                   2,
//                   Scalar(150));
//        }
//        
//    }
//}
//
//void CanvasStraightener_NotUsed::findEdges()
//{
//    if (!images_.canvas.empty()) {
//        cv::Mat edges;
//        cv::Canny(images_.canvas, edges, 50, 200, 3, true);
//        images_.canvas.setTo(cv::Scalar::all(255));
//        images_.canvas.setTo(cv::Scalar(0, 128, 255, 255), edges);
//        
//        int dilate_size = 0;
//        cv::Mat element = getStructuringElement( MORPH_RECT,
//                                                Size( 2*dilate_size + 1, 2*dilate_size+1 ),
//                                                Point( dilate_size, dilate_size ) );
//        cv::dilate(images_.canvas, images_.canvas, element);
//        
//        //        vector<vector<Point> > contours;
//        //        vector<Vec4i> hierarchy;
//        //        findContours(images_.canvas,
//        //                     contours,
//        //                     hierarchy,
//        //                     CV_RETR_TREE,
//        //                     CV_CHAIN_APPROX_SIMPLE,
//        //                     cv::Point(0,0));
//        //        images_.canvas.setTo(cv::Scalar::all(255));
//        //        for( int i = 0; i< contours.size(); i++ )
//        //        {
//        //            Scalar color = Scalar(0,0,0);
//        //            drawContours( images_.canvas, contours, i, color, 1, CV_AA, hierarchy, 0, Point() );
//        //        }
//    }
//}
//
//void CanvasStraightener_NotUsed::applyBlobDetection()
//{
//    if (!images_.canvas.empty()) {
//        cv::SimpleBlobDetector::Params params;
//        params.minDistBetweenBlobs = 10.0;  // minimum 10 pixels between blobs
//        params.filterByArea = true;         // filter my blobs by area of blob
//        params.minArea = 20.0;              // min 20 pixels squared
//        params.maxArea = 500.0;             // max 500 pixels squared
//        SimpleBlobDetector myBlobDetector(params);
//        std::vector<cv::KeyPoint> myBlobs;
//        myBlobDetector.detect(images_.canvas, myBlobs);
//        
//        drawKeypoints(images_.canvas, myBlobs, images_.canvas);
//        
//        cout << "Number of blobs: " << myBlobs.size() << "\n";
//        
//    }
//}
//
//void CanvasStraightener_NotUsed::applyFloodFill()
//{
//    if (!images_.canvas.empty()) {
//        cv::Point seed(4,4);
//        //        cv::Mat mask;
//        //        cv::Canny(images_.canvas, mask, 100, 200);
//        //        cv::copyMakeBorder(mask, mask, 1, 1, 1, 1, cv::BORDER_REPLICATE);
//        //        uchar fillValue = 128;
//        
//        cv::floodFill(images_.canvas,
//                      //                      mask,
//                      seed,
//                      cv::Scalar(150), // Color for the fill
//                      0, // Maximal lower brightness/color difference
//                      cv::Scalar(), // Maximal upper brightness/color difference
//                      cv::Scalar(), //
//                      4);
//        //                      4 | cv::FLOODFILL_MASK_ONLY | (fillValue << 8));
//        
//        //        std::vector<std::vector<Point>> contours;
//        //        vector<Vec4i> hierarchy;
//        //        findContours(images_.canvas,
//        //                     contours,
//        //                     hierarchy,
//        //                     CV_RETR_TREE,
//        //                     CV_CHAIN_APPROX_SIMPLE,
//        //                     cv::Point(0,0));
//        //
//        //        int largestBlobIndex;
//        //        double largestBlobArea = 0.0;
//        //        Scalar color = Scalar(255,105,180);
//        //        for (int i = 0; i < contours.size(); i++) {
//        //            if (i == 0 | contourArea(contours[i]) > largestBlobArea) {
//        //                largestBlobArea = contourArea(contours[i]);
//        //                largestBlobIndex = i;
//        //            }
//        //        }
//        // show something with the largest blob
//        //contours[i];
//    }
//}
//
//// returns sequence of squares detected on the image.
//// the sequence is stored in the specified memory storage
//void CanvasStraightener_NotUsed::findSquares(const Mat& image, vector<vector<Point> >& squares)
//{
//    squares.clear();
//    
//    Mat pyr, timg, gray;
//    
//    // down-scale and upscale the image to filter out the noise
//    pyrDown(image, pyr, Size(image.cols/2, image.rows/2));
//    pyrUp(pyr, timg, image.size());
//    vector<vector<Point> > contours;
//    
//    // hack: use Canny instead of zero threshold level.
//    // Canny helps to catch squares with gradient shading
//    // apply Canny. Take the upper threshold from slider
//    // and set the lower to 0 (which forces edges merging)
//    //                Canny(gray0, gray, 0, thresh, 5);
//    double const max_BINARY_value = 255.0;
//    int const block_size = 3;
//    double const constant_value = 1.0;
//    //    cvtColor(timg, timg, CV_BGR2GRAY);
//    adaptiveThreshold(timg,
//                      gray,
//                      max_BINARY_value,
//                      ADAPTIVE_THRESH_GAUSSIAN_C,
//                      THRESH_BINARY_INV,
//                      block_size,
//                      constant_value);
//    // dilate canny output to remove potential
//    // holes between edge segments
//    //    dilate(gray, gray, Mat(), Point(-1,-1));
//    
//    // find contours and store them all as a list
//    findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
//    
//    vector<Point> approx;
//    
//    // test each contour
//    for( size_t i = 0; i < contours.size(); i++ )
//    {
//        // approximate contour with accuracy proportional
//        // to the contour perimeter
//        approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true)*0.02, true);
//        
//        // square contours should have 4 vertices after approximation
//        // relatively large area (to filter out noisy contours)
//        // and be convex.
//        // Note: absolute value of an area is used because
//        // area may be positive or negative - in accordance with the
//        // contour orientation
//        if( approx.size() == 4 &&
//           fabs(contourArea(Mat(approx))) > 2000 &&
//           isContourConvex(Mat(approx)) )
//        {
//            double maxCosine = 0;
//            
//            for( int j = 2; j < 5; j++ )
//            {
//                // find the maximum cosine of the angle between joint edges
//                double cosine = fabs(getAngle(approx[j%4], approx[j-2], approx[j-1]));
//                maxCosine = MAX(maxCosine, cosine);
//            }
//            
//            // if cosines of all angles are small
//            // (all angles are ~90 degree) then write quandrange
//            // vertices to resultant sequence
//            if( maxCosine < 0.3 )
//                squares.push_back(approx);
//        }
//    }
//    
//    // sort squares
//    sort(squares.begin(), squares.end(), compareContourAreas);
//    
//    // grab second largest contour
//    std::vector<cv::Point> secondBiggestContour = squares[squares.size()-2];
//    cout << "Largest contour area is " << secondBiggestContour << "\n";
//    
//    drawSquares(images_.canvas, secondBiggestContour);
//    
//}
//
//
//
//
//
//
