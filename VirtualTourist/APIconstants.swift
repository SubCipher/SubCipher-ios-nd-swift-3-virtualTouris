//
//  APIconstants.swift
//  VirtualTourist
//
//  Created by Krishna Picart on 7/8/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//

import Foundation
import UIKit

struct APIconstants {
    
    struct Flickr {
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
        
        static let SearchBBoxHalfWidth = 0.5
        static let SearchBoxHalfHeight = 0.5
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
    }
    
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKEY = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallBack = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let Page = "page"
        static let PerPage = "per_page"
        
    }
    
    struct FlickrParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKEY = "4f27d98a8f10a2bf38a69e3a7bf9bcea"
        static let ResponseFormat = "json"
        static let DisableJSONCallBack = "1"
        static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
        static let GalleryID = "6065-72157617483228192"
        static let MediumURL = "url_m"
        static let UseSafeSearch = "1"
        static let NumberImagesPerPage = "12"
        static let PageNumber = "1"
        
    }
    //future use for flickr page selection 
    
    func randomePage()->Int{
    
        let pageNumber = Int(arc4random_uniform(UInt32(3)))
        return pageNumber
    }
    
    struct FlickrResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let Total = "total"
        
    }
    
    struct FlickrResponseValues {
        static let OKStatus = "ok"
}
}
