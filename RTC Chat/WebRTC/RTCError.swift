//
//  RTCError.swift
//  RTC Chat
//
//  Created by Pepe Becker on 14/06/2018.
//  Copyright © 2018 Pepe Becker. All rights reserved.
//

enum RTCError: Error {
    case SetupCallFailed
    case DescriptionIsNil
    case ExtractDataFailed
    case MethodNotOverriden
    case DataChannelIsNil
    case FailedToSendData
}
