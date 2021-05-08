//
//  DynamoNotificationEvent.swift
//  
//
//  Created by Bill Gestrich on 12/9/20.
//

import Foundation
import DynamoDB
import sugar_utils

public struct DynamoNotificationEvent {
    
    public static let partitionKey = DynamoStoreService.partitionKey
    public static let partitionValue: String = "Notification"
    public static let dateKey = DynamoStoreService.sortKey
    public static let eventTypeKey = "eventType"
    public static let userKey = "user"
    public static let stateUUIDKey = "stateUUID"
    
    public static let phoneEventType = "phone"
    public static let textMessageEventType = "textMessage"
    public static let acknowledgedEventType = "acknowledged"
    public static let declinedEventType = "declined"
    
    public let date: Date
    public let eventType: String
    public let user: String
    public let stateUUID: String
    
    
    public init(date: Date, eventType: String, user: String, stateUUID: String) {
        self.date = date
        self.eventType = eventType
        self.user = user
        self.stateUUID = stateUUID
    }
    
    public var attributeValues: [String: DynamoDB.AttributeValue] {
        let dictionary = [
            DynamoNotificationEvent.partitionKey: DynamoDB.AttributeValue(s: String(DynamoNotificationEvent.partitionValue)),
            DynamoNotificationEvent.dateKey: DynamoDB.AttributeValue(s: Utils.iso8601Formatter.string(from: date)),
            DynamoNotificationEvent.eventTypeKey: DynamoDB.AttributeValue(s: eventType),
            DynamoNotificationEvent.userKey: DynamoDB.AttributeValue(s: user),
            DynamoNotificationEvent.stateUUIDKey: DynamoDB.AttributeValue(s: stateUUID),
        ]
        
        return dictionary
    }

    public static func eventWith(dictionary: [String: DynamoDB.AttributeValue]) -> DynamoNotificationEvent? {
        
        guard let date = dictionary[DynamoNotificationEvent.dateKey]?.s, let dateAsString = Utils.iso8601Formatter.date(from: date) else {
            return nil
        }
        
        guard let eventType = dictionary[DynamoNotificationEvent.eventTypeKey]?.s else {
            return nil
        }
        
        guard let user = dictionary[DynamoNotificationEvent.userKey]?.s else {
            return nil
        }
        
        guard let stateUUID = dictionary[DynamoNotificationEvent.stateUUIDKey]?.s else {
            return nil
        }
        
        return DynamoNotificationEvent(date: dateAsString, eventType: eventType, user: user, stateUUID: stateUUID)
    }
}


