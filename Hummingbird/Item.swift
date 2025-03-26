//
//  Item.swift
//  Hummingbird
//
//  Created by Boris Paucinac on 3/26/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
