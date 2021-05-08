//
//  Twilio.swift
//
//
//  Created by Bill Gestrich on 11/3/20.
//

import AsyncHTTPClient
import Foundation
import NIO

public struct Twilio {
    
    let account = "AC08f8cd6df62d405ca592180b991c33bf"
    let password = "d184cbf25c21a7f7ef3ee9336d58981e"
    let returnPhone = "+17744625476"
    
    public init() {

    }
    
    public func call(message: String, user: User, httpClient: AsyncHTTPClient.HTTPClient) -> EventLoopFuture<HTTPClient.Response>{
        /*
         curl -X POST https://api.twilio.com/2010-04-01/Accounts/AC08f8cd6df62d405ca592180b991c33bf/Calls.json \
         --data-urlencode "Twiml=<Response><Say>Ahoy there</Say></Response>" \
         --data-urlencode "To=+14123773856" \
         --data-urlencode "From=+17744625476" \
         -u AC08f8cd6df62d405ca592180b991c33bf:d184cbf25c21a7f7ef3ee9336d58981e
         
         */

        
        let credentialsClearText = "\(account):\(password)"
        let credentialsAsData = credentialsClearText.data(using: .utf8)
        guard let credentialsEncodedString = credentialsAsData?.base64EncodedString() else {
            fatalError("Unable to prepare ff config server request")
        }
        let headerAuthKey = "Authorization"
        let headerAuthValue = "Basic \(credentialsEncodedString)"
        
        
        var request = try! HTTPClient.Request(url: "https://api.twilio.com/2010-04-01/Accounts/\(account)/Calls.json", method: .POST)
        request.headers.add(name: "Content-Type", value: "application/x-www-form-urlencoded")
        request.headers.add(name: headerAuthKey, value: headerAuthValue)
        
        let messageWithPrompt = message + " Press 1 to confirm you will fix this issue in the next 5 minutes. Press any other key to send to the next caller."
        let dict = [
            "Twiml": "<Response><Pause length=\"1\"/><Gather input=\"dtmf\" action=\"https://96unt7kqj8.execute-api.us-east-1.amazonaws.com/twilioCallback\" numDigits=\"1\"><Say>\(messageWithPrompt)</Say></Gather></Response>",
            "To": user.phone,
            "From": returnPhone,
//            "MachineDetection": "Enable",
//            "AsyncAMD": "true"
        ]
        
        let dataString = dict.reduce("") { (partialResult, tuple: (String, String)) -> String in
            let ampersand = (partialResult != "" ? "&" : "")
            return partialResult + ampersand + tuple.0 + "=" + tuple.1
        }
        
        let postData = NSMutableData(data: dataString.data(using: String.Encoding.utf8)!)
        let postLength = "\(postData.length)"
        request.headers.add(name: "Content-Length", value: postLength)
        
        let body = HTTPClient.Body.data(postData as Data)
        request.body = body
        
        return httpClient.execute(request: request)
        
    }
    
