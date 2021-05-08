//
//  NightScoutService.swift
//  
//
//  Created by Bill Gestrich on 12/14/20.
//

import Foundation
import AsyncHTTPClient
import NIO
import Crypto


//API Reference: https://github.com/nightscout/cgm-remote-monitor

public class NightScoutService {
    let baseURL: String
    let secret: String
    let referenceDate: Date
    
    public init(baseURL: String, secret: String, referenceDate: Date){
        self.baseURL = baseURL
        self.secret = secret
        self.referenceDate = referenceDate
    }
    
    //curl -L "<baseURL>/api/v1/entries.json" | jq
    // curl -L -g '<baseURL>/api/v1/entries/sgv.json?find[dateString][$gte]=2020-12-29' | jq
    public func getEGVs(startDate: Date, endDate: Date?, httpClient: HTTPClient) -> EventLoopFuture<[EGV]> {
        
        let endDate = endDate ?? referenceDate
        
        let startDateString = dateFormatter().string(from: startDate)
        let endDateString = dateFormatter().string(from: endDate)
        
        let scheme = "https"
        let host = baseURL
        let path = "/api/v1/entries/sgv.json"
        let startQueryItem = URLQueryItem(name: "find[dateString][$gte]", value: startDateString)
        let endQueryItem = URLQueryItem(name: "find[dateString][$lte]", value: endDateString)
        let countQueryItem = URLQueryItem(name: "count", value: "100000")

        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.path = path
        urlComponents.queryItems = [startQueryItem, endQueryItem, countQueryItem]
        
        let url = urlComponents.url!
        
        return httpClient.get(url: url.absoluteString).map { (response) in
            guard let body = response.body else {
                return []
            }
            
            let data = Data(buffer: body)
            
            var entries = [NightScoutEntryJSON]()
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(self.dateFormatter())
                entries = try decoder.decode([NightScoutEntryJSON].self, from: data)
            } catch {
                print(error)
            }
            
//            return entries.map({$0.toEGV()})
            return entries.filter({$0.device != "CGMBLEKit Dexcom G6 21.0"}).map({$0.toEGV()})
        }
    }
    
    //curl -L "<baseURL>/api/v1/treatments.json" | jq
    public func getTreatments(startDate: Date, endDate: Date?, httpClient: HTTPClient) -> EventLoopFuture<NightScoutTreatmentResult> {
        
        let endDate = endDate ?? referenceDate
        
        let startDateString = dateFormatter().string(from: startDate)
        let endDateString = dateFormatter().string(from: endDate)
        
        let scheme = "https"
        let host = baseURL
        let path = "/api/v1/treatments.json"
        let startQueryItem = URLQueryItem(name: "find[created_at][$gte]", value: startDateString)
        let endQueryItem = URLQueryItem(name: "find[created_at][$lte]", value: endDateString)
        let countQueryItem = URLQueryItem(name: "count", value: "1000")

        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.path = path
        urlComponents.queryItems = [startQueryItem, endQueryItem, countQueryItem]
        
        let url = urlComponents.url!
        
        return httpClient.get(url: url.absoluteString).map { (response) -> NightScoutTreatmentResult in
            guard let body = response.body else {
                return NightScoutTreatmentResult(basalEntries: [], bolusEntries: [], carbEntries: [])
            }
            
            let data = Data(buffer: body)
            
            var treatments = [NightScoutTreatmentJSON]()
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(self.dateFormatter())
                treatments = try decoder.decode([NightScoutTreatmentJSON].self, from: data)
            } catch {
                print(error)
            }
            
            return NightScoutTreatmentResult.getTreatmentResult(jsonObjects: treatments)
        }
    }
    
    //curl -L -g '<baseURL>/api/v1/devicestatus.json?find[created_at][$gte]=2021-05-01' | jq | less
    public func getDeviceStatuses(startDate: Date, endDate: Date?, httpClient: HTTPClient) -> EventLoopFuture<[NightScoutDeviceStatus]> {
        
        let endDate = endDate ?? referenceDate
        
        let startDateString = dateFormatter().string(from: startDate)
        let endDateString = dateFormatter().string(from: endDate)
        
        let scheme = "https"
        let host = baseURL
        let path = "/api/v1/devicestatus.json"
        let startQueryItem = URLQueryItem(name: "find[created_at][$gte]", value: startDateString)
        let endQueryItem = URLQueryItem(name: "find[created_at][$lte]", value: endDateString)
        let countQueryItem = URLQueryItem(name: "count", value: "1000")
        
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.path = path
        urlComponents.queryItems = [startQueryItem, endQueryItem, countQueryItem]
        
        let url = urlComponents.url!
        
        return httpClient.get(url: url.absoluteString).map { (response) -> [NightScoutDeviceStatus] in
            guard let body = response.body else {
                return []
            }
            
            let data = Data(buffer: body)
            
            var deviceStatuses = [NightScoutDeviceStatus]()
            
            do {
                let decoder = self.jsonDecoder()
                deviceStatuses = try decoder.decode([NightScoutDeviceStatus].self, from: data)
            } catch {
                print(error)
            }
            
            return deviceStatuses
        }
    }
    
    public func getBasalTreatments(startDate: Date, endDate: Date?, httpClient: HTTPClient) -> EventLoopFuture<[BasalEntry]> {
        return self.getTreatments(startDate: startDate, endDate: endDate, httpClient: httpClient).map { (result) in
            return result.basalEntries
        }
    }
    
    public func getBolusTreatments(startDate: Date, endDate: Date?, httpClient: HTTPClient) -> EventLoopFuture<[BolusEntry]> {
        return self.getTreatments(startDate: startDate, endDate: endDate, httpClient: httpClient).map { (result) in
            return result.bolusEntries
        }
    }
    
    public func getCarbTreatments(startDate: Date, endDate: Date?, httpClient: HTTPClient) -> EventLoopFuture<[CarbEntry]> {
        return self.getTreatments(startDate: startDate, endDate: endDate, httpClient: httpClient).map { (result) in
            return result.carbEntries
        }
    }
    
    public func sha1Secret() -> String {
        var sha1 = Insecure.SHA1()
        let sha1Data = secret.data(using: .utf8)!
        sha1.update(data: sha1Data)
        let digest = sha1.finalize()
        print(digest.description)
        return String(digest.description.split(separator: " ").last ?? "")
    }
    
    public func startOverride(overrideName: String, overrideDisplay: String, duration: Int, httpClient: HTTPClient) -> EventLoopFuture<HTTPClient.Response> {
        
        let secret = sha1Secret()

        let scheme = "https"
        let host = baseURL
        let path = "/api/v2/notifications/loop"

        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.path = path
        
        let url = urlComponents.url!
        var request = try! HTTPClient.Request(url: url, method: .POST)
        request.headers.add(name: "Content-Type", value: "application/json")
        request.headers.add(name: "api-secret", value: secret)

        let jsonDict: [String: String] = [
            "reason":overrideName,
            "reasonDisplay":overrideDisplay,
            "eventType":"Temporary Override",
            "duration":"\(duration)",
            "notes":""
        ]
        
        let postData = try! JSONEncoder().encode(jsonDict)
        let postLength = "\(postData.count)"
        request.headers.add(name: "Content-Length", value: postLength)
        
        let body = HTTPClient.Body.data(postData as Data)
        request.body = body
        
        return httpClient.execute(request: request)
    }

    func dateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }
    
    func secondaryDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }
    
    func jsonDecoder() -> JSONDecoder {
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            var date: Date? = nil
            if let tempDate = self.dateFormatter().date(from: dateStr) {
                date = tempDate
            } else if let tempDate = self.secondaryDateFormatter().date(from: dateStr) {
                date = tempDate
            }

            guard let date_ = date else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateStr)")
            }

            return date_
        })
        return decoder

    }
    
    
}

