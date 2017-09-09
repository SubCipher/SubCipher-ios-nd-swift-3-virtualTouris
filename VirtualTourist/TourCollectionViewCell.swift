//
//  TourCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Krishna Picart on 7/14/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//

import UIKit

class TourCollectionViewCell: UICollectionViewCell {
    
    //let tourDataModel = TourDataModel()
    //var placeHolderImage = UIImage(named: "placeholder")
    //var tourImage = UIImage()
    
    
    @IBOutlet weak var cellActivityIndicatorOutlet: UIActivityIndicatorView!
    @IBOutlet weak var tourImageForCell: UIImageView!
    @IBOutlet weak var cellTextForImage: UILabel!
    
    
    func setImageForCell(_ galleryImageAtIndex: UIImage?){
        
        self.tourImageForCell.image = galleryImageAtIndex
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout:UICollectionViewLayout,sizeForItemAt indexpath: IndexPath) -> CGSize{
       
        let itemWidth = collectionView.bounds.height / 125
        let itemHeight = collectionView.bounds.width / 125
        return CGSize(width: itemWidth,height: itemHeight)
    }
    
//    override func prepareForReuse()  {
//        super.prepareForReuse()
//        print("cellVIEW REUSE")
//            self.tourImageForCell.image = nil
//            self.cellTextForImage.text = nil
//    }
    
}





