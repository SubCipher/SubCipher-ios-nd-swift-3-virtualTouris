//
//  APImethods.swift
//  VirtualTourist
//
//  Created by Krishna Picart on 7/11/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//

import Foundation
import MapKit

class APImethods: NSObject {
    
    let tourDataModel = TourDataModel()
    let tourSessionTasks = TourSessionTasks()
    
    func geoSearch(_ coordinates: CLLocationCoordinate2D,completionHandlerForGeoSearch: @escaping(_ success:Bool, _ error: String) ->Void) {
    
        TourDataModel.sharedInstance().geoCoordinates = coordinates
        
        let methodParameters = [
        APIconstants.FlickrParameterKeys.Method: APIconstants.FlickrParameterValues.SearchMethod,
        APIconstants.FlickrParameterKeys.PerPage: APIconstants.FlickrParameterValues.NumberImagesPerPage,
        APIconstants.FlickrParameterKeys.APIKEY: APIconstants.FlickrParameterValues.APIKEY,
        APIconstants.FlickrParameterKeys.BoundingBox: bboxString(coordinates),
        
        APIconstants.FlickrParameterKeys.SafeSearch: APIconstants.FlickrParameterValues.UseSafeSearch,
        APIconstants.FlickrParameterKeys.Extras: APIconstants.FlickrParameterValues.MediumURL,
        
        APIconstants.FlickrParameterKeys.Format: APIconstants.FlickrParameterValues.ResponseFormat,
        APIconstants.FlickrParameterKeys.NoJSONCallBack: APIconstants.FlickrParameterValues.DisableJSONCallBack
        ]
        
        
        createAPIRequest(methodParameters as [String : AnyObject]) {(success,error) in
            
            guard success == true else {
                completionHandlerForGeoSearch(false,"completionHandlerForGeoSearch FAILED")
                return
            }
             completionHandlerForGeoSearch(true,"")
        }
    }
    
    private func bboxString(_ coordinate: CLLocationCoordinate2D?) ->String {
        
        if let latitude = coordinate?.latitude,let longitude = coordinate?.longitude {
            let minimumLon = max(longitude - APIconstants.Flickr.SearchBBoxHalfWidth, APIconstants.Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - APIconstants.Flickr.SearchBoxHalfHeight, APIconstants.Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + APIconstants.Flickr.SearchBBoxHalfWidth, APIconstants.Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + APIconstants.Flickr.SearchBoxHalfHeight, APIconstants.Flickr.SearchLatRange.1)
            
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        } else {
            return "0,0,0,0"
        }
    }
    
    
    func createAPIRequest(_ methodParameters: [String:AnyObject], completionHandlerForAPIrequest: @escaping (_ results:Bool, _ error: String) -> Void) {
       
        
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        tourSessionTasks.flickerSessionTasks(request) { (results,error) in
            guard error == nil else {
                completionHandlerForAPIrequest(false,error?.localizedDescription ?? "")
                return
            }
            
            completionHandlerForAPIrequest(true,error?.localizedDescription ?? "" )
                       
            }
    }
    
    
    private func flickrURLFromParameters(_ parameters: [String: AnyObject]) -> URL {
        var components = URLComponents()
        components.scheme = APIconstants.Flickr.APIScheme
        components.host = APIconstants.Flickr.APIHost
        components.path = APIconstants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key,value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
}