public struct NightScoutEntryJSON: Codable {
    
    public let _id: String
    public let sgv: Int
    public let dateString: Date //"2020-12-29T14:54:31.000Z",
    public let trend: Float?
    public let direction: String?
    public let device: String
    public let type: String
    public let utcOffset: Int
    public let sysTime: Date
    public let mills: Int?
    
    /*
     {
       "_id": "5feb436be0d1aa28f0556ec5",
       "sgv": 119,
       "date": 1609253671000,
       "dateString": "2020-12-29T14:54:31.000Z",
       "trend": 3,
       "direction": "FortyFiveUp",
       "device": "share2",
       "type": "sgv",
       "utcOffset": 0,
       "sysTime": "2020-12-29T14:54:31.000Z",
       "mills": 1609253671000
     }
     */
    
    func toEGV() -> EGV {
        return EGV(value: sgv, systemTime: sysTime, displayTime: sysTime, realtimeValue: nil, smoothedValue: nil, trendRate: trend, trendDescription: "")
    }
}

public struct NightScoutTreatmentJSON: Codable {
    public let _id: String
    
    let timestamp: String?//"2020-12-14T04:15:02Z"
    let amount: Float? //0
    let rate: Float?//0
    let eventType: String// "Temp Basal",
    let absolute: Float?//0,
    let created_at: Date //"2020-12-14T04:15:02.000Z"
    let enteredBy: String?//"loop://iPhone",
    
    
    let temp: String?//"absolute",
    let duration: Float?//19.953699616591134,
    let utcOffset: Int//0,
    let mills: Int?//1607919302000,
    let carbs: Int?//null,
    let insulin: Float?//null
    

