import Foundation

public struct VideoConfig {
    public struct WhiteBalancePreset {
        public let whiteBalance: Int16
        public let tint: Int16

        init(whiteBalance: Int16, tint: Int16) {
            self.whiteBalance = whiteBalance
            self.tint = tint
        }
    }

    public static let kWhiteBalancePresets: [WhiteBalancePreset] = [
        WhiteBalancePreset(whiteBalance: 5600, tint: 10),
        WhiteBalancePreset(whiteBalance: 3200, tint: 0),
        WhiteBalancePreset(whiteBalance: 4000, tint: 15),
        WhiteBalancePreset(whiteBalance: 4500, tint: 15),
        WhiteBalancePreset(whiteBalance: 6500, tint: 10),
    ]

    public static let kWhiteBalanceMin: Int16 = 2500
    public static let kWhiteBalanceMax: Int16 = 10000
    public static let kWhiteBalanceStep: Int16 = 50

    public static let kTintMin: Int16 = -50
    public static let kTintMax: Int16 = 50

    public static let kOffSpeedFrameRateMin: Int16 = 12
    public static let kOffSpeedFrameRateMax: Int16 = 60

    public static let kSentSensorGainBase: UInt16 = 100
    public static let kReceivedSensorGainBase: UInt16 = 200
    public static let kISOValues: [Int] = [200, 400, 800, 1600]
	public static let kGainValues: [Int] = [-6, 0, 6, 12]

    public static let kShutterAngles: [Double] = [11.2, 15.0, 22.5, 30.0, 37.5, 45.0, 60.0, 72.0, 75.0, 90.0, 108.0, 120.0, 144.0, 150.0, 172.8, 180.0, 216.0, 270.0, 324.0, 360.0]
    public static let kShutterSpeeds: [Int32] = [24, 25, 30, 50, 60, 100, 125, 200, 250, 500, 1000, 2000]
	public static let kShutterSpeedMin: Int = 24
	public static let kShutterSpeedMax: Int = 2000
	public static let kShutterAngleMin: Double = 5.0
	public static let kShutterAngleMax: Double = 360.0

    public static func GetWhiteBalancePresetFromValues(_ whiteBalance: Int16, _ tint: Int16) -> Int {
        var presetIndex: Int = 0
        for preset in kWhiteBalancePresets {
            if whiteBalance == preset.whiteBalance && tint == preset.tint {
                return presetIndex
            }

            presetIndex += 1
        }

        return -1
    }

    public static func GetShutterSpeed(for angle: Double, with frameRate: Int16, mRateEnabled: Bool) -> Int32 {
        if frameRate <= 0 {
            return 0
        }

        if mRateEnabled {
            let frameRateReciprocal: Double = 1.0 / Double(frameRate)
            let angleFraction: Double = Double(angle) / 360.0
            let exposure = Int32(frameRateReciprocal * angleFraction * 1_001_000.0) + 1
            return exposure
        } else {
            let frameRateReciprocal: Double = 1.0 / Double(frameRate)
            let angleFraction: Double = Double(angle) / 360.0
            let exposure = Int32(frameRateReciprocal * angleFraction * 1_000_000.0) + 1
            return exposure
        }
    }

    public static func GetShutterAngleIndex(for shutterSpeed: Int32, with frameRate: Int16) -> Int {
        if frameRate <= 0 {
            return 0
        }

        let frameRateReciprocal: Double = 1.0 / Double(frameRate)
        let angleFraction: Double = Double(shutterSpeed) / (frameRateReciprocal * 1_000_000.0)
        let angle = Double(angleFraction * 360.0)

        var closestAngle: Double = 360.0
        var closestIndex: Int = -1

        var shutterIndex = 0
        for shutterAngle in kShutterAngles {
            let difference = abs(angle - shutterAngle)

            if difference < closestAngle {
                closestAngle = difference
                closestIndex = shutterIndex
            }

            shutterIndex += 1
        }

        return closestIndex
    }

    public static func GetShutterAngle(for shutterSpeed: Int32, with frameRate: Int16, mRateEnabled: Bool) -> Double {
        if frameRate <= 0 {
            return 0
        }

        if mRateEnabled {
            let frameRateReciprocal: Double = 1.0 / Double(frameRate)
            let angleFraction: Double = Double(shutterSpeed) / (frameRateReciprocal * 1_001_000.0)
            let angle = Double(angleFraction * 360.0)

            return Double(Int((angle * 10.0).rounded())) / 10.0
        } else {
            let frameRateReciprocal: Double = 1.0 / Double(frameRate)
            let angleFraction: Double = Double(shutterSpeed) / (frameRateReciprocal * 1_000_000.0)
            let angle = Double(angleFraction * 360.0)

            return Double(Int((angle * 10.0).rounded())) / 10.0
        }
    }
}
