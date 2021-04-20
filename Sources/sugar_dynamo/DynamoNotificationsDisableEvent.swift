//
//  DynamoNotificationsDisableEvent.swift
//
//
//  Created by Bill Gestrich on 12/9/20.
//

import Foundation
import DynamoDB

public struct DynamoNotificationsDisableEvent {
    
    public static let partitionKey = DynamoStoreService.partitionKey
    public static let partitionValue: String = "NotificationsDisable"
    public static let dateKey = DynamoStoreService.sortKey
    public static let triggeringUserKey = "triggeringUser"
    public static let minutesKey = "minutes"
    
    public let date: Date
    public let minutes: Int
    public let triggeringUser: String
    
    
    public init(date: Date, minutes: Int, user: String) {
        self.date = date
        self.minutes = minutes
        self.triggeringUser = user
    }
    
    public var attributeValues: [String: DynamoDB.AttributeValue] {
        let dictionary = [
            DynamoNotificationsDisableEvent.partitionKey: DynamoDB.AttributeValue(s: String(DynamoNotificationsDisableEvent.partitionValue)),
            DynamoNotificationsDisableEvent.dateKey: DynamoDB.AttributeValue(s: Utils.iso8601Formatter.string(from: date)),
            DynamoNotificationsDisableEvent.minutesKey: DynamoDB.AttributeValue(n: String(minutes)),
            DynamoNotificationsDisableEvent.triggeringUserKey: DynamoDB.AttributeValue(s: triggeringUser),
        ]
        
        return dictionary
    }

    public static func eventWith(dictionary: [String: DynamoDB.AttributeValue]) -> DynamoNotificationsDisableEvent? {
        
        guard let date = dictionary[DynamoNotificationsDisableEvent.dateKey]?.s, let dateAsString = Utils.iso8601Formatter.date(from: date) else {
            return nil
        }
        
        guard let minutesString = dictionary[DynamoNotificationsDisableEvent.minutesKey]?.n, let minutes = Int(minutesString) else {
            
            return nil
        }
        
        guard let user = dictionary[DynamoNotificationsDisableEvent.triggeringUserKey]?.s else {
            return nil
        }
        
        return DynamoNotificationsDisableEvent(date: dateAsString, minutes: minutes, user: user)
    }
    
    public func userDescription() -> String {
        let now = Date()
        let latestDisabledDate = date.adding(minutes: minutes)
        if now < latestDisabledDate {
            let remaningMinutes = latestDisabledDate.timeIntervalSince(now) / 60.0
            return "Phone Notifications Disabled for \(Int(remaningMinutes)) minutes"
        } else {
            return "Phone Notifications were previously disabled for \(Int(minutes)) minutes"
        }

    }
}

