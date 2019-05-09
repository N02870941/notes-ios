//
//  Set.swift
//  notes
//
//  Created by Vince G on 4/12/19.
//  Copyright © 2019 jabari. All rights reserved.
//

extension Set {
    var asArray: [Element] {
        return [Element](self)
    }
}

extension Set: Stringifiable where Element == Note {
    static func comparator(lhs: Note, rhs: Note) -> Bool {
        if
            let left = lhs.lastEditedDate,
            let right = rhs.lastEditedDate {
            
            return left < right
        }
        
        // TODO: Handle nil cases
        
        return false
    }
    
    var stringified: String {
        return sorted(by: Set.comparator)
            .map { $0.stringified }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
}

extension Set: Loggable where Element == Note {
    private var averageTitleLength: Float {
        guard count > 0 else { return 0 }
        let sum = Float(map { $0.titleLength }.reduce(0, +))
        return sum / Float(count)
    }
    
    private var averageBodyLength: Float {
        guard count > 0 else { return 0 }
        let sum = Float(map { $0.bodyLength }.reduce(0, +))
        return sum / Float(count)
    }
    
    private var maxTitleLength: Int {
        return map { $0.titleLength }.max() ?? 0
    }
    
    private var maxBodyLength: Int {
        return map { $0.bodyLength }.max() ?? 0
    }
    
    private var minTitleLength: Int {
        return map { $0.titleLength }.min() ?? 0
    }
    
    private var minBodyLength: Int {
        return map { $0.bodyLength }.min() ?? 0
    }
    
    var parameters: [String : Any] {
        return [
            "count": count,
            "average_title_length": averageTitleLength,
            "average_body_length":  averageBodyLength,
            "max_title_length":     maxTitleLength,
            "max_body_length":      maxBodyLength,
            "min_title_length":     minTitleLength,
            "min_body_length":      minBodyLength,
        ]
    }
}
