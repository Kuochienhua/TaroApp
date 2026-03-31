//
//  Item.swift
//  TaroApp
//
//  Created by 郭健華 on 2026/3/31.
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
