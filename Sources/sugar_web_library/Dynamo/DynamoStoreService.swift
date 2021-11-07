//
//  DynamoStoreService.swift
//  
//
//  Created by Bill Gestrich on 11/8/20.
//

import Foundation
import NIO
import DynamoDB
import sugar_utils

public struct DynamoStoreService {
    
    public static let partitionKey = "partitionKey"
    public static let sortKey = "sort"
    public static let testDatabaseName = "EGVTest"
    
    let db: DynamoDB
    let tableName: String
    
    
    //General
    
    public init(db: DynamoDB = DynamoDB(region: Region.useast1), tableName: String) {
        self.db = db
        self.tableName = tableName
    }
    
    public func createTable() -> EventLoopFuture<DynamoDB.CreateTableOutput> {
        
        let keySchema = [
            DynamoDB.KeySchemaElement(attributeName: DynamoStoreService.partitionKey, keyType: .hash),
            DynamoDB.KeySchemaElement(attributeName: DynamoStoreService.sortKey, keyType: .range),
        ]
        
        let attributeDefinitions = [
            DynamoDB.AttributeDefinition(attributeName: DynamoStoreService.partitionKey, attributeType: .s),
            DynamoDB.AttributeDefinition(attributeName: DynamoStoreService.sortKey, attributeType: .s),
        ]
        
        let provisionThroughput = DynamoDB.ProvisionedThroughput(readCapacityUnits: 5, writeCapacityUnits: 5)
        
        let tableInput = DynamoDB.CreateTableInput(attributeDefinitions: attributeDefinitions, keySchema: keySchema, provisionedThroughput: provisionThroughput, tableName: tableName)
        
        return db.createTable(tableInput)
    }
    
    public func getItems(partition: String, startSort: String, endSort: String) -> EventLoopFuture<DynamoDB.QueryOutput> {
        
        return db.query(.init(
            expressionAttributeNames: ["#u" : DynamoStoreService.partitionKey],
            expressionAttributeValues: [":u": .init(s: partition), ":d1" : .init(s: startSort), ":d2" : .init(s: endSort)],
            keyConditionExpression: "#u = :u AND \(DynamoStoreService.sortKey) BETWEEN :d1 AND :d2",
            tableName: tableName
        ))
    }
    
    
    //MARK: EGV
    
    public func storeEGV(_ egv: DynamoEGV) -> EventLoopFuture<DynamoEGV> {

        let input = DynamoDB.PutItemInput(item: egv.attributeValues, tableName: tableName)
        return db.putItem(input).map { (_) -> DynamoEGV in
            egv
        }
    }
    
    public func getEGVsSinceDate(oldestDate: Date, latestDate: Date) -> EventLoopFuture<[DynamoEGV]> {
        
        let oldestDateAsString = Utils.iso8601Formatter.string(from: oldestDate)
        let currentDateAsString = Utils.iso8601Formatter.string(from: latestDate)
        
        return getItems(partition: DynamoEGV.partitionValue, startSort: oldestDateAsString, endSort: currentDateAsString).map { (output) -> [DynamoEGV] in
            let egvValues = output.items?.compactMap({ (dict) -> DynamoEGV? in
                return DynamoEGV.egvWith(dictionary: dict)
            }) ?? []
            
            return egvValues
        }
    }
    
    public func getEGVsInPastMinutes(_ minutes: Int, referenceDate: Date) -> EventLoopFuture<[DynamoEGV]> {
        let interval = TimeInterval(minutes) * -60
        let date = referenceDate.addingTimeInterval(interval)
        return self.getEGVsSinceDate(oldestDate: date, latestDate: referenceDate)
    }
    
    public func getLatestEGV() -> EventLoopFuture<DynamoEGV?> {
        self.getEGVsInPastMinutes(60, referenceDate: Date()).map { (egvs) -> DynamoEGV? in
            return egvs.last
        }
    }
    
    
    //MARK: A1C
    
    public func storeA1C(_ a1c: DynamoA1CEstimate) -> EventLoopFuture<DynamoA1CEstimate> {
        let input = DynamoDB.PutItemInput(item: a1c.attributeValues, tableName: tableName)
        return db.putItem(input).map { (_) -> DynamoA1CEstimate in
            a1c
        }
    }
    
