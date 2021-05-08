//
//  User.swift
//  
//
//  Created by Bill Gestrich on 11/27/20.
//

import Foundation

public struct User {
    public let name: String
    public let phone: String
    public let slackID: String
    
    public init(name: String, phone: String, slackID: String) {
        self.name = name
        self.phone = phone
        self.slackID = slackID
    }
}
