import Foundation

public struct CCUEncodingFunctions {
    // Video category encoding functions
    public static func CreateVideoSensorGainCommand(value: Int8) -> (CCUPacketTypes.Command?) {
        return CreateCommand(value, CCUPacketTypes.Category.Video, CCUPacketTypes.VideoParameter.SensorGain.rawValue)
    }

    public static func CreateVideoWhiteBalanceCommand(_ whiteBalance: Int16, _ tint: Int16) -> (CCUPacketTypes.Command?) {
        let dataArray: [Int16] = [whiteBalance, tint]
        let payloadData: [UInt8] = UtilityFunctions.ToByteArrayFromArray(dataArray)

        let command = CCUPacketTypes.InitCommand(
            target: CCUPacketTypes.kBroadcastTarget,
            commandId: CCUPacketTypes.CommandID.ChangeConfiguration,
            category: CCUPacketTypes.Category.Video,
            parameter: CCUPacketTypes.VideoParameter.ManualWB.rawValue,
            operationType: CCUPacketTypes.OperationType.AssignValue,
            dataType: CCUPacketTypes.DataTypes.kInt16,
            data: payloadData)

        return command
    }
    
    public static func CreateAudioGainCommand(_ gainL: Int16,_ gainR: Int16) -> (CCUPacketTypes.Command?) {
        let dataArray: [Int16] = [gainL, gainR]
        let payloadData: [UInt8] = UtilityFunctions.ToByteArrayFromArray(dataArray)
        
        let command = CCUPacketTypes.InitCommand(
            target: CCUPacketTypes.kBroadcastTarget,
            commandId: CCUPacketTypes.CommandID.ChangeConfiguration,
            category: CCUPacketTypes.Category.Audio,
            parameter: CCUPacketTypes.AudioParameter.InputLevels.rawValue,
            operationType: CCUPacketTypes.OperationType.AssignValue,
            dataType: CCUPacketTypes.DataTypes.kInt16,
            data: payloadData)
        
        return command
    }

    public static func CreateGammaCommand(_ red: Int16, _ green: Int16, _ blue: Int16, _ luma: Int16) -> (CCUPacketTypes.Command?) {
        let dataArray: [Int16] = [red, green, blue, luma]
        let payloadData: [UInt8] = UtilityFunctions.ToByteArrayFromArray(dataArray)
        
        let command = CCUPacketTypes.InitCommand(
            target: CCUPacketTypes.kBroadcastTarget,
            commandId: CCUPacketTypes.CommandID.ChangeConfiguration,
            category: CCUPacketTypes.Category.ColorCorrection,
            parameter: CCUPacketTypes.ColorCorrectionParameter.GammaAdjust.rawValue,
            operationType: CCUPacketTypes.OperationType.AssignValue,
            dataType: CCUPacketTypes.DataTypes.kInt16,
            data: payloadData)
        
        return command
    }
    
    public static func CreateVideoSetAutoWBCommand() -> (CCUPacketTypes.Command?) {
        return CreateVoidCommand(CCUPacketTypes.Category.Video, CCUPacketTypes.VideoParameter.SetAutoWB.rawValue)
    }

    public static func CreateLensSetAutoFocusCommand() -> (CCUPacketTypes.Command?) {
        return CreateVoidCommand(CCUPacketTypes.Category.Lens,
            CCUPacketTypes.LensParameter.AutoFocus.rawValue)
    }
    
    public static func CreateVideoExposureCommand(value: Int32) -> (CCUPacketTypes.Command?) {
        return CreateCommand(value, CCUPacketTypes.Category.Video, CCUPacketTypes.VideoParameter.Exposure.rawValue)
    }

