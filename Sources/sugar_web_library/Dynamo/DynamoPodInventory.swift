//
//  DynamoPodInventory.swift
//
//
//  Created by Bill Gestrich on 11/7/21.
//

import Foundation
import DynamoDB
import sugar_utils

public struct DynamoPodInventory {
    
    public static let partitionKey = DynamoStoreService.partitionKey
    public static let partitionValue: String = "PodInventory"
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
            DynamoPodInventory.partitionKey: DynamoDB.AttributeValue(s: String(DynamoPodInventory.partitionValue)),
            DynamoPodInventory.inventoryCountKey: DynamoDB.AttributeValue(n: String(inventoryCount)),
            DynamoPodInventory.date: DynamoDB.AttributeValue(s: Utils.iso8601Formatter.string(from: inventoryDate))
        ]
        
        return dictionary
    }

    public static func podInventoryWith(dictionary: [String: DynamoDB.AttributeValue]) -> DynamoPodInventory? {
        
        guard let inventoryDateString = dictionary[DynamoPodInventory.date]?.s, let inventoryDate = Utils.iso8601Formatter.date(from: inventoryDateString) else {
            return nil
        }
        
        guard let inventoryCountString = dictionary[DynamoPodInventory.inventoryCountKey]?.n, let inventoryCount = Int(inventoryCountString) else {
            return nil
        }
        
        return DynamoPodInventory(inventoryCount: inventoryCount, inventoryDate: inventoryDate)
    }
}