    public func getA1CsSinceDate(oldestDate: Date, latestDate: Date) -> EventLoopFuture<[DynamoA1CEstimate]> {
        
        let oldestDateAsString = Utils.iso8601Formatter.string(from: oldestDate)
        let currentDateAsString = Utils.iso8601Formatter.string(from: latestDate)
        
        return getItems(partition: DynamoA1CEstimate.partitionValue, startSort: oldestDateAsString, endSort: currentDateAsString).map { (output) -> [DynamoA1CEstimate] in
            let a1cValues = output.items?.compactMap({ (dict) -> DynamoA1CEstimate? in
                return DynamoA1CEstimate.a1cWith(dictionary: dict)
            }) ?? []
            
            return a1cValues
        }
    }
    
    public func getA1CsInPastMinutes(_ minutes: Int, referenceDate: Date) -> EventLoopFuture<[DynamoA1CEstimate]> {
        let interval = TimeInterval(minutes) * -60
        let date = referenceDate.addingTimeInterval(interval)
        return self.getA1CsSinceDate(oldestDate: date, latestDate: referenceDate)
    }
    
    public func getLatestA1C(referenceDate: Date) -> EventLoopFuture<DynamoA1CEstimate?> {
        self.getA1CsInPastMinutes(60 * 24, referenceDate: referenceDate).map { (a1cs) -> DynamoA1CEstimate? in
            return a1cs.last
        }
    }
    
    
    //MARK: User
    
    public func storeUser(user: DynamoUser) ->  EventLoopFuture<DynamoUser> {

        let input = DynamoDB.PutItemInput(item: user.attributeValues, tableName: tableName)
        return db.putItem(input).map { (_) -> DynamoUser in
            user
        }
    }
    
    public func getUser(name: String) -> EventLoopFuture<[DynamoUser]> {
        
        return getItems(partition: DynamoUser.partitionValue, startSort: name, endSort: name).map { (output) -> [DynamoUser] in
            let userValues = output.items?.compactMap({ (dict) -> DynamoUser? in
                return DynamoUser.userWith(dictionary: dict)
            }) ?? []
            
            return userValues
        }
    }
    
    public func getUser(phone: String) -> EventLoopFuture<DynamoUser?> {
        return getAllUsers().map { (users) -> DynamoUser? in
            return users.filter { (tempUser) -> Bool in
                return tempUser.phone == phone
            }.last
        }
    }
    
    public func getAllUsers() -> EventLoopFuture<[DynamoUser]> {
        
        return getItems(partition: DynamoUser.partitionValue, startSort: "A", endSort: "ZZZZZZZZZZZZZZZZZZZZZZZZZZ").map { (output) -> [DynamoUser] in
            let userValues = output.items?.compactMap({ (dict) -> DynamoUser? in
                return DynamoUser.userWith(dictionary: dict)
            }) ?? []
            
            return userValues
        }
    }
    
    
    
    
    //MARK: Notification Event
    
    public func storeNotificationEvent(event: DynamoNotificationEvent) ->  EventLoopFuture<DynamoNotificationEvent> {

        let input = DynamoDB.PutItemInput(item: event.attributeValues, tableName: tableName)
        return db.putItem(input).map { (_) -> DynamoNotificationEvent in
            event
        }
    }
    
    public func getNotificationEventSinceDate(oldestDate: Date, latestDate: Date) -> EventLoopFuture<[DynamoNotificationEvent]> {
        
        let currentDateAsString = Utils.iso8601Formatter.string(from: latestDate)
        let oldestDateAsString = Utils.iso8601Formatter.string(from: oldestDate)
        
        return getItems(partition: DynamoNotificationEvent.partitionValue, startSort: oldestDateAsString, endSort: currentDateAsString).map { (output) -> [DynamoNotificationEvent] in
            let events = output.items?.compactMap({ (dict) -> DynamoNotificationEvent? in
                return DynamoNotificationEvent.eventWith(dictionary: dict)
            }) ?? []
            
            return events
        }
    }
    
    public func getRecentNotificationEvents(minutes: Int, referenceDate: Date) -> EventLoopFuture<[DynamoNotificationEvent]> {
        
        let lookbackDate = referenceDate.adding(minutes: -minutes)
        
        return self.getNotificationEventSinceDate(oldestDate: lookbackDate, latestDate: referenceDate).map { (events) -> [DynamoNotificationEvent] in
            return events
        }
    }
    
    
    //MARK: Notification Disable Event
    
    public func storeNotificationDisableEvent(event: DynamoNotificationsDisableEvent) ->  EventLoopFuture<DynamoNotificationsDisableEvent> {

        let input = DynamoDB.PutItemInput(item: event.attributeValues, tableName: tableName)
        return db.putItem(input).map { (_) -> DynamoNotificationsDisableEvent in
            event
        }
    }
    
