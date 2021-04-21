import Foundation

struct CCUValidationFunctions {
    static func ValidateCCUPacket(packetAsData data: Data) -> Bool {
        let byteArray = [UInt8](data)
        return ValidateCCUPacket(packetAsByteArray: byteArray)
    }

    static func ValidateCCUPacket(packetAsByteArray byteArray: [UInt8]) -> Bool {
        let packetSize = UInt8(byteArray.count)
        let isSizeValid = (packetSize >= CCUPacketTypes.kPacketSizeMin && packetSize <= CCUPacketTypes.kPacketSizeMax)
        if !isSizeValid {
            Logger.LogWithInfo("CCU packet (\(packetSize) bytes) is not between \(CCUPacketTypes.kPacketSizeMin) and \(CCUPacketTypes.kPacketSizeMax) bytes.")
            return false
        }

        let commandLength = byteArray[CCUPacketTypes.PacketFormatIndex.CommandLength]
        let expectedPayloadSize = commandLength - CCUPacketTypes.kCCUCommandHeaderSize
        let actualPayloadSize = packetSize - (CCUPacketTypes.kCCUPacketHeaderSize + CCUPacketTypes.kCCUCommandHeaderSize)
        if actualPayloadSize < expectedPayloadSize {
            Logger.LogWithInfo("Payload (\(actualPayloadSize)) is smaller than expected (\(expectedPayloadSize)).")
            return false
        }

        let categoryValue = byteArray[CCUPacketTypes.PacketFormatIndex.Category]
        let category: CCUPacketTypes.Category? = CCUPacketTypes.Category(rawValue: categoryValue)
        if category == nil {
            Logger.LogWithInfo("CCU packet has invalid category (\(categoryValue)).")
            return false
        }

        var isParamterValid = false
        let parameterValue: UInt8 = byteArray[CCUPacketTypes.PacketFormatIndex.Parameter]
        //Logger.LogWithInfo("CCU Packet Parameter RX:(\(parameterValue)).")
        switch category!
        {
        case .Lens:
            let parameter = CCUPacketTypes.LensParameter(rawValue: parameterValue)
            //Logger.LogWithInfo("CCU Packet LENS Parameter RX:(\(parameter)).")
            isParamterValid = parameter != nil
        case .Video:
            let parameter = CCUPacketTypes.VideoParameter(rawValue: parameterValue)
            isParamterValid = parameter != nil
        case .Audio:
            let parameter = CCUPacketTypes.AudioParameter(rawValue: parameterValue)
            isParamterValid = parameter != nil
        case .Output:
            let parameter = CCUPacketTypes.OutputParameter(rawValue: parameterValue)
            isParamterValid = parameter != nil
        case .Display:
            let parameter = CCUPacketTypes.DisplayParameter(rawValue: parameterValue)
            isParamterValid = parameter != nil
        case .Tally:
            let parameter = CCUPacketTypes.TallyParameter(rawValue: parameterValue)
            isParamterValid = parameter != nil
        case .Reference:
            let parameter = CCUPacketTypes.ReferenceParameter(rawValue: parameterValue)
            isParamterValid = parameter != nil
        case .Configuration:
            let parameter = CCUPacketTypes.ConfigurationParameter(rawValue: parameterValue)
            isParamterValid = parameter != nil
        case .ColorCorrection:
            let parameter = CCUPacketTypes.ColorCorrectionParameter(rawValue: parameterValue)
            isParamterValid = parameter != nil
        case .Status:
            let parameter = CCUPacketTypes.StatusParameter(rawValue: parameterValue)
            isParamterValid = parameter != nil
        case .Media:
            let parameter = CCUPacketTypes.MediaParameter(rawValue: parameterValue)
            isParamterValid = parameter != nil
        case .ExternalDeviceControl:
            let parameter = CCUPacketTypes.ExDevControlParameter(rawValue: parameterValue)
            isParamterValid = parameter != nil
        case .Metadata:
            let parameter = CCUPacketTypes.MetadataParameter(rawValue: parameterValue)
            //Logger.LogWithInfo("CCU Packet Meta Data Parameter RX:(\(parameter)).")
            isParamterValid = parameter != nil
        }

        if !isParamterValid {
            Logger.LogWithInfo("CCU packet has invalid parameter \(parameterValue) for category \(category.getString()).")
            return false
        }

        return true
    }
}
