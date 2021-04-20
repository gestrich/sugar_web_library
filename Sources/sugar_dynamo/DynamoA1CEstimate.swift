//
//  DynamoA1CEstimate.swift
//  
//
//  Created by Bill Gestrich on 3/30/21.
//

import Foundation
import DynamoDB

public struct DynamoA1CEstimate {
    
    public static let partitionKey = DynamoStoreService.partitionKey
    public static let partitionValue: String = "A1C"
    public static let calculationDateKey = DynamoStoreService.sortKey
    public static let valueKey = "value"
    
    let value: Float
    let calculationDate: Date
    
    public init(value: Float, calculationDate: Date){
        self.value = value
        self.calculationDate = calculationDate
    }
    
    public var attributeValues: [String: DynamoDB.AttributeValue] {
        let dictionary = [
            DynamoA1CEstimate.partitionKey: DynamoDB.AttributeValue(s: String(DynamoA1CEstimate.partitionValue)),
            DynamoA1CEstimate.valueKey: DynamoDB.AttributeValue(n: String(value)),
            DynamoA1CEstimate.calculationDateKey: DynamoDB.AttributeValue(s: Utils.iso8601Formatter.string(from: calculationDate))
        ]
        
        return dictionary
    }

    public static func a1cWith(dictionary: [String: DynamoDB.AttributeValue]) -> DynamoA1CEstimate? {
        
        guard let calculationDateString = dictionary[DynamoA1CEstimate.calculationDateKey]?.s, let calculationDate = Utils.iso8601Formatter.date(from: calculationDateString) else {
            return nil
        }
        
        guard let valueString = dictionary[DynamoA1CEstimate.valueKey]?.n, let value = Float(valueString) else {
            return nil
        }
        
        return DynamoA1CEstimate(value: value, calculationDate: calculationDate)
    }
}
