import Foundation

public struct LensConfig {
    
    public static let kMaxFocus: Double = 1.0
    public static let kMinFocus: Double = 0.0
    
    public static let fStopValues: [Double] = [1.2, 1.4, 1.8, 2.0, 2.2, 2.4, 2.6, 2.8, 3.2, 3.5, 3.7, 4.0, 4.5, 4.8, 5.2, 5.6, 6.2, 6.7, 7.3, 8.0, 8.7, 9.5, 10.0, 11.0, 12.0, 14.0, 15.0, 16.0, 17.0, 19.0, 21.0, 22.0]

    // ccu_fixed_t representation of log2(fstop ^ 2) (see definition and conversion functions in CCUPacketTypes.swift)
    public static let apertureNumbers: [Int16] = [1077, 1988, 3473, 4096, 4659, 5173, 5646, 6084, 6873, 7402, 7731, 8192, 8888, 9269, 9742, 10180, 10781, 11240, 11746, 12288, 12783, 13303, 13606, 14169, 14684, 15594, 16002, 16384, 16742, 17399, 17990, 18265]

    public static func GetIndexForApertureNumber(_ targetNumber: Int16) -> Int {
        if targetNumber > apertureNumbers.last! {
            return apertureNumbers.count - 1
        }

        if let index: Int = apertureNumbers.index(where: { targetNumber <= $0 }) {
            return index
        }

        return -1
    }

    public static func GetFStopString(_ fStopValue: Double) -> String {
        let isFractionalNumber: Bool = fStopValue != floor(fStopValue)
        let isLessThanTen: Bool = fStopValue < 10.0
        if isFractionalNumber || isLessThanTen {
            return String(format: "f%.1f", fStopValue)
        }

        return String(format: "f%d", Int(fStopValue))
    }
}