    public static func CreateRecordingFormatCommand(recordingFormatData: CCUPacketTypes.RecordingFormatData) -> (CCUPacketTypes.Command?) {
        var flags: Int16 = 0
        if recordingFormatData.mRateEnabled {
            flags = flags | Int16(CCUPacketTypes.VideoRecordingFormat.FileMRate.rawValue)
        }
        if recordingFormatData.offSpeedEnabled {
            flags = flags | Int16(CCUPacketTypes.VideoRecordingFormat.SensorOffSpeed.rawValue)
        }
        if recordingFormatData.interlacedEnabled {
            flags = flags | Int16(CCUPacketTypes.VideoRecordingFormat.Interlaced.rawValue)
        }
        if recordingFormatData.windowedModeEnabled {
            flags = flags | Int16(CCUPacketTypes.VideoRecordingFormat.WindowedMode.rawValue)
        }

        var data: [Int16] = Array(repeating: 0, count: 5)
        data[0] = recordingFormatData.frameRate
        data[1] = recordingFormatData.offSpeedFrameRate
        data[2] = recordingFormatData.width
        data[3] = recordingFormatData.height
        data[4] = flags

        let payloadData: [UInt8] = UtilityFunctions.ToByteArrayFromArray(data)

        let command = CCUPacketTypes.InitCommand(
            target: CCUPacketTypes.kBroadcastTarget,
            commandId: CCUPacketTypes.CommandID.ChangeConfiguration,
            category: CCUPacketTypes.Category.Video,
            parameter: CCUPacketTypes.VideoParameter.RecordingFormat.rawValue,
            operationType: CCUPacketTypes.OperationType.AssignValue,
            dataType: CCUPacketTypes.DataTypes.kInt16,
            data: payloadData)

        return command
    }

    public static func CreateTransportInfoCommand(transportInfo: TransportInfo) -> (CCUPacketTypes.Command?) {
        let data: [UInt8] = transportInfo.serialize()
        let command = CCUPacketTypes.InitCommand(
            target: CCUPacketTypes.kBroadcastTarget,
            commandId: CCUPacketTypes.CommandID.ChangeConfiguration,
            category: CCUPacketTypes.Category.Media,
            parameter: CCUPacketTypes.MediaParameter.TransportMode.rawValue,
            operationType: CCUPacketTypes.OperationType.AssignValue,
            dataType: CCUPacketTypes.DataTypes.kInt8,
            data: data)

        return command
    }

    // Metadata encoding functions
    // Important: All metadata CCU commands are undocumented and are subject to change in a future release
    
    public static func CreateMetadataStringCommand(_ string: String, _ category: CCUPacketTypes.Category, _ parameter: CCUPacketTypes.MetadataParameter) -> (CCUPacketTypes.Command?) {
        let maxLength: Int8? = CCUPacketTypes.MetadataParameterToStringLengthMap[parameter]
        if maxLength != nil {
            return CreateStringCommand(string, category, parameter.rawValue, maxLength: maxLength!)
        } else {
            Logger.LogError("No max string length info for metadata parameter \(parameter). Cannot create CCU command.")
        }

        return nil
    }

    public static func CreateMetadataSceneTagsCommand(_ sceneTag: CCUPacketTypes.MetadataSceneTag, _ locationType: CCUPacketTypes.MetadataLocationTypeTag, _ dayOrNight: CCUPacketTypes.MetadataDayNightTag) -> (CCUPacketTypes.Command?) {
        var data = [UInt8](repeating: 0, count: 3)
        data[0] = UInt8(bitPattern: sceneTag.rawValue)
        data[1] = locationType.rawValue
        data[2] = dayOrNight.rawValue

        let command = CCUPacketTypes.InitCommand(
            target: CCUPacketTypes.kBroadcastTarget,
            commandId: CCUPacketTypes.CommandID.ChangeConfiguration,
            category: CCUPacketTypes.Category.Metadata,
            parameter: CCUPacketTypes.MetadataParameter.SceneTags.rawValue,
            operationType: CCUPacketTypes.OperationType.AssignValue,
            dataType: CCUPacketTypes.DataTypes.kInt8,
            data: data)

        return command
    }

