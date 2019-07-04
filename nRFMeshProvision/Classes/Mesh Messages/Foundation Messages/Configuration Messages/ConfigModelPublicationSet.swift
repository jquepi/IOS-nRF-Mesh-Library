//
//  ConfigModelPublicationSet.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 03/07/2019.
//

import Foundation

public struct ConfigModelPublicationSet: ConfigAnyModelMessage {
    public static let opCode: UInt32 = 0x03
    
    public var parameters: Data? {
        var data = Data() + elementAddress + publish.publicationAddress.address
        data += UInt8(publish.index & 0xFF)
        data += UInt8(publish.index >> 8) | UInt8(publish.credentials << 4)
        data += publish.ttl
        data += (publish.periodSteps! & 0x3F) | (publish.periodResolution!.rawValue >> 6)
        data += (publish.retransmit.count & 0x07) | UInt8((publish.retransmit.interval / 50) - 1)
        data += modelIdentifier
        if let companyIdentifier = companyIdentifier {
            return data + companyIdentifier
        } else {
            return data
        }
    }
    
    public var isSegmented: Bool {
        return true
    }
    
    public let elementAddress: Address
    public let modelIdentifier: UInt16
    public let companyIdentifier: UInt16?
    /// Publication data.
    public let publish: Publish
    
    public init(_ publish: Publish, to model: Model) {
        self.publish = publish
        self.elementAddress = model.parentElement.unicastAddress
        self.modelIdentifier = model.modelIdentifier
        self.companyIdentifier = model.companyIdentifier
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 11 || parameters.count == 13 else {
            return nil
        }
        self.elementAddress = parameters.read(fromOffset: 0)
        
        let address: Address = parameters.read(fromOffset: 2)
        let index: KeyIndex = parameters.read(fromOffset: 4) & 0x0FFF
        let flag = Int((parameters[5] & 0x10) >> 4)
        let ttl = parameters[6]
        let periodSteps = parameters[7] & 0x3F
        let periodResolution = Publish.StepResolution(rawValue: parameters[7] >> 6)!
        let count = parameters[8] & 0x07
        let interval = parameters[8] >> 3
        let retransmit = Publish.Retransmit(publishRetransmitCount: count, intervalSteps: interval)
            
        self.publish = Publish(to: address.hex, withKeyIndex: index,
                               friendshipCredentialsFlag: flag, ttl: ttl,
                               periodSteps: periodSteps, periodResolution: periodResolution,
                               retransmit: retransmit)
        self.modelIdentifier = parameters.read(fromOffset: 9)
        if parameters.count == 12 {
            self.companyIdentifier = parameters.read(fromOffset: 11)
        } else {
            self.companyIdentifier = nil
        }
    }
}