    public func sendText(message: String, user: User, httpClient: AsyncHTTPClient.HTTPClient) -> EventLoopFuture<HTTPClient.Response>{
        /*
         curl -X POST https://api.twilio.com/2010-04-01/Accounts/AC08f8cd6df62d405ca592180b991c33bf/Calls.json \
         --data-urlencode "Twiml=<Response><Say>Ahoy there</Say></Response>" \
         --data-urlencode "To=+14123773856" \
         --data-urlencode "From=+17744625476" \
         -u AC08f8cd6df62d405ca592180b991c33bf:d184cbf25c21a7f7ef3ee9336d58981e
         
         */
        
        let credentialsClearText = "\(account):\(password)"
        let credentialsAsData = credentialsClearText.data(using: .utf8)
        guard let credentialsEncodedString = credentialsAsData?.base64EncodedString() else {
            fatalError("Unable to prepare ff config server request")
        }
        let headerAuthKey = "Authorization"
        let headerAuthValue = "Basic \(credentialsEncodedString)"
        
        
        var request = try! HTTPClient.Request(url: "https://api.twilio.com/2010-04-01/Accounts/\(account)/Messages.json", method: .POST)
        request.headers.add(name: "Content-Type", value: "application/x-www-form-urlencoded")
        request.headers.add(name: headerAuthKey, value: headerAuthValue)
        
        let messageWithPrompt = message + " Reply with just a 1 to confirm you will fix this issue in the next 5 minutes. Reply with 2 to send to the next caller."
        let dict = [
            "Body":messageWithPrompt,
            "To": user.phone,
            "From": returnPhone
        ]
        
        let dataString = dict.reduce("") { (partialResult, tuple: (String, String)) -> String in
            let ampersand = (partialResult != "" ? "&" : "")
            return partialResult + ampersand + tuple.0 + "=" + tuple.1
        }
        
        let postData = NSMutableData(data: dataString.data(using: String.Encoding.utf8)!)
        let postLength = "\(postData.length)"
        request.headers.add(name: "Content-Length", value: postLength)
        
        let body = HTTPClient.Body.data(postData as Data)
        request.body = body
        
        return httpClient.execute(request: request)
        
    }
    
    
    public func getReceivedPhonePayload(body: String) -> TwilioReceivedPhonePayload? {
        
        guard let base64Data = body.data(using: .utf8), let decodedData = Data(base64Encoded: base64Data) else {
            return TwilioReceivedPhonePayload(toNumber: "", digitsPressed: "", queryDictionary: [:])
        }
        
        guard let decodedString = String(data: decodedData, encoding: .utf8) else {
            return TwilioReceivedPhonePayload(toNumber: "", digitsPressed: "", queryDictionary: [:])
        }
        
        let queryDictionary = convertQueryStringToDictionary(queryString: decodedString)
        
        guard let digits: String = queryDictionary["Digits"]  else {
            return nil
        }
        
        guard let toNumber: String = queryDictionary["To"] else {
            return nil
        }
        
        return TwilioReceivedPhonePayload(toNumber: toNumber, digitsPressed: digits, queryDictionary: queryDictionary)
        
    }
    
public func getReceivedTextMessagePayload(body: String) -> TwilioReceivedTextPayload? {
        
        guard let base64Data = body.data(using: .utf8), let decodedData = Data(base64Encoded: base64Data) else {
            return TwilioReceivedTextPayload(fromNumber: "", message: "", queryDictionary: [:])
        }
        
        guard let decodedString = String(data: decodedData, encoding: .utf8) else {
            return TwilioReceivedTextPayload(fromNumber: "", message: "", queryDictionary: [:])
        }
        
        let queryDictionary = convertQueryStringToDictionary(queryString: decodedString)
        
        guard let message: String = queryDictionary["Body"]  else {
            return nil
        }
        
        guard let fromNumber: String = queryDictionary["From"] else {
            return nil
        }
        
        return TwilioReceivedTextPayload(fromNumber: fromNumber, message: message, queryDictionary: queryDictionary)
        
    }
    
    /*
     ToCountry=US&
ToState=MA&
     SmsMessageSid=SMc8512f6c6fe5e5f4cde414209a5caaf9&
     NumMedia=0&
     ToCity=&
     FromZip=15217&
     SmsSid=SMc8512f6c6fe5e5f4cde414209a5caaf9&
     FromState=PA&
     SmsStatus=received&
     FromCity=PITTSBURGH&
     Body=This+is+a+test&
     FromCountry=US&
     To=%2B17744625476&ToZip=&
     NumSegments=1&
     MessageSid=SMc8512f6c6fe5e5f4cde414209a5caaf9&
     AccountSid=AC08f8cd6df62d405ca592180b991c33bf&
     From=%2B14123773856&
     ApiVersion=2010-04-01
     */
}

func convertQueryStringToDictionary(queryString: String) -> Dictionary<String, String> {
    var queryStrings = [String: String]()
    for pair in queryString.split(separator: "&") {
        
        let key = pair.components(separatedBy: "=")[0]
        
        let value = pair
            .components(separatedBy:"=")[1]
            .replacingOccurrences(of: "+", with: " ")
            .removingPercentEncoding ?? ""
        
        queryStrings[key] = value
    }
    
    return queryStrings
}


public struct TwilioReceivedPhonePayload {
    public let toNumber: String
    public let digitsPressed: String
    public let queryDictionary: Dictionary<String, String>
}

public struct TwilioReceivedTextPayload {
    public let fromNumber: String
    public let message: String
    public let queryDictionary: Dictionary<String, String>
}




//Code that called the sugar dial lambda via API gateway
/*
func callPhone(httpClient: AsyncHTTPClient.HTTPClient) -> EventLoopFuture<AsyncHTTPClient.HTTPClient.Response> {
    
    postToSlack("Calling Bill's Phone", isError: true, includeMentions: true)
    
    var request = try! HTTPClient.Request(url: "https://0mkgwkauba.execute-api.us-east-1.amazonaws.com/sugarDial", method: .POST)
    request.headers.add(name: "Content-Type", value: "application/json")
    request.headers.add(name: "Accept", value: "application/json")
    let jsonData = try! JSONSerialization.data(withJSONObject: ["phone_number": "+14123773856"], options: .prettyPrinted)
    let body = HTTPClient.Body.data(jsonData)
    request.body = body
    
    return httpClient.execute(request: request)

}
*/
