//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by knax on 7/17/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//

import Foundation
import CoreData


public class Pin: NSManagedObject {
    
    
    convenience init(name: String, context: NSManagedObjectContext) {
        
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            
            self.init(entity: ent, insertInto: context)
            self.name = name;
            self.creationDate = Date()
            self.latitude = 0.0
            self.longitude = 0.0
        } else {
            fatalError("unable to find entity name!")
        }
    }
}
