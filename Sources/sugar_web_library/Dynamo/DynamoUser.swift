//
//  DynamoUser.swift
//  
//
//  Created by Bill Gestrich on 12/9/20.
//

import Foundation
import DynamoDB


public struct DynamoUser {
    
    public static let partitionKey = DynamoStoreService.partitionKey
    public static let partitionValue: String = "User"
    public static let nameKey = DynamoStoreService.sortKey
    public static let phoneKey = "phone"
    public static let slackIDKey = "slackID"
    
    public let name: String
    public let phone: String
    public let slackID: String
    
    public init(name: String, phone: String, slackID: String) {
        self.name = name
        self.phone = phone
        self.slackID = slackID
    }
    
    public var attributeValues: [String: DynamoDB.AttributeValue] {
        let dictionary = [
            DynamoUser.partitionKey: DynamoDB.AttributeValue(s: String(DynamoUser.partitionValue)),
            DynamoUser.nameKey: DynamoDB.AttributeValue(s: String(name)),
            DynamoUser.phoneKey: DynamoDB.AttributeValue(s: String(phone)),
            DynamoUser.slackIDKey: DynamoDB.AttributeValue(s: String(slackID)),
        ]
        
        return dictionary
    }

    public static func userWith(dictionary: [String: DynamoDB.AttributeValue]) -> DynamoUser? {
        
        guard let name = dictionary[DynamoUser.nameKey]?.s else {
            return nil
        }
        
        guard let phone = dictionary[DynamoUser.phoneKey]?.s else {
            return nil
        }
        
        guard let slackID = dictionary[DynamoUser.slackIDKey]?.s else {
            return nil
        }
        
        return DynamoUser(name: name, phone: phone, slackID: slackID)
    }
}


