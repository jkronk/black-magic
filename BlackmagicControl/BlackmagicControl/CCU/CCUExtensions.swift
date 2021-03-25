import Foundation

extension Optional {
    func getString() -> String {
        switch self
        {
        case let .some(value):
            return String(describing: value)
        case _:
            return "(nil)"
        }
    }
}

extension CCUPacketTypes.Command {
    func Log() {
        var commandDescription = "CCU Command:\n"
        commandDescription += "Destination: \(self.target)\n"
        commandDescription += "Command Length: \(self.length)\n"
        commandDescription += "Command ID: \(self.commandID)\n"
        commandDescription += "Source Device: \(self.reserved)\n"
        commandDescription += "Category: \(self.category)\n"
        commandDescription += "Parameter: \(self.parameter)\n"
        commandDescription += "Data Type: \(self.dataType)\n"
        commandDescription += "Operation Type: \(self.operationType)\n"
        commandDescription += "Payload size: \(self.data.count)\n"

        Logger.Log(commandDescription)
    }
}

public protocol CCUDataType {
    static func getCCUDataType() -> (CCUPacketTypes.DataType)
}

extension Int64: CCUDataType {
    public static func getCCUDataType() -> (CCUPacketTypes.DataType) {
        return CCUPacketTypes.DataTypes.kInt64
    }
}

extension Int32: CCUDataType {
    public static func getCCUDataType() -> (CCUPacketTypes.DataType) {
        return CCUPacketTypes.DataTypes.kInt32
    }
}

extension Int16: CCUDataType {
    public static func getCCUDataType() -> (CCUPacketTypes.DataType) {
        return CCUPacketTypes.DataTypes.kInt16
    }
}

extension Int8: CCUDataType {
    public static func getCCUDataType() -> (CCUPacketTypes.DataType) {
        return CCUPacketTypes.DataTypes.kInt8
    }
}

extension Bool: CCUDataType {
    public static func getCCUDataType() -> (CCUPacketTypes.DataType) {
        return CCUPacketTypes.DataTypes.kBool
    }
}

extension String: CCUDataType {
    public static func getCCUDataType() -> (CCUPacketTypes.DataType) {
        return CCUPacketTypes.DataTypes.kString
    }
}
