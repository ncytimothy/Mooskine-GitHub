//
//  Note+Extensions.swift
//  Mooskine
//
//  Created by Timothy Ng on 4/11/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import CoreData

extension Note {
    
    // Add Note's creationDate at initialization
    // awakeFromInsert() provides an opportunity to add code into the
    // life cycle of the managed object when it is initially created.
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
    
}