    public func getNotificationDisableEventsSinceDate(oldestDate: Date, latestDate: Date) -> EventLoopFuture<[DynamoNotificationsDisableEvent]> {
        
        let currentDateAsString = Utils.iso8601Formatter.string(from: latestDate)
        let oldestDateAsString = Utils.iso8601Formatter.string(from: oldestDate)
        
        return getItems(partition: DynamoNotificationsDisableEvent.partitionValue, startSort: oldestDateAsString, endSort: currentDateAsString).map { (output) -> [DynamoNotificationsDisableEvent] in
            let events = output.items?.compactMap({ (dict) -> DynamoNotificationsDisableEvent? in
                return DynamoNotificationsDisableEvent.eventWith(dictionary: dict)
            }) ?? []
            
            return events
        }
    }
    
    public func activeNotificationsDisabledEvent(nowDate: Date) -> EventLoopFuture<DynamoNotificationsDisableEvent?> {
        let lookbackMinutes = -60 * 24
        let oldestDate = nowDate.adding(minutes: lookbackMinutes)
        return getNotificationDisableEventsSinceDate(oldestDate: oldestDate, latestDate: nowDate).map { (events) in
            let eventsDescending = events.sorted(by:{$0.date > $1.date})
            guard let latestEvent = eventsDescending.first else {
                return nil
            }
            
            let disabledUntil = latestEvent.date.adding(minutes: latestEvent.minutes)
            
            if nowDate.timeIntervalSince(disabledUntil) > 0 {
                //past
                return nil
            } else {
                return latestEvent
            }
        }

    }
    
    
    //MARK: Insulin Override
    
    public func storeInsulinOverride(override: DynamoInsulinOverride) ->  EventLoopFuture<DynamoInsulinOverride> {

        let input = DynamoDB.PutItemInput(item: override.attributeValues, tableName: tableName)
        return db.putItem(input).map { (_) -> DynamoInsulinOverride in
            override
        }
    }
    
    public func getInulinOverridesSinceDate(oldestDate: Date, latestDate: Date) -> EventLoopFuture<[DynamoInsulinOverride]> {
        
        let currentDateAsString = Utils.iso8601Formatter.string(from: latestDate)
        let oldestDateAsString = Utils.iso8601Formatter.string(from: oldestDate)
        
        return getItems(partition: DynamoInsulinOverride.partitionValue, startSort: oldestDateAsString, endSort: currentDateAsString).map { (output) -> [DynamoInsulinOverride] in
            let events = output.items?.compactMap({ (dict) -> DynamoInsulinOverride? in
                return DynamoInsulinOverride.insulinOverrideWith(dictionary: dict)
            }) ?? []
            
            return events
        }
    }
    
    public func activeInsulinOverride(nowDate: Date) -> EventLoopFuture<DynamoInsulinOverride?> {
        let lookbackMinutes = -60 * 24 * 365
        let oldestDate = nowDate.adding(minutes: lookbackMinutes)
        return getInulinOverridesSinceDate(oldestDate: oldestDate, latestDate: nowDate).map { (events) in
            let eventsDescending = events.sorted(by:{$0.date > $1.date})
            return eventsDescending.first
        }
    }

    
    //MARK: Target Override
    
    public func storeTargetOverride(override: DynamoTargetOverride) ->  EventLoopFuture<DynamoTargetOverride> {

        let input = DynamoDB.PutItemInput(item: override.attributeValues, tableName: tableName)
        return db.putItem(input).map { (_) -> DynamoTargetOverride in
            override
        }
    }
    
    public func getTargetOverridesSinceDate(oldestDate: Date, latestDate: Date) -> EventLoopFuture<[DynamoTargetOverride]> {
        
        let currentDateAsString = Utils.iso8601Formatter.string(from: latestDate)
        let oldestDateAsString = Utils.iso8601Formatter.string(from: oldestDate)
        
        return getItems(partition: DynamoTargetOverride.partitionValue, startSort: oldestDateAsString, endSort: currentDateAsString).map { (output) -> [DynamoTargetOverride] in
            let events = output.items?.compactMap({ (dict) -> DynamoTargetOverride? in
                return DynamoTargetOverride.targetOverrideWith(dictionary: dict)
            }) ?? []
            
            return events
        }
    }
    
    public func activeTargetOverride(nowDate: Date) -> EventLoopFuture<DynamoTargetOverride?> {
        let lookbackMinutes = -60 * 24 * 365
        let oldestDate = nowDate.adding(minutes: lookbackMinutes)
        return getTargetOverridesSinceDate(oldestDate: oldestDate, latestDate: nowDate).map { (events) in
            let eventsDescending = events.sorted(by:{$0.date > $1.date})
            return eventsDescending.first
        }
    }
    
