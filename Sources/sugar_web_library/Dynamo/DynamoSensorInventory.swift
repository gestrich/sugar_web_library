//
//  DynamoSensorInventory.swift
//
//
//  Created by Bill Gestrich on 11/7/21.
//

import Foundation
import DynamoDB
import sugar_utils

public struct DynamoSensorInventory {
    
    public static let partitionKey = DynamoStoreService.partitionKey
    public static let partitionValue: String = "SensorInventory"
    public static let date = DynamoStoreService.sortKey
    public static let inventoryCountKey = "inventoryCount"
    
    public let inventoryCount: Int
    public let inventoryDate: Date
    
    public init(inventoryCount: Int, inventoryDate: Date){
        self.inventoryCount = inventoryCount
        self.inventoryDate = inventoryDate
    }
    
    public var attributeValues: [String: DynamoDB.AttributeValue] {
        let dictionary = [
            DynamoSensorInventory.partitionKey: DynamoDB.AttributeValue(s: String(DynamoSensorInventory.partitionValue)),
            DynamoSensorInventory.inventoryCountKey: DynamoDB.AttributeValue(n: String(inventoryCount)),
            DynamoSensorInventory.date: DynamoDB.AttributeValue(s: Utils.iso8601Formatter.string(from: inventoryDate))
        ]
        
        return dictionary
    }

    public static func sensorInventoryWith(dictionary: [String: DynamoDB.AttributeValue]) -> DynamoSensorInventory? {
        
        guard let inventoryDateString = dictionary[DynamoSensorInventory.date]?.s, let inventoryDate = Utils.iso8601Formatter.date(from: inventoryDateString) else {
            return nil
        }
        
        guard let inventoryCountString = dictionary[DynamoSensorInventory.inventoryCountKey]?.n, let inventoryCount = Int(inventoryCountString) else {
            return nil
        }
        
        return DynamoSensorInventory(inventoryCount: inventoryCount, inventoryDate: inventoryDate)
    }
}
