 //
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Krishna Picart on 7/8/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let stack = TourCoreDataStack(modelName: "TourModel")!
    //let tourDataModel = TourDataModel()
    
    //Preload data
    func preloadData() {
        
        do {  try stack.dropAllData() } catch {  print("error dropping all objects")  }  }
 
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
       //preloadData()
        stack.autoSave(60)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        
        do { try stack.saveContext() } catch {  print("Error while saving.") } }

    func applicationDidEnterBackground(_ application: UIApplication) {

        do { try stack.saveContext() } catch { print("error while saving") } }

       func applicationWillTerminate(_ application: UIApplication) {
        //Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
}



