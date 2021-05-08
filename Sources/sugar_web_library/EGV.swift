//
//  EGV.swift
//  
//
//  Created by Bill Gestrich on 11/8/20.
//

import Foundation

public struct EGV {
    public let value: Int
    public let systemTime: Date
    public let displayTime: Date
    public let realtimeValue: Int?
    public let smoothedValue: Int?
    public let trendRate: Float?
    public let trendDescription: String
    
    public init(value: Int, systemTime: Date, displayTime: Date, realtimeValue: Int?, smoothedValue: Int?, trendRate: Float?, trendDescription: String){
        self.value = value
        self.systemTime = systemTime
        self.displayTime = displayTime
        self.realtimeValue = realtimeValue
        self.smoothedValue = smoothedValue
        self.trendRate = trendRate
        self.trendDescription = trendDescription
    }
    
    public var debugDescription: String {
        return "\(displayTime): \(value), (\(trendDescription) \(trendRate ?? 0.0))"
    }
    
    public func simpleDescription() ->  String {
        return "\(value)"
    }
    
    public func displayDateDescription() -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.timeZone = TimeZone(identifier: "EST")
        dateFormatterPrint.dateFormat = "h:mm a"
        return dateFormatterPrint.string(from: displayTime)
    }
    
    public func fullDescription() -> String {
        var toRet = "\(simpleDescription()), "
        toRet += displayDateDescription()
        return toRet
    }
}

extension EGV: SugarEvent {
    
    public var date: Date {
        return self.systemTime
    }
    
    public func inlineDescription() -> String {
        return "\(dateDescription()) EGV \(self.value)"
    }
}

extension Array where Element == EGV {
    
    public func calculateA1C() -> Float? {
        
        guard self.count > 0 else {
            return nil
        }
        
        let totalEGVs = self.reduce(0) { (partialSum, event) -> Float in
            return partialSum + Float(event.value)
        }
        
        let average = totalEGVs / Float(self.count)
        let a1cValue = (46.7 + average) / 28.7
        return a1cValue
    }
}

public enum SugarMonitorError: Error {
    case failedLogin(msg: String)
    case failedConnection(msg: String)
}
