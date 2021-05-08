//
//  DynamoTargetOverride.swift
//  
//
//  Created by Bill Gestrich on 2/21/21.
//

import Foundation
import DynamoDB
import sugar_utils

public struct DynamoTargetOverride {
    
    public static let partitionKey = DynamoStoreService.partitionKey
    public static let partitionValue: String = "TargetOverride"
    public static let dateKey = DynamoStoreService.sortKey
    public static let triggeringUserKey = "triggeringUser"
    public static let targetBaseKey = "targetBase"
    
    public let date: Date
    public let targetBase: Int
    public let triggeringUser: String
    
    
    public init(date: Date, targetBase: Int, user: String) {
        self.date = date
        self.targetBase = targetBase
        self.triggeringUser = user
    }
    
    public var attributeValues: [String: DynamoDB.AttributeValue] {
        let dictionary = [
            DynamoTargetOverride.partitionKey: DynamoDB.AttributeValue(s: String(DynamoTargetOverride.partitionValue)),
            DynamoTargetOverride.dateKey: DynamoDB.AttributeValue(s: Utils.iso8601Formatter.string(from: date)),
            DynamoTargetOverride.targetBaseKey: DynamoDB.AttributeValue(n: String(targetBase)),
            DynamoTargetOverride.triggeringUserKey: DynamoDB.AttributeValue(s: triggeringUser),
        ]
        
        return dictionary
    }

    public static func targetOverrideWith(dictionary: [String: DynamoDB.AttributeValue]) -> DynamoTargetOverride? {
        
        guard let date = dictionary[DynamoTargetOverride.dateKey]?.s, let dateAsString = Utils.iso8601Formatter.date(from: date) else {
            return nil
        }
        
        guard let targetBaseString = dictionary[DynamoTargetOverride.targetBaseKey]?.n, let targetBase = Int(targetBaseString) else {
            return nil
        }
        
        guard let user = dictionary[DynamoTargetOverride.triggeringUserKey]?.s else {
            return nil
        }
        
        return DynamoTargetOverride(date: dateAsString, targetBase: targetBase, user: user)
    }
}