    public func getOverrides(nowDate: Date) -> EventLoopFuture<(insulinOverride: DynamoInsulinOverride?, targetOverride: DynamoTargetOverride?)> {
        var insulinOverride: DynamoInsulinOverride? = nil
        var targetOverride: DynamoTargetOverride? = nil

        return activeInsulinOverride(nowDate: nowDate).flatMap { (fetchedInsulinOverride) in
            insulinOverride = fetchedInsulinOverride
            return self.activeTargetOverride(nowDate: nowDate).map { (fetchedTargetOverride) in
                targetOverride = fetchedTargetOverride
                return (insulinOverride, targetOverride)
            }
        }
    }
    
    
    //MARK: Sensor Change
    
    public func storeSensorChange(_ sensorChange: DynamoSensorChange) -> EventLoopFuture<DynamoSensorChange> {
        let input = DynamoDB.PutItemInput(item: sensorChange.attributeValues, tableName: tableName)
        return db.putItem(input).map { (_) -> DynamoSensorChange in
            sensorChange
        }
    }
    
    public func getSensorChangesSinceDate(oldestDate: Date, latestDate: Date) -> EventLoopFuture<[DynamoSensorChange]> {
        
        let oldestDateAsString = Utils.iso8601Formatter.string(from: oldestDate)
        let currentDateAsString = Utils.iso8601Formatter.string(from: latestDate)
        
        return getItems(partition: DynamoSensorChange.partitionValue, startSort: oldestDateAsString, endSort: currentDateAsString).map { (output) -> [DynamoSensorChange] in
            return output.items?.compactMap({ (dict) -> DynamoSensorChange? in
                return DynamoSensorChange.sensorChangeWith(dictionary: dict)
            }) ?? []
        }
    }
    
    public func getSensorChangesInPastMinutes(_ minutes: Int, referenceDate: Date) -> EventLoopFuture<[DynamoSensorChange]> {
        let interval = TimeInterval(minutes) * -60
        let date = referenceDate.addingTimeInterval(interval)
        return self.getSensorChangesSinceDate(oldestDate: date, latestDate: referenceDate)
    }
    
    public func getLatestSensorChange(referenceDate: Date) -> EventLoopFuture<DynamoSensorChange?> {
        //Support last 60 days.
        self.getSensorChangesInPastMinutes(60 * 24 * 60, referenceDate: referenceDate).map { (sensorChanges) -> DynamoSensorChange? in
            return sensorChanges.last
        }
    }
    
    
    //MARK: Sensor Inventory
    
    public func storeSensorInventory(_ sensorInventory: DynamoSensorInventory) -> EventLoopFuture<DynamoSensorInventory> {
        let input = DynamoDB.PutItemInput(item: sensorInventory.attributeValues, tableName: tableName)
        return db.putItem(input).map { (_) -> DynamoSensorInventory in
            sensorInventory
        }
    }
    
    public func getSensorInventoriesSinceDate(oldestDate: Date, latestDate: Date) -> EventLoopFuture<[DynamoSensorInventory]> {
        
        let oldestDateAsString = Utils.iso8601Formatter.string(from: oldestDate)
        let currentDateAsString = Utils.iso8601Formatter.string(from: latestDate)
        
        return getItems(partition: DynamoSensorInventory.partitionValue, startSort: oldestDateAsString, endSort: currentDateAsString).map { (output) -> [DynamoSensorInventory] in
            return output.items?.compactMap({ (dict) -> DynamoSensorInventory? in
                return DynamoSensorInventory.sensorInventoryWith(dictionary: dict)
            }) ?? []
        }
    }
    
    public func getSensorInventoriesInPastMinutes(_ minutes: Int, referenceDate: Date) -> EventLoopFuture<[DynamoSensorInventory]> {
        let interval = TimeInterval(minutes) * -60
        let date = referenceDate.addingTimeInterval(interval)
        return self.getSensorInventoriesSinceDate(oldestDate: date, latestDate: referenceDate)
    }
    
    public func getLatestSensorInventory(referenceDate: Date) -> EventLoopFuture<DynamoSensorInventory?> {
        //Support last 60 days.
        self.getSensorInventoriesInPastMinutes(60 * 24 * 60, referenceDate: referenceDate).map { (sensorInventories) -> DynamoSensorInventory? in
            return sensorInventories.last
        }
    }

}
