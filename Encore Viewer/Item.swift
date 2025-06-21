//
//  Item.swift
//  Encore Viewer
//
//  Created by Taine Noble on 22/6/2025.
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