    public static func CreateMetadataTakeCommand(_ takeNumber: UInt8, _ takeTag: CCUPacketTypes.MetadataTakeTag) -> (CCUPacketTypes.Command?) {
        var data = [UInt8](repeating: 0, count: 2)
        data[0] = UInt8(takeNumber)
        data[1] = UInt8(bitPattern: takeTag.rawValue)

        let command = CCUPacketTypes.InitCommand(
            target: CCUPacketTypes.kBroadcastTarget,
            commandId: CCUPacketTypes.CommandID.ChangeConfiguration,
            category: CCUPacketTypes.Category.Metadata,
            parameter: CCUPacketTypes.MetadataParameter.Take.rawValue,
            operationType: CCUPacketTypes.OperationType.AssignValue,
            dataType: CCUPacketTypes.DataTypes.kInt8,
            data: data)

        return command
    }

    // Generic encoding functions
    public static func CreateCommand<T: CCUDataType>(_ value: T, _ category: CCUPacketTypes.Category, _ parameter: UInt8) -> (CCUPacketTypes.Command?) {
        let data: [UInt8] = UtilityFunctions.ToByteArray(value)
        let command = CCUPacketTypes.InitCommand(
            target: CCUPacketTypes.kBroadcastTarget,
            commandId: CCUPacketTypes.CommandID.ChangeConfiguration,
            category: category,
            parameter: parameter,
            operationType: CCUPacketTypes.OperationType.AssignValue,
            dataType: T.getCCUDataType(),
            data: data)

        return command
    }

    public static func CreateCommandFromArray<T: CCUDataType>(_ value: [T], _ category: CCUPacketTypes.Category, _ parameter: UInt8) -> (CCUPacketTypes.Command?) {

        let data: [UInt8] = UtilityFunctions.ToByteArrayFromArray(value)
        let command = CCUPacketTypes.InitCommand(
            target: CCUPacketTypes.kBroadcastTarget,
            commandId: CCUPacketTypes.CommandID.ChangeConfiguration,
            category: category,
            parameter: parameter,
            operationType: CCUPacketTypes.OperationType.AssignValue,
            dataType: T.getCCUDataType(),
            data: data)

        return command
    }

    public static func CreateFixed16Command(_ value: CCUPacketTypes.ccu_fixed_t, _ category: CCUPacketTypes.Category, _ parameter: UInt8) -> (CCUPacketTypes.Command?) {
        let data: [UInt8] = UtilityFunctions.ToByteArray(value)
        let command = CCUPacketTypes.InitCommand(
            target: CCUPacketTypes.kBroadcastTarget,
            commandId: CCUPacketTypes.CommandID.ChangeConfiguration,
            category: category,
            parameter: parameter,
            operationType: CCUPacketTypes.OperationType.AssignValue,
            dataType: CCUPacketTypes.DataTypes.kFixed16,
            data: data)

        return command
    }

    public static func CreateStringCommand(_ string: String, _ category: CCUPacketTypes.Category, _ parameter: UInt8, maxLength: Int8 = -1) -> (CCUPacketTypes.Command?) {
        let data: [UInt8] = Array(string.utf8)

        if maxLength >= 0 && data.count > Int(maxLength) {
            Logger.LogError("String length (\(data.count)) exceeds maximum (\(maxLength)). Cannot create CCU command.")
            return nil
        }

        let command = CCUPacketTypes.InitCommand(
            target: CCUPacketTypes.kBroadcastTarget,
            commandId: CCUPacketTypes.CommandID.ChangeConfiguration,
            category: category,
            parameter: parameter,
            operationType: CCUPacketTypes.OperationType.AssignValue,
            dataType: CCUPacketTypes.DataTypes.kString,
            data: data)

        return command
    }

    public static func CreateVoidCommand(_ category: CCUPacketTypes.Category, _ parameter: UInt8) -> (CCUPacketTypes.Command?) {
        let data = [UInt8]()
        let command = CCUPacketTypes.InitCommand(
            target: CCUPacketTypes.kBroadcastTarget,
            commandId: CCUPacketTypes.CommandID.ChangeConfiguration,
            category: category,
            parameter: parameter,
            operationType: CCUPacketTypes.OperationType.AssignValue,
            dataType: CCUPacketTypes.DataTypes.kVoid,
            data: data)

        return command
    }
}
