//
//  WCSessionSupport.swift
//  NotificationDemo
//
//  Created by Eric Blair on 1/5/17.
//  Copyright © 2017 Martiancraft. All rights reserved.
//

import WatchConnectivity

/// Typealias for the `WCSession` `sendMessage` reply handler
typealias MessageReplyHandler = (([String: Any]) -> Void)
/// Typealis for the `WCSession` `snedMessageData` reply handler
typealias DataReplyHandler = ((Data) -> Void)
/// Typealias for the `WCSession` error handler
typealias ErrorHandler = ((Error) -> Void)


