//
//  DynamoInsulinOverride.swift
//  
//
//  Created by Bill Gestrich on 2/20/21.
//

import Foundation
import DynamoDB

public struct DynamoInsulinOverride {
    
    public static let partitionKey = DynamoStoreService.partitionKey
    public static let partitionValue: String = "InsulinOverride"
    public static let dateKey = DynamoStoreService.sortKey
    public static let triggeringUserKey = "triggeringUser"
    public static let insulinPercentKey = "insulinPercent"
    
    public let date: Date
    public let insulinPercent: Int
    public let triggeringUser: String
    
    
    public init(date: Date, insulinPercent: Int, user: String) {
        self.date = date
        self.insulinPercent = insulinPercent
        self.triggeringUser = user
    }
    
    public var attributeValues: [String: DynamoDB.AttributeValue] {
        let dictionary = [
            DynamoInsulinOverride.partitionKey: DynamoDB.AttributeValue(s: String(DynamoInsulinOverride.partitionValue)),
            DynamoInsulinOverride.dateKey: DynamoDB.AttributeValue(s: Utils.iso8601Formatter.string(from: date)),
            DynamoInsulinOverride.insulinPercentKey: DynamoDB.AttributeValue(n: String(insulinPercent)),
            DynamoInsulinOverride.triggeringUserKey: DynamoDB.AttributeValue(s: triggeringUser),
        ]
        
        return dictionary
    }

    public static func insulinOverrideWith(dictionary: [String: DynamoDB.AttributeValue]) -> DynamoInsulinOverride? {
        
        guard let date = dictionary[DynamoInsulinOverride.dateKey]?.s, let dateAsString = Utils.iso8601Formatter.date(from: date) else {
            return nil
        }
        
        guard let insulinPercentString = dictionary[DynamoInsulinOverride.insulinPercentKey]?.n, let insulinPercent = Int(insulinPercentString) else {
            return nil
        }
        
        guard let user = dictionary[DynamoInsulinOverride.triggeringUserKey]?.s else {
            return nil
        }
        
        return DynamoInsulinOverride(date: dateAsString, insulinPercent: insulinPercent, user: user)
    }
}



