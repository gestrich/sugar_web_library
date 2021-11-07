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
    public static let inputDateKey = DynamoStoreService.sortKey
    public static let changeDateKey = "changeDate"
    
    public let inputDate: Date
    public let changeDate: Date
    
    public init(changeDate: Date, inputDate: Date){
        self.changeDate = changeDate
        self.inputDate = inputDate
    }
    
    public var attributeValues: [String: DynamoDB.AttributeValue] {
        let dictionary = [
            DynamoSensorChange.partitionKey: DynamoDB.AttributeValue(s: String(DynamoSensorChange.partitionValue)),
            DynamoSensorChange.inputDateKey: DynamoDB.AttributeValue(s: Utils.iso8601Formatter.string(from: inputDate)),
            DynamoSensorChange.changeDateKey: DynamoDB.AttributeValue(s: Utils.iso8601Formatter.string(from: changeDate)),
        ]
        
        return dictionary
    }

    public static func sensorChangeWith(dictionary: [String: DynamoDB.AttributeValue]) -> DynamoSensorChange? {
        
        guard let changeDateString = dictionary[DynamoSensorChange.changeDateKey]?.s, let changeDate = Utils.iso8601Formatter.date(from: changeDateString) else {
            return nil
        }
        
        guard let inputDateString = dictionary[DynamoSensorChange.inputDateKey]?.s, let inputDate = Utils.iso8601Formatter.date(from: inputDateString) else {
            return nil
        }
        
        return DynamoSensorChange(changeDate: changeDate, inputDate: inputDate)
    }
}
