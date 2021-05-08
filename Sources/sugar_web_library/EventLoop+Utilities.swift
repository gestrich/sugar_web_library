//
//  EventLoop+Utilities.swift
//  
//
//  Created by Bill Gestrich on 11/15/20.
//

import Foundation
import NIO

public extension EventLoop {
    
    func backgroundFuture<T>(block: @escaping () throws -> T)  -> EventLoopFuture<T> {
        let promise = makePromise(of: T.self)
        DispatchQueue.global().async  {
            do {
                let res = try block()
                promise.succeed(res)
            } catch {
                promise.fail(error)
            }

        }
        
        return promise.futureResult
    }

}
