//
//  DynamoSensorChange.swift
//
//
//  Created by Bill Gestrich on 11/7/21.
//

import Foundation
import DynamoDB
import sugar_utils

public struct DynamoSensorChange {
    
    public static let partitionKey = DynamoStoreService.partitionKey
    public static let partitionValue: String = "SensorChange"
    public static let changeDateKey = DynamoStoreService.sortKey
    public static let inventoryCountKey = "inventoryCount"
    
    public let inventoryCount: Int
    public let changeDate: Date
    
    public init(inventoryCount: Int, changeDate: Date){
        self.inventoryCount = inventoryCount
        self.changeDate = changeDate
    }
    
    public var attributeValues: [String: DynamoDB.AttributeValue] {
        let dictionary = [
            DynamoSensorChange.partitionKey: DynamoDB.AttributeValue(s: String(DynamoSensorChange.partitionValue)),
            DynamoSensorChange.inventoryCountKey: DynamoDB.AttributeValue(n: String(inventoryCount)),
            DynamoSensorChange.changeDateKey: DynamoDB.AttributeValue(s: Utils.iso8601Formatter.string(from: changeDate))
        ]
        
        return dictionary
    }

    public static func sensorChangeWith(dictionary: [String: DynamoDB.AttributeValue]) -> DynamoSensorChange? {
        
        guard let changeDateString = dictionary[DynamoSensorChange.changeDateKey]?.s, let changeDate = Utils.iso8601Formatter.date(from: changeDateString) else {
            return nil
        }
        
        guard let inventoryCountString = dictionary[DynamoSensorChange.inventoryCountKey]?.n, let inventoryCount = Int(inventoryCountString) else {
            return nil
        }
        
        return DynamoSensorChange(inventoryCount: inventoryCount, changeDate: changeDate)
    }
}
