//
//  TourSessionTasks.swift
//  VirtualTourist
//
//  Created by Krishna Picart on 7/11/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class TourSessionTasks: NSObject {
    
    let downloadQueue = DispatchQueue(label: "download", qos: .background)
    
    let stack = TourCoreDataStack(modelName: "TourModel")
    let session = URLSession.shared
    let tourDataModel = TourDataModel()
    
    func flickerSessionTasks(_ request: URLRequest,
                             completionHandlerForFlickerRequest: @escaping (_ success: Bool,_ error: Error?)-> Void) {
        let additionalTime: DispatchTimeInterval = .seconds(0)
       
        //perform session tasks on background Queue to eliminate loading time for images 
        downloadQueue.asyncAfter(deadline: .now() + additionalTime) {
                        
            let task = self.session.dataTask(with: request) { (data,response, error ) in
                
                //display any errors generated during taskRequestprint
                func displayError(_ error: String) {
                   completionHandlerForFlickerRequest(false, error as? Error)
                }
                
                guard (error == nil) else {
                    displayError("There was an error with your request: \(String(describing: error?.localizedDescription))")
                    return
                }
                
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                    displayError("There was an error with your request: \(String(describing: error?.localizedDescription))")
                    return
                }
                guard let data = data else {
                    displayError("no data was returned")
                    return
                }
                
                let parsedResult: [String:AnyObject]!
                do {
                    parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
                } catch {
                    displayError("could not parse data '\(data)'")
                    return
                }
                
                guard let photosDictionary = parsedResult[APIconstants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    displayError("photosDict cannot find key '\(APIconstants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                    return
                }
                
                guard let photosArray = photosDictionary[APIconstants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                    displayError("photoArray cannot find key '\(APIconstants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                    return
                }
                if photosArray.count == 0 {
                     displayError("no photos found")
                    
                    return
                } else {
                    TourDataModel.sharedInstance().imageArrayCount = photosArray.count
                    
                    TourDataModel.sharedInstance().imageArrayCount = photosArray.count
                    TourDataModel.sharedInstance().tourImages.removeAll()
                    for _ in photosArray {
                       
                        let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                        let photoDictionary = photosArray[randomPhotoIndex] as [String:AnyObject]
                        
                        guard let imageUrlString = photoDictionary[APIconstants.FlickrResponseKeys.MediumURL] as? String else {
                            displayError("imageURLString not found '\(APIconstants.FlickrResponseKeys.MediumURL)' in \(photosDictionary)")
                            return
                        }
                        let imageURL = URL(string: imageUrlString)
                        //convert image to Data
                        guard let imageData = try? Data(contentsOf: imageURL!) else {
                            return
                        }
                        TourDataModel.sharedInstance().tourImages.append(imageData)
                        TourDataModel.sharedInstance().imageData = imageData
                        
                        if TourDataModel.sharedInstance().tourImages.count == TourDataModel.sharedInstance().imageArrayCount {
                            completionHandlerForFlickerRequest(true, "nil" as? Error)
                        }
                    }
                }
                
                self.coreDataTasks()
            }
            task.resume()
        }
    }
    
    var geoPin: Pin?
    var existingPin: Pin?
    var tourStopDictionary = [String: [Data] ]()
    
    func generateNewPin(){
        geoPin = Pin(name: TourDataModel.sharedInstance().compareGeoString , context: (self.stack?.context)!)
        geoPin?.latitude = TourDataModel.sharedInstance().geoCoordinates.latitude
        geoPin?.longitude = TourDataModel.sharedInstance().geoCoordinates.longitude
    }

    
    func coreDataTasks() {
        //Build dictionary from interm array w/ images & placemarks as key/value pairs=> [CLPlacemark:[Data]]
        
        //update the dictionary
        tourStopDictionary.updateValue(TourDataModel.sharedInstance().tourImages, forKey: TourDataModel.sharedInstance().compareGeoString)

        for _ in tourStopDictionary.keys {
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
            
            do {
                //find all existing Pins
               let searchResults = try self.stack?.context.fetch(fetchRequest)
              
                if !(searchResults?.isEmpty)! {
                    
                    for result in searchResults as! [Pin]{
                    if  result.name == TourDataModel.sharedInstance().compareGeoString {
                    
                    //a little housekeeping to remove unused(?) NSSet reference to removed images
                        var removeNSSET = result.photos?.allObjects
                        removeNSSET?.removeAll()
                        
                        do {
                            try self.stack?.saveContext()
                            geoPin = nil
                        } catch {  print("coreData save throw in tasks error \(error.localizedDescription)")  }
                        
                    geoPin = result
                        }
                    }
                    if geoPin == nil {  generateNewPin() }  }
                    
                  //if there are no search results generate new Pin (used for first run be for references are stored)
                else { generateNewPin()  }
            } catch {  print("error in setting Pin",error.localizedDescription) }
        }
        
        for imageData in tourStopDictionary.values{
            for image in imageData {
                
                //add image colletion to coreData for each geoPin
                let geoPhoto = Photo(photoFromTour: image, context: (self.stack?.context)!)
                geoPhoto.creationDate = Date()
                geoPhoto.photoFromTour = image
                geoPhoto.pin = geoPin
                geoPhoto.text = geoPin?.name
            }
            
            do {
                try self.stack?.saveContext()
                geoPin = nil
            } catch { print("coreData save throw in tasks error \(error.localizedDescription)")  }
            
            if !(tourStopDictionary.isEmpty) {  tourStopDictionary.removeAll()   }
        }
    }
}
