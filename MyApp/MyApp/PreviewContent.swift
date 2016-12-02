//
//  PreviewContent.swift
//  MyApp
//
//  Created by Hung Vuong on 12/2/16.
//  Copyright © 2016 Hung Vuong. All rights reserved.
//

import UIKit

class PreviewContent: NSObject, NSCoding {
    // MARK: Properties
    
    var image: UIImage?
    var date: NSString?
    var title: NSString?
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("previewContents")
    
    // MARK: Initialization
    init(image: UIImage?, date: NSString?, title: NSString?) {
        self.image = image
        self.date = date
        self.title = title
        
        super.init()
    }
    
    // MARK: Types
    
    struct PropertyKey {
        static let imageKey = "image"
        static let dateKey = "date"
        static let titleKey = "title"
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(image, forKey: PropertyKey.imageKey)
        aCoder.encode(date, forKey: PropertyKey.dateKey)
        aCoder.encode(title, forKey: PropertyKey.titleKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let image = aDecoder.decodeObject(forKey: PropertyKey.imageKey) as? UIImage
        let date = aDecoder.decodeObject(forKey: PropertyKey.dateKey) as? NSString
        let title = aDecoder.decodeObject(forKey: PropertyKey.titleKey) as? NSString
        
        self.init(image: image, date: date, title: title)
    }
}
