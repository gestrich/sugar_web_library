//
//  Slack.swift
//
//
//  Created by Bill Gestrich on 11/3/20.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct Slack {
    
    static public let debugURL: URL = URL(string: "https://hooks.slack.com/services/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")!
    static public let sugarDialURL: URL = URL(string: "https://hooks.slack.com/services/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")!
    public static let dadID = "U01DB1C23F1"
    public static let billID = "U01559M7E5U"
    
    let slackURL: URL
    
    public init(slackURL: URL) {
        self.slackURL = slackURL
    }
    
    public func post(message: String, completionBlock:@escaping () -> Void, errorBlock:@escaping () -> Void) {
        let payload = "payload={\"channel\": \"#dexcom\", \"username\": \"bot\", \"icon_emoji\":\":calling:\", \"text\": \"\(message)\"}"
        let data = (payload as NSString).data(using: String.Encoding.utf8.rawValue)
        
        let request = NSMutableURLRequest(url: slackURL)
        request.httpMethod = "POST"
        request.httpBody = data
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest){
            (data, response, error) -> Void in
            if let error = error {
                print("error: \(error.localizedDescription)")
                errorBlock()
            }
            else if let data = data {
                
                if let str = String(data: data, encoding: String.Encoding.utf8) {
                    completionBlock()
                    print("\(str)")
                }
                else {
                    print("error")
                }
            }
        }
        task.resume()
    }
    
    public func postAndWait(message: String) {
        
        let semaphore = DispatchSemaphore(value: 0)
        post(message: message) {
            semaphore.signal()
        } errorBlock: {
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
    }
}
