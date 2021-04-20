//
//  DynamoEGV.swift
//  
//
//  Created by Bill Gestrich on 11/7/20.
//

import Foundation
import DynamoDB

public struct DynamoEGV {
    
    public static let partitionKey = DynamoStoreService.partitionKey
    public static let partitionValue: String = "EGV"
    public static let systemTimeKey = DynamoStoreService.sortKey
    public static let displayTimeKey = "displayTime"
    public static let trendKey = "trend"
    public static let valueKey = "value"
    
    let trend: Float
    let value: Int
    let displayTime: Date
    let systemTime: Date
    
    
    public var attributeValues: [String: DynamoDB.AttributeValue] {
        var dictionary = [
            DynamoEGV.partitionKey: DynamoDB.AttributeValue(s: String(DynamoEGV.partitionValue)),
            DynamoEGV.trendKey: DynamoDB.AttributeValue(n: String(trend)),
            DynamoEGV.valueKey: DynamoDB.AttributeValue(n: String(value)),
        ]
        
        dictionary[DynamoEGV.displayTimeKey] = DynamoDB.AttributeValue(s: Utils.iso8601Formatter.string(from: displayTime))
        dictionary[DynamoEGV.systemTimeKey] = DynamoDB.AttributeValue(s: Utils.iso8601Formatter.string(from: systemTime))
        
        return dictionary
    }

    public static func egvWith(dictionary: [String: DynamoDB.AttributeValue]) -> DynamoEGV? {
        
        guard let displayTimeString = dictionary[DynamoEGV.displayTimeKey]?.s, let displayTime = Utils.iso8601Formatter.date(from: displayTimeString) else {
            return nil
        }
        
        guard let systemTimeString = dictionary[DynamoEGV.systemTimeKey]?.s, let systemTime = Utils.iso8601Formatter.date(from: systemTimeString) else {
            return nil
        }
        
        guard let trendString = dictionary[DynamoEGV.trendKey]?.n, let trend = Float(trendString) else {
            return nil
        }
        
        guard let valueString = dictionary[DynamoEGV.valueKey]?.n, let value = Int(valueString) else {
            
            return nil
        }
        
        return DynamoEGV(trend: trend, value: value, displayTime: displayTime, systemTime: systemTime)
    }
}