    func basalEntry() -> BasalEntry? {
        guard eventType == "Temp Basal" else {
            return nil
        }
        
        return BasalEntry(date: created_at, duration: duration ?? 0.0, rate: rate ?? 0.0, amount: amount ?? 0.0)
        
        
    }
    
    func bolusEntry() -> BolusEntry? {
        guard eventType == "Correction Bolus" else {
            return nil
        }
        
        guard let insulin = insulin else {
            return nil
        }
        
        return BolusEntry(date: created_at, amount: insulin)
    }
    
    func carbEntry() -> CarbEntry? {
        guard eventType == "Meal Bolus" else {
            return nil
        }
        
        //TODO: Not sure about the time.
        return CarbEntry(date: created_at, amount: carbs ?? 0)
    }
    
}

public struct NightScoutTreatmentResult {
    
    let basalEntries: [BasalEntry]
    let bolusEntries: [BolusEntry]
    let carbEntries: [CarbEntry]

    static func getTreatmentResult(jsonObjects: [NightScoutTreatmentJSON]) -> NightScoutTreatmentResult {
        var basalEntries = [BasalEntry]()
        var bolusEntries = [BolusEntry]()
        var carbEntries = [CarbEntry]()
        
        for jsonObj in jsonObjects {

            if let basalEntry = jsonObj.basalEntry() {
                basalEntries.append(basalEntry)
            } else if let bolusEntry = jsonObj.bolusEntry() {
                bolusEntries.append(bolusEntry)
            } else if let carbEntry = jsonObj.carbEntry() {
                carbEntries.append(carbEntry)
            }
            
        }
        
        return NightScoutTreatmentResult(basalEntries: basalEntries, bolusEntries: bolusEntries, carbEntries: carbEntries)
    }
}

public struct NightScoutDeviceStatus: Codable, SugarEvent {
    
    public let _id: String
    public let created_at: Date
    public let loop: NightScoutLoopStatus?
    public let pump: NightScoutPumpStatus?
    public let uploader: NightScoutUploaderStatus?
    public let override: NightScoutOverride?
    
    public var date: Date {
        get {
            return created_at
        }
    }
    
    public func inlineDescription() -> String {
        //TODO: Implement this
        return ""
    }
}

public struct NightScoutPumpStatus: Codable, SugarEvent {
    public let clock: Date
    public let reservoir: Float?
    public let suspended: Bool
    public let pumpID: String
    
    public var date: Date {
        get {
            return clock
        }
    }
    
    public func inlineDescription() -> String {
        //TODO: Implement this
        return ""
    }
}


public struct NightScoutLoopStatus: Codable {
    public let timestamp: Date
    public let name: String
    public let version: String
    public let recommendedBolus: Float?
}

public struct NightScoutUploaderStatus: Codable {
    public let timestamp: Date
    public let battery: Int
    public let name: String
}

public struct NightScoutOverride: Codable {
    public let name: String?
    public let timestamp: Date
    public let active: Bool
    public let multiplier: Float?
    public let currentCorrectionRange: NightScoutCorrectionRange?
}

