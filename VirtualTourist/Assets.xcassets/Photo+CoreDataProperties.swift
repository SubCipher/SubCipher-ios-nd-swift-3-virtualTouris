//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by knax on 7/17/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var creationDate: Date?
    @NSManaged public var photoFromTour: Data?
    @NSManaged public var text: String?
    @NSManaged public var pin: Pin?

}
