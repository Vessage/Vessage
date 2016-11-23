//
//  VTMRecord+CoreDataClass.swift
//  Vessage
//
//  Created by Alex Chow on 2016/11/23.
//  Copyright © 2016年 Bahamut. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData

class VTMRecord: NSManagedObject {
    @NSManaged var chatterId: String
    @NSManaged var mtime: NSNumber
    @NSManaged var modelValue: String
    @NSManaged var ctime: NSNumber
}
