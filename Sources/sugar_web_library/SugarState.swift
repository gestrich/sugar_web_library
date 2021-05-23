//
//  SugarState.swift
//
//
//  Created by Bill Gestrich on 12/9/20.
//

import Foundation
import sugar_utils

public struct SugarState {
    public let type: SugarStateType
    public let date: Date
    public let message: String
    public let urgency: SugarStateUrgency
    public let egv: EGV?
    public var a1c: Float?
    
    public init(type: SugarStateType, date: Date, message: String, urgency: SugarStateUrgency, egv: EGV? = nil, a1c: Float? = nil) {
        self.type = type
        self.date = date
        self.message = message
        self.urgency = urgency
        self.egv = egv
        self.a1c = a1c
    }
    
    public func key() -> String {
        return type.rawValue + "-" + date.iso8601
    }
    
    public func acknowledgeTimeFrame() -> TimeInterval {
        switch urgency {
        case .none, .success:
            return 0
        case .low:
            return 0
        case .medium:
            return 25 * 60
        case .high:
            return 10 * 60
        }
    }
    
    public func requiresAcknowledgement() -> Bool {
        switch urgency {
        case .none, .success:
            return false
        case .low:
            return false
        case .medium:
            return true
        case .high:
            return true
        }
    }
    
}

public enum SugarStateType: String {
    case sugarUnder60
    case sugar60to100
//    case sugar60to70
//    case sugar70to80
//    case sugar80to90
//    case sugar90to100
    case sugarNormal
    case sugar200to300
    case sugarOver300
    case carbPrematureTime
    case carbMissingBolus
    case lowOverride
    case connection
    case lowPump
    case test
    case a1c
}

public enum SugarStateUrgency {
    case none
    case success
    case low
    case medium
    case high
}
/*
public enum SugarState {
    
    case urgentLow(egv: EGV?)
    case low(egv: EGV?)
    case ok(egv: EGV?)
    case high(egv: EGV?)
    case urgentHigh(egv: EGV?)
    case connection(msg: String)
    
    static func getStateWithEGV(_ egv: EGV) -> SugarState {
        if egv.value < 65 {
            return .urgentLow(egv: egv)
        } else if egv.value < 85 {
            return .low(egv: egv)
        } else if egv.value < 180 {
            return .ok(egv: egv)
        } else if egv.value < 250 {
            return .high(egv: egv)
        } else {
            return .urgentHigh(egv: egv)
        }
    }
    
    static func getConnectionErrorStateWithMessage(_ message: String) -> SugarState {
        return .connection(msg: message)
    }
}

 */
