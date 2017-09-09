//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Krishna Picart on 7/8/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//


import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    
    let stack = TourCoreDataStack(modelName: "TourModel")
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>?
    lazy var geocoder = CLGeocoder()
    var reachability: TourNetworkStatus = TourNetworkStatus.init(hostName: "api.flickr.com")!
    
    lazy var sitePlacemark = CLPlacemark()
    var searchKey: String?
    
    let apiMethods = APImethods()
    var tourDataModel = TourDataModel()
    
    @IBOutlet weak var parentViewOutlet: UIView!
    @IBOutlet weak var mapViewTour: MKMapView!
    @IBOutlet weak var longPressGestureOutlet: UILongPressGestureRecognizer!
    @IBOutlet weak var tourActivityIndicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapViewTour.delegate = self
        restoredPins()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepMapView()
        checkReachability()
        longPressGestureOutlet.isEnabled = !tourActivityIndicatorView.isAnimating
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityDidChange(_:)), name: NSNotification.Name(rawValue: ReachabilityDidChangeNotificationName), object:nil)
        _ = reachability.startNotifier()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "coreDataCollectionViewController" {
            let  destinationVC = segue.destination as! CoreDataCollectionViewController
            
            let tourFetchResult = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
            tourFetchResult.sortDescriptors = [NSSortDescriptor(key: "text", ascending: true),
                                               NSSortDescriptor(key: "creationDate", ascending: false)]
            
            tourFetchResult.predicate = NSPredicate(format: "text = %@", ((self.searchKey))! )
            
            self.fetchedResultsController = NSFetchedResultsController(fetchRequest: tourFetchResult, managedObjectContext: (self.stack?.context)!, sectionNameKeyPath: nil, cacheName: nil)
            
            destinationVC.fetchedResultsController = self.fetchedResultsController!
            destinationVC.searchKey  = self.searchKey!
        }
    }
    
    
    func prepMapView(){
        
      
        tourActivityIndicatorView.stopAnimating()
        tourActivityIndicatorView.isHidden = true
    }
    
    @IBAction func addGesturePoint(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state ==  .began {
            
            checkReachability()
            
            NotificationCenter.default.addObserver(self, selector: #selector(reachabilityDidChange(_:)), name: NSNotification.Name(rawValue: ReachabilityDidChangeNotificationName), object:nil)
            
            _ = reachability.startNotifier()
            
            //disable mapKit to prevent rapid succession of requests from overlaping
            tourDataModel.activityViewManager(tourActivityIndicatorView)
            longPressGestureOutlet.isEnabled = !tourActivityIndicatorView.isAnimating
            
            //get CGPoint to convert
            let gesturePoint = sender.location(in: self.mapViewTour)
            
            let annotation = MKPointAnnotation()
            let siteCoordinates = self.mapViewTour.convert(gesturePoint, toCoordinateFrom: self.mapViewTour)
            
            //CLLocations are required for reverse geoCodes/CLPlacemark
            let geoLocation = generateCLLocation(siteCoordinates)
            
            codeLocation4Placemark(geoLocation, completionHandlerForGeoCode: {[weak self] (success, error) in
                guard success == true else {
                    let actionSheet = UIAlertController(title: "GeoCode ERROR", message: error, preferredStyle: .alert)
                    
                    actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self?.present(actionSheet,animated: true, completion: nil)

                    return
                }
                annotation.coordinate = (siteCoordinates)
                annotation.title = "\(self!.sitePlacemark)"
                
                
                self?.mapViewTour.addAnnotation(annotation)
                
                //start download in background to eliminate load time in collection VC
                self?.apiMethods.geoSearch(siteCoordinates, completionHandlerForGeoSearch: {(success, error) in
                    
                    if success == true {
                        
                        DispatchQueue.main.async {
                            self?.tourDataModel.activityViewManager((self?.tourActivityIndicatorView)!)
                            self?.longPressGestureOutlet.isEnabled = !(self?.tourActivityIndicatorView.isAnimating)!
                        }
                        
                    } else {
                        let actionSheet = UIAlertController(title: "Session ERROR", message: error, preferredStyle: .alert)
                        
                        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        self?.present(actionSheet,animated: true, completion: nil)
                    
                        
                        self?.tourDataModel.activityViewManager((self?.tourActivityIndicatorView)!)
                        self?.longPressGestureOutlet.isEnabled = !(self?.tourActivityIndicatorView.isAnimating)!
                    }
                })
            })
        }
    }
    
    func generateCLLocation(_ coordinate:CLLocationCoordinate2D)->CLLocation {
        
        let newCLLocation = CLLocation(latitude: (coordinate.latitude), longitude: (coordinate.longitude))
        return newCLLocation
    }
    
    func codeLocation4Placemark(_ codeLocation: CLLocation, completionHandlerForGeoCode: @escaping(_ success: Bool,_ error:String)->Void){
        
        self.geocoder.reverseGeocodeLocation(codeLocation) { (placemarks,error) in
            
            guard (error == nil ) else {
                completionHandlerForGeoCode(false,(error?.localizedDescription ?? "geoCoder Error"))
                
                return
            }
            guard let setSitePlacemark = placemarks?.first else {
                completionHandlerForGeoCode(false,(error?.localizedDescription ?? "geoCoder Placemark Error"))
                return
            }
            self.sitePlacemark = setSitePlacemark
            
            TourDataModel.sharedInstance().compareGeoString = "\(setSitePlacemark)"
            
            completionHandlerForGeoCode(true,(""))
        }
    }
        
    
    func restoredPins(){
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        do {
            let searchResults = try self.stack?.context.fetch(fetchRequest)
            
            for result in searchResults as! [Pin]{
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2DMake(result.latitude, result.longitude)
                annotation.title = result.name
                self.mapViewTour.addAnnotation(annotation)
                
            }
        } catch {
            print("error \(error)")
        }
    }
    
    //MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        mapViewTour.reloadInputViews()
        let reuseID = "pin"
        
        var pinView = mapViewTour.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView!.canShowCallout = true
            pinView?.animatesDrop = true
            pinView!.pinTintColor = .green
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        searchKey =  ((view.annotation?.title)!)!
        
        TourDataModel.sharedInstance().compareGeoString = ((view.annotation?.title)!)!
        
        tourDataModel.activityViewManager(self.tourActivityIndicatorView)
        if control == view.rightCalloutAccessoryView {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
                self.performSegue(withIdentifier: "coreDataCollectionViewController", sender: view)
                self.tourDataModel.activityViewManager(self.tourActivityIndicatorView)
            }
        }
        
    }
    
}
extension MapViewController{
    
    //MARK: - network reachability
    
    func checkReachability() {
        let networkState = reachability
        
        
        //green = found connection / red = no connection
        
        if networkState.isReachable {
            
            parentViewOutlet.backgroundColor = UIColor.init(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.5)
            
        } else {
            parentViewOutlet.backgroundColor = UIColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
            
            //MARK: failed connection alert
            let actionSheet = UIAlertController(title: "NETWORK ERROR", message: "Your Internet Connection Cannot Be Detected", preferredStyle: .actionSheet)
           
            let actOnButton = UIAlertAction(title: "Cancel", style: .default, handler: { (action) -> Void in
                self.tourActivityIndicatorView.stopAnimating()
                self.longPressGestureOutlet.isEnabled = !self.tourActivityIndicatorView.isAnimating
               
            })
            actionSheet.addAction(actOnButton)
            //actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(actionSheet,animated: true, completion: nil)
        }
    }
    
    func reachabilityDidChange(_ notification: Notification){
        checkReachability()
    }
    
}