public struct NightScoutCorrectionRange: Codable {
    public let minValue: Int
    public let maxValue: Int
}

extension Array where Element == NightScoutDeviceStatus {
    
    public func getCurrentPumpStatuses() -> [NightScoutPumpStatus] {
        var toRet = [NightScoutPumpStatus]()
        
        for nightScoutStatus in self.sortDescending() {
            guard let pumpStatus = nightScoutStatus.pump else {
                continue
            }
            
            let lastPumpStatus: NightScoutPumpStatus? = toRet.last
            if let lastPumpStatus = lastPumpStatus, lastPumpStatus.pumpID != pumpStatus.pumpID {
                //Pod change
                break
            }
            toRet.append(pumpStatus)
        }
        
        return toRet
}
    public func getCurrentPumpStatusesLessThanUnits(_ units: Float) -> [NightScoutPumpStatus] {
        var descendingEvents = getCurrentPumpStatuses().sortDescending()
        descendingEvents.removeLast(10) //After pump change the units are inaccurate for 20 minutes or so.
        return descendingEvents.filter { status in
            if let reservoir = status.reservoir {
                return reservoir < units
            } else {
                return false
            }
        }
    }
    
    public func estimatedPumpUnits(referenceDate: Date) -> Float {
        if let reservoir = getCurrentPumpStatusesLessThanUnits(50).sortDescending().first?.reservoir {
            return reservoir
        } else {
            return 50
        }
    }
}




/*
 Carb Entry:
 
 Time seems to be time of EATING, not input time.
 
 - _id : "5fd7f77e8df99cafb2be144b"
 - timestamp : "2020-12-14T23:50:17Z"
 - amount : nil
 - rate : nil
 - eventType : "Meal Bolus"
 - absolute : nil
 - created_at : "2020-12-14T23:50:17.000Z"
 - enteredBy : "loop://iPhone"
 - temp : nil
 - duration : nil
 - utcOffset : 0
 - mills : 1607989817000
 ▿ carbs : Optional<Int>
 - some : 125
 - insulin : nil
 */

/*
 Bolus Entry suggested with carb entry
 
 See "insulin" for amount.
 
 - _id : "5fd7f7828df99cafb2be1686"
 - timestamp : "2020-12-14T23:38:40Z"
 - amount : nil
 - rate : nil
 - eventType : "Correction Bolus"
 - absolute : nil
 - created_at : "2020-12-14T23:38:40.000Z"
 - enteredBy : "loop://iPhone"
 - temp : nil
 ▿ duration : Optional<Float>
 - some : 2.3333333
 - utcOffset : 0
 - mills : 1607989120000
 - carbs : nil
 ▿ insulin : Optional<Float>
 - some : 3.5
 */

/*
 Temp Basal done by Loop
 
 ▿ 2 : NightScoutTreatment
 - _id : "5fd7f1fb8df99cafb2bb6048"
 - timestamp : "2020-12-14T23:15:07Z"
 - amount : nil
 ▿ rate : Optional<Float>
 - some : 0.0
 - eventType : "Temp Basal"
 ▿ absolute : Optional<Float>
 - some : 0.0
 - created_at : "2020-12-14T23:15:07.000Z"
 - enteredBy : "loop://iPhone"
 ▿ temp : Optional<String>
 - some : "absolute"
 ▿ duration : Optional<Float>
 - some : 30.0
 - utcOffset : 0
 - mills : 1607987707000
 - carbs : nil
 - insulin : nil
 */

/*
 Auto-Bolus
 
 - _id : "5fd7eaee8df99cafb2b7f052"
 - timestamp : "2020-12-14T22:45:00Z"
 - amount : nil
 - rate : nil
 - eventType : "Correction Bolus"
 - absolute : nil
 - created_at : "2020-12-14T22:45:00.000Z"
 - enteredBy : "loop://iPhone"
 - temp : nil
 ▿ duration : Optional<Float>
 - some : 0.033333335
 - utcOffset : 0
 - mills : 1607985900000
 - carbs : nil
 ▿ insulin : Optional<Float>
 - some : 0.05
 */
