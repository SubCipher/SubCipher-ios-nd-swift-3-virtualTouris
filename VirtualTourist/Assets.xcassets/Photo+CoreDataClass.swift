//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by knax on 7/17/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//

import Foundation
import CoreData


public class Photo: NSManagedObject {

    convenience init(photoFromTour: Data,text: String = "New Newphoto", context:NSManagedObjectContext) {
        
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            
            self.text = text
            self.creationDate = Date()
            self.photoFromTour = Data()
            
            
        } else {
            fatalError("cannot find entity name!")
        }
    }
    
    var humanReadableAge: String {
        get {
            let fmt = DateFormatter()
            fmt.timeStyle = .none
            fmt.dateStyle = .short
            fmt.doesRelativeDateFormatting = true
            fmt.locale = Locale.current
            return fmt.string(from: creationDate! as Date)
        }
    }
}

