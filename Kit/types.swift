//
//  types.swift
//  Kit
//
//  Created by Serhiy Mytrovtsiy on 10/04/2021.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2021 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa

public struct DoubleValue {
    public var ts: Date = Date()
    public let value: Double
    
    public init(_ value: Double = 0) {
        self.value = value
    }
}

public struct ColorValue: Equatable {
    public var ts: Date = Date()
    public let value: Double
    public var color: NSColor?
    
    public init(_ value: Double, color: NSColor? = nil) {
        self.value = value
        self.color = color
    }
    
    // swiftlint:disable function_name_whitespace
    public static func ==(lhs: ColorValue, rhs: ColorValue) -> Bool {
        return lhs.value == rhs.value
    }
    // swiftlint:enable function_name_whitespace
}

public enum AppUpdateInterval: String {
    case silent = "Silent"
    case atStart = "At start"
    case separator1 = "separator_1"
    case oncePerDay = "Once per day"
    case oncePerWeek = "Once per week"
    case oncePerMonth = "Once per month"
    case separator2 = "separator_2"
    case never = "Never"
}
public let AppUpdateIntervals: [KeyValue_t] = [
    KeyValue_t(key: "Silent", value: AppUpdateInterval.silent.rawValue),
    KeyValue_t(key: "At start", value: AppUpdateInterval.atStart.rawValue),
    KeyValue_t(key: "separator_1", value: "separator_1"),
    KeyValue_t(key: "Once per day", value: AppUpdateInterval.oncePerDay.rawValue),
    KeyValue_t(key: "Once per week", value: AppUpdateInterval.oncePerWeek.rawValue),
    KeyValue_t(key: "Once per month", value: AppUpdateInterval.oncePerMonth.rawValue),
    KeyValue_t(key: "separator_2", value: "separator_2"),
    KeyValue_t(key: "Never", value: AppUpdateInterval.never.rawValue)
]

public let TemperatureUnits: [KeyValue_t] = [
    KeyValue_t(key: "system", value: "System"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: "celsius", value: "Celsius", additional: UnitTemperature.celsius),
    KeyValue_t(key: "fahrenheit", value: "Fahrenheit", additional: UnitTemperature.fahrenheit)
]

public let CombinedModulesSpacings: [KeyValue_t] = [
    KeyValue_t(key: "none", value: "None"),
    KeyValue_t(key: "1", value: "1", additional: 1),
    KeyValue_t(key: "2", value: "2", additional: 2),
    KeyValue_t(key: "3", value: "3", additional: 3),
    KeyValue_t(key: "4", value: "4", additional: 4),
    KeyValue_t(key: "5", value: "5", additional: 5),
    KeyValue_t(key: "6", value: "6", additional: 6),
    KeyValue_t(key: "7", value: "7", additional: 7),
    KeyValue_t(key: "8", value: "8", additional: 8)
]

public let PublicIPAddressRefreshIntervals: [KeyValue_t] = [
    KeyValue_t(key: "never", value: "Never"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: "hour", value: "Every hour"),
    KeyValue_t(key: "12", value: "Every 12 hours"),
    KeyValue_t(key: "24", value: "Every 24 hours")
]

public enum DataSizeBase: String {
    case bit
    case byte
}
public let SpeedBase: [KeyValue_t] = [
    KeyValue_t(key: "bit", value: "Bit", additional: DataSizeBase.bit),
    KeyValue_t(key: "byte", value: "Byte", additional: DataSizeBase.byte)
]

public let NetworkSpeedUnitAuto = "auto"
public let NetworkSpeedUnits: [KeyValue_t] = [
    KeyValue_t(key: NetworkSpeedUnitAuto, value: "Auto"),
    KeyValue_t(key: SizeUnit.KB.key, value: "KB/Kb"),
    KeyValue_t(key: SizeUnit.MB.key, value: "MB/Mb"),
    KeyValue_t(key: SizeUnit.GB.key, value: "GB/Gb"),
    KeyValue_t(key: SizeUnit.TB.key, value: "TB/Tb")
]

public func networkSpeedUnit(from key: String) -> KeyValue_t {
    NetworkSpeedUnits.first(where: { $0.key.lowercased() == key.lowercased() }) ?? NetworkSpeedUnits[0]
}

public func networkSpeedSizeUnit(from key: String) -> SizeUnit? {
    let unit = networkSpeedUnit(from: key)
    return unit.key == NetworkSpeedUnitAuto ? nil : SizeUnit.fromString(unit.key)
}

public func networkSpeedPrefix(from key: String) -> String? {
    let unit = networkSpeedUnit(from: key)
    return unit.key == NetworkSpeedUnitAuto ? nil : String(unit.key.prefix(1))
}

internal enum StackMode: String {
    case auto = "automatic"
    case oneRow = "oneRow"
    case twoRows = "twoRows"
}

internal let SensorsWidgetValue: [KeyValue_t] = [
    KeyValue_t(key: "oi", value: "output/input"),
    KeyValue_t(key: "io", value: "input/output"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: "i", value: "input"),
    KeyValue_t(key: "o", value: "output")
]

internal let SensorsWidgetMode: [KeyValue_t] = [
    KeyValue_t(key: StackMode.auto.rawValue, value: "Automatic"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: StackMode.oneRow.rawValue, value: "One row"),
    KeyValue_t(key: StackMode.twoRows.rawValue, value: "Two rows")
]

internal let SpeedPictogram: [KeyValue_t] = [
    KeyValue_t(key: "none", value: "None"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: "dots", value: "Dots"),
    KeyValue_t(key: "arrows", value: "Arrows"),
    KeyValue_t(key: "chars", value: "Characters")
]
internal let SpeedPictogramColor: [KeyValue_t] = [
    KeyValue_t(key: "none", value: "None"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: "default", value: "Default color"),
    KeyValue_t(key: "transparent", value: "Transparent when no activity"),
    KeyValue_t(key: "constant", value: "Constant color")
]

internal let BatteryAdditionals: [KeyValue_t] = [
    KeyValue_t(key: "none", value: "None"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: "innerPercentage", value: "Percentage inside the icon"),
    KeyValue_t(key: "separator", value: "separator"),
    KeyValue_t(key: "percentage", value: "Percentage"),
    KeyValue_t(key: "time", value: "Time"),
    KeyValue_t(key: "percentageAndTime", value: "Percentage and time"),
    KeyValue_t(key: "timeAndPercentage", value: "Time and percentage")
]

internal let BatteryInfo: [KeyValue_t] = [
    KeyValue_t(key: "percentage", value: "Percentage"),
    KeyValue_t(key: "time", value: "Time"),
    KeyValue_t(key: "percentageAndTime", value: "Percentage and time"),
    KeyValue_t(key: "timeAndPercentage", value: "Time and percentage")
]

public let ShortLong: [KeyValue_t] = [
    KeyValue_t(key: "short", value: "Short"),
    KeyValue_t(key: "long", value: "Long")
]

public let ReaderUpdateIntervals: [KeyValue_t] = [
    KeyValue_t(key: "1", value: "1 sec"),
    KeyValue_t(key: "2", value: "2 sec"),
    KeyValue_t(key: "3", value: "3 sec"),
    KeyValue_t(key: "5", value: "5 sec"),
    KeyValue_t(key: "10", value: "10 sec"),
    KeyValue_t(key: "15", value: "15 sec"),
    KeyValue_t(key: "30", value: "30 sec"),
    KeyValue_t(key: "60", value: "60 sec")
]
public let NumbersOfProcesses: [Int] = [0, 3, 5, 8, 10, 15]

public let NetworkReaders: [KeyValue_t] = [
    KeyValue_t(key: "interface", value: "Interface based"),
    KeyValue_t(key: "process", value: "Processes based")
]

internal let Alignments: [KeyValue_t] = [
    KeyValue_t(key: "left", value: "Left alignment", additional: NSTextAlignment.left),
    KeyValue_t(key: "center", value: "Center alignment", additional: NSTextAlignment.center),
    KeyValue_t(key: "right", value: "Right alignment", additional: NSTextAlignment.right)
]

public struct SColor: KeyValue_p, Equatable {
    public let key: String
    public let value: String
    public var additional: Any?
    
    private static let customPrefix = "custom:"
    
    public static func == (lhs: SColor, rhs: SColor) -> Bool {
        return lhs.key == rhs.key
    }
    
    public static func custom(_ color: NSColor) -> SColor {
        return SColor(key: "\(customPrefix)\(color.hexString)", value: "Custom...", additional: color)
    }
    
    public var isCustom: Bool {
        return self.key.hasPrefix(SColor.customPrefix)
    }
}

extension SColor: CaseIterable {
    public static var utilization: SColor { SColor(key: "utilization", value: "Based on utilization", additional: NSColor.black) }
    public static var pressure: SColor { SColor(key: "pressure", value: "Based on pressure", additional: NSColor.black) }
    public static var cluster: SColor { SColor(key: "cluster", value: "Based on cluster", additional: NSColor.controlAccentColor) }
    
    public static var separator1: SColor { SColor(key: "separator_1", value: "separator_1", additional: NSColor.black) }
    
    public static var systemAccent: SColor { SColor(key: "system", value: "System accent", additional: NSColor.controlAccentColor) }
    public static var monochrome: SColor { SColor(key: "monochrome", value: "Monochrome accent", additional: NSColor.textColor) }
    
    public static var separator2: SColor { SColor(key: "separator_2", value: "separator_2", additional: NSColor.black) }
    
    public static var clear: SColor { SColor(key: "clear", value: "Clear", additional: NSColor.clear) }
    public static var white: SColor { SColor(key: "white", value: "White", additional: NSColor.white) }
    public static var black: SColor { SColor(key: "black", value: "Black", additional: NSColor.black) }
    public static var gray: SColor { SColor(key: "gray", value: "Gray", additional: NSColor.gray) }
    public static var secondGray: SColor { SColor(key: "secondGray", value: "Second gray", additional: NSColor.systemGray) }
    public static var darkGray: SColor { SColor(key: "darkGray", value: "Dark gray", additional: NSColor.darkGray) }
    public static var lightGray: SColor { SColor(key: "lightGray", value: "Light gray", additional: NSColor.lightGray) }
    public static var red: SColor { SColor(key: "red", value: "Red", additional: NSColor.red) }
    public static var secondRed: SColor { SColor(key: "secondRed", value: "Second red", additional: NSColor.systemRed) }
    public static var green: SColor { SColor(key: "green", value: "Green", additional: NSColor.green) }
    public static var secondGreen: SColor { SColor(key: "secondGreen", value: "Second green", additional: NSColor.systemGreen) }
    public static var blue: SColor { SColor(key: "blue", value: "Blue", additional: NSColor.blue) }
    public static var secondBlue: SColor { SColor(key: "secondBlue", value: "Second blue", additional: NSColor.systemBlue) }
    public static var yellow: SColor { SColor(key: "yellow", value: "Yellow", additional: NSColor.yellow) }
    public static var secondYellow: SColor { SColor(key: "secondYellow", value: "Second yellow", additional: NSColor.systemYellow) }
    public static var orange: SColor { SColor(key: "orange", value: "Orange", additional: NSColor.orange) }
    public static var secondOrange: SColor { SColor(key: "secondOrange", value: "Second orange", additional: NSColor.systemOrange) }
    public static var purple: SColor { SColor(key: "purple", value: "Purple", additional: NSColor.purple) }
    public static var secondPurple: SColor { SColor(key: "secondPurple", value: "Second purple", additional: NSColor.systemPurple) }
    public static var brown: SColor { SColor(key: "brown", value: "Brown", additional: NSColor.brown) }
    public static var secondBrown: SColor { SColor(key: "secondBrown", value: "Second brown", additional: NSColor.systemBrown) }
    public static var cyan: SColor { SColor(key: "cyan", value: "Cyan", additional: NSColor.cyan) }
    public static var magenta: SColor { SColor(key: "magenta", value: "Magenta", additional: NSColor.magenta) }
    public static var pink: SColor { SColor(key: "pink", value: "Pink", additional: NSColor.systemPink) }
    public static var teal: SColor { SColor(key: "teal", value: "Teal", additional: NSColor.systemTeal) }
    public static var indigo: SColor { SColor(key: "indigo", value: "Indigo", additional: NSColor.systemIndigo) }
    
    public static var allCases: [SColor] {
        return [.utilization, .pressure, .cluster, separator1,
                .systemAccent, .monochrome, separator2,
                .clear, .white, .black, .gray, .secondGray, .darkGray, .lightGray,
                .red, .secondRed, .green, .secondGreen, .blue, .secondBlue, .yellow, .secondYellow,
                .orange, .secondOrange, .purple, .secondPurple, .brown, .secondBrown,
                .cyan, .magenta, .pink, .teal, .indigo
        ]
    }
    
    public static var allColors: [SColor] {
        return [.systemAccent, .monochrome, .separator2, .clear, .white, .black, .gray, .secondGray, .darkGray, .lightGray,
                .red, .secondRed, .green, .secondGreen, .blue, .secondBlue, .yellow, .secondYellow,
                .orange, .secondOrange, .purple, .secondPurple, .brown, .secondBrown,
                .cyan, .magenta, .pink, .teal, .indigo
        ]
    }
    
    public static func fromString(_ key: String, defaultValue: SColor = .systemAccent) -> SColor {
        if let color = SColor.allCases.first(where: { $0.key == key }) {
            return color
        }
        if key.hasPrefix(customPrefix), let color = NSColor(hex: String(key.dropFirst(customPrefix.count))) {
            return SColor.custom(color)
        }
        return defaultValue
    }
}

internal class MonochromeColor {
    static internal let red: NSColor = NSColor(red: 145/255, green: 145/255, blue: 145/255, alpha: 1)
    static internal let blue: NSColor = NSColor(red: 113/255, green: 113/255, blue: 113/255, alpha: 1)
}

public typealias colorZones = (orange: Double, red: Double)

public extension Notification.Name {
    static let toggleSettings = Notification.Name("toggleSettings")
    static let toggleModule = Notification.Name("toggleModule")
    static let togglePopup = Notification.Name("togglePopup")
    static let popupVisibilityChanged = Notification.Name("popupVisibilityChanged")
    static let toggleWidget = Notification.Name("toggleWidget")
    static let togglePreview = Notification.Name("togglePreview")
    static let openModuleSettings = Notification.Name("openModuleSettings")
    static let clickInSettings = Notification.Name("clickInSettings")
    static let refreshPublicIP = Notification.Name("refreshPublicIP")
    static let resetTotalNetworkUsage = Notification.Name("resetTotalNetworkUsage")
    static let syncFansControl = Notification.Name("syncFansControl")
    static let checkFanModes = Notification.Name("checkFanModes")
    static let fanHelperState = Notification.Name("fanHelperState")
    static let toggleOneView = Notification.Name("toggleOneView")
    static let widgetRearrange = Notification.Name("widgetRearrange")
    static let moduleRearrange = Notification.Name("moduleRearrange")
    static let pause = Notification.Name("pause")
    static let toggleFanControl = Notification.Name("toggleFanControl")
    static let fanCurveManualOverride = Notification.Name("fanCurveManualOverride")
    static let fanCurveProfileState = Notification.Name("fanCurveProfileState")
    static let combinedModulesPopup = Notification.Name("combinedModulesPopup")
    static let remoteLoginSuccess = Notification.Name("remoteLoginSuccess")
    static let remoteState = Notification.Name("remoteState")
    static let remoteAuthenticated = Notification.Name("remoteAuthenticated")
    static let remoteUpdate = Notification.Name("remoteUpdate")
    static let openWindow = Notification.Name("openWindow")
}

public var isARM: Bool {
    SystemKit.shared.device.platform != .intel
}

public let notificationLevels: [KeyValue_t] = [
    KeyValue_t(key: "", value: "Disabled"),
    KeyValue_t(key: "0.03", value: "3%"),
    KeyValue_t(key: "0.05", value: "5%"),
    KeyValue_t(key: "0.1", value: "10%"),
    KeyValue_t(key: "0.15", value: "15%"),
    KeyValue_t(key: "0.2", value: "20%"),
    KeyValue_t(key: "0.25", value: "25%"),
    KeyValue_t(key: "0.3", value: "30%"),
    KeyValue_t(key: "0.35", value: "35%"),
    KeyValue_t(key: "0.4", value: "40%"),
    KeyValue_t(key: "0.45", value: "45%"),
    KeyValue_t(key: "0.5", value: "50%"),
    KeyValue_t(key: "0.55", value: "55%"),
    KeyValue_t(key: "0.6", value: "60%"),
    KeyValue_t(key: "0.65", value: "65%"),
    KeyValue_t(key: "0.7", value: "70%"),
    KeyValue_t(key: "0.75", value: "75%"),
    KeyValue_t(key: "0.8", value: "80%"),
    KeyValue_t(key: "0.85", value: "85%"),
    KeyValue_t(key: "0.9", value: "90%"),
    KeyValue_t(key: "0.95", value: "95%"),
    KeyValue_t(key: "0.97", value: "97%"),
    KeyValue_t(key: "1.0", value: "100%")
]

public struct Scale: KeyValue_p, Equatable {
    public let key: String
    public let value: String
    
    public static func == (lhs: Scale, rhs: Scale) -> Bool {
        return lhs.key == rhs.key
    }
}

extension Scale: CaseIterable {
    public static var none: Scale { return Scale(key: "none", value: "None") }
    public static var separator: Scale { return Scale(key: "separator", value: "separator") }
    public static var linear: Scale { return Scale(key: "linear", value: "Linear") }
    public static var square: Scale { return Scale(key: "square", value: "Square") }
    public static var cube: Scale { return Scale(key: "cube", value: "Cube") }
    public static var logarithmic: Scale { return Scale(key: "logarithmic", value: "Logarithmic") }
    public static var separator2: Scale { return Scale(key: "separator", value: "separator") }
    public static var fixed: Scale { return Scale(key: "fixed", value: "Fixed scale") }
    
    public static var allCases: [Scale] {
        return [.none, .separator, .linear, .square, .cube, .logarithmic, .separator2, .fixed]
    }
    
    public static func fromString(_ key: String, defaultValue: Scale = .linear) -> Scale {
        return Scale.allCases.first{ $0.key == key } ?? defaultValue
    }
}

public enum FanValue: String {
    case rpm
    case percentage
}

/// The interpolation shape used by a native fan curve.
public enum FanCurveShape: String, Codable, CaseIterable {
    case linear
    case easeIn
    case sCurve
}

/// One temperature/speed point in a fan curve. Speed is normalized to 0...1.
public struct FanCurvePoint: Codable, Equatable {
    public var temperatureC: Double
    public var speedPercent: Double

    public init(temperatureC: Double, speedPercent: Double) {
        self.temperatureC = temperatureC
        self.speedPercent = speedPercent
    }
}

/// Parameters shared by built-in and user-created profiles.
public struct FanCurveParameters: Codable, Equatable {
    public var stopTemperatureC: Double
    public var startTemperatureC: Double
    public var ceilingTemperatureC: Double
    public var maxSpeedPercent: Double
    public var rampUpPerSecond: Double
    public var rampDownPerSecond: Double
    public var sustainedTriggerSeconds: Double
    public var curveShape: FanCurveShape
    public var instantEngage: Bool
    public var alwaysOn: Bool
    public var handsOff: Bool

    public init(
        stopTemperatureC: Double = 50,
        startTemperatureC: Double = 55,
        ceilingTemperatureC: Double = 85,
        maxSpeedPercent: Double = 1,
        rampUpPerSecond: Double = 0.05,
        rampDownPerSecond: Double = 0.025,
        sustainedTriggerSeconds: Double = 0,
        curveShape: FanCurveShape = .linear,
        instantEngage: Bool = false,
        alwaysOn: Bool = false,
        handsOff: Bool = false
    ) {
        self.stopTemperatureC = stopTemperatureC
        self.startTemperatureC = startTemperatureC
        self.ceilingTemperatureC = ceilingTemperatureC
        self.maxSpeedPercent = maxSpeedPercent
        self.rampUpPerSecond = rampUpPerSecond
        self.rampDownPerSecond = rampDownPerSecond
        self.sustainedTriggerSeconds = sustainedTriggerSeconds
        self.curveShape = curveShape
        self.instantEngage = instantEngage
        self.alwaysOn = alwaysOn
        self.handsOff = handsOff
    }
}

/// A persisted, native fan-control strategy.
public struct FanCurveProfile: Codable, Equatable, Identifiable {
    public let id: String
    public var name: String
    public var parameters: FanCurveParameters
    public var points: [FanCurvePoint]
    /// Optional points for a specific physical fan id.
    public var fanOverrides: [Int: [FanCurvePoint]]

    public init(
        id: String,
        name: String,
        parameters: FanCurveParameters = FanCurveParameters(),
        points: [FanCurvePoint] = [],
        fanOverrides: [Int: [FanCurvePoint]] = [:]
    ) {
        self.id = id
        self.name = name
        self.parameters = parameters
        self.points = points
        self.fanOverrides = fanOverrides
    }

    /// Returns a normalized target in the range 0...1 for the given temperature.
    /// Invalid/non-finite temperatures fail closed to zero.
    public func speedPercent(at temperatureC: Double, fanID: Int? = nil) -> Double {
        guard temperatureC.isFinite else { return 0 }

        let params = self.parameters
        let stop = min(params.stopTemperatureC, params.startTemperatureC)
        let start = max(stop, params.startTemperatureC)
        let ceiling = max(start, params.ceilingTemperatureC)
        let cap = Self.clamp(params.maxSpeedPercent)
        let curve = (fanID.flatMap { self.fanOverrides[$0] } ?? self.points)
            .filter { $0.temperatureC.isFinite && $0.speedPercent.isFinite }
            .sorted { $0.temperatureC < $1.temperatureC }

        if !params.alwaysOn && temperatureC < start {
            return 0
        }
        if temperatureC <= stop && !params.alwaysOn {
            return 0
        }
        if cap <= 0 || params.handsOff && temperatureC < start {
            return 0
        }

        let value: Double
        if temperatureC >= ceiling {
            value = cap
        } else if curve.isEmpty {
            let range = max(ceiling - start, 0.001)
            value = cap * Self.shape((temperatureC - start) / range, shape: params.curveShape)
        } else {
            value = min(cap, Self.interpolate(curve, temperatureC: temperatureC, shape: params.curveShape))
        }

        return Self.clamp(value)
    }

    private static func interpolate(_ points: [FanCurvePoint], temperatureC: Double, shape: FanCurveShape) -> Double {
        guard let first = points.first else { return 0 }
        if temperatureC <= first.temperatureC { return clamp(first.speedPercent) }
        guard let last = points.last else { return 0 }
        if temperatureC >= last.temperatureC { return clamp(last.speedPercent) }

        for pair in zip(points, points.dropFirst()) {
            let left = pair.0
            let right = pair.1
            guard temperatureC <= right.temperatureC else { continue }
            let distance = max(right.temperatureC - left.temperatureC, 0.001)
            let fraction = (temperatureC - left.temperatureC) / distance
            let shaped = Self.shape(fraction, shape: shape)
            return clamp(left.speedPercent + (right.speedPercent - left.speedPercent) * shaped)
        }
        return clamp(last.speedPercent)
    }

    private static func shape(_ value: Double, shape: FanCurveShape) -> Double {
        let t = clamp(value)
        switch shape {
        case .linear:
            return t
        case .easeIn:
            return t * t
        case .sCurve:
            return t * t * (3 - (2 * t))
        }
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    public static let builtIns: [FanCurveProfile] = [
        FanCurveProfile(
            id: "silent",
            name: "Silent",
            parameters: FanCurveParameters(
                stopTemperatureC: 50,
                startTemperatureC: 55,
                ceilingTemperatureC: 55,
                maxSpeedPercent: 0,
                rampUpPerSecond: 0.05,
                rampDownPerSecond: 0.025,
                sustainedTriggerSeconds: 8,
                handsOff: true
            ),
            points: [FanCurvePoint(temperatureC: 55, speedPercent: 0)]
        ),
        FanCurveProfile(
            id: "balanced",
            name: "Balanced",
            parameters: FanCurveParameters(
                stopTemperatureC: 50,
                startTemperatureC: 55,
                ceilingTemperatureC: 70,
                maxSpeedPercent: 0.6,
                rampUpPerSecond: 0.05,
                rampDownPerSecond: 0.025,
                sustainedTriggerSeconds: 8,
                curveShape: .easeIn
            ),
            points: [
                FanCurvePoint(temperatureC: 55, speedPercent: 0),
                FanCurvePoint(temperatureC: 70, speedPercent: 1)
            ]
        ),
        FanCurveProfile(
            id: "performance",
            name: "Performance",
            parameters: FanCurveParameters(
                stopTemperatureC: 50,
                startTemperatureC: 55,
                ceilingTemperatureC: 65,
                maxSpeedPercent: 0.85,
                rampUpPerSecond: 0.1,
                rampDownPerSecond: 0.04,
                sustainedTriggerSeconds: 4
            ),
            points: [
                FanCurvePoint(temperatureC: 55, speedPercent: 0.15),
                FanCurvePoint(temperatureC: 65, speedPercent: 1)
            ]
        ),
        FanCurveProfile(
            id: "max",
            name: "Max",
            parameters: FanCurveParameters(
                stopTemperatureC: 0,
                startTemperatureC: 0,
                ceilingTemperatureC: 65,
                maxSpeedPercent: 1,
                rampUpPerSecond: 1,
                rampDownPerSecond: 0.1,
                sustainedTriggerSeconds: 0,
                instantEngage: true
            ),
            points: [FanCurvePoint(temperatureC: 0, speedPercent: 1)]
        ),
        FanCurveProfile(
            id: "smart",
            name: "Smart",
            parameters: FanCurveParameters(
                stopTemperatureC: 50,
                startTemperatureC: 53,
                ceilingTemperatureC: 85,
                maxSpeedPercent: 1,
                rampUpPerSecond: 0.05,
                rampDownPerSecond: 0.025,
                sustainedTriggerSeconds: 6,
                curveShape: .sCurve
            ),
            points: [
                FanCurvePoint(temperatureC: 53, speedPercent: 0.1),
                FanCurvePoint(temperatureC: 85, speedPercent: 1)
            ]
        )
    ]
}

public let FanValues: [KeyValue_t] = [
    KeyValue_t(key: "rpm", value: "RPM", additional: FanValue.rpm),
    KeyValue_t(key: "percentage", value: "Percentage", additional: FanValue.percentage)
]

public var LineChartHistory: [KeyValue_p] = [
    KeyValue_t(key: "60", value: "1 minute"),
    KeyValue_t(key: "120", value: "2 minutes"),
    KeyValue_t(key: "180", value: "3 minutes"),
    KeyValue_t(key: "300", value: "5 minutes"),
    KeyValue_t(key: "600", value: "10 minutes")
]

public struct SizeUnit: KeyValue_p, Equatable {
    public let key: String
    public let value: String
    
    public static func == (lhs: SizeUnit, rhs: SizeUnit) -> Bool {
        return lhs.key == rhs.key
    }
}

extension SizeUnit: CaseIterable {
    public static var byte: SizeUnit { return SizeUnit(key: "byte", value: "Bytes") }
    public static var KB: SizeUnit { return SizeUnit(key: "KB", value: "KB") }
    public static var MB: SizeUnit { return SizeUnit(key: "MB", value: "MB") }
    public static var GB: SizeUnit { return SizeUnit(key: "GB", value: "GB") }
    public static var TB: SizeUnit { return SizeUnit(key: "TB", value: "TB") }
    
    public static var allCases: [SizeUnit] {
        [.byte, .KB, .MB, .GB, .TB]
    }
    
    public static func fromString(_ key: String, defaultValue: SizeUnit = .byte) -> SizeUnit {
        return SizeUnit.allCases.first{ $0.key == key } ?? defaultValue
    }
    
    public func toBytes(_ value: Int) -> Int {
        switch self {
        case .KB:
            return value * 1_000
        case .MB:
            return value * 1_000 * 1_000
        case .GB:
            return value * 1_000 * 1_000 * 1_000
        case .TB:
            return value * 1_000 * 1_000 * 1_000 * 1_000
        default:
            return value
        }
    }
}

public enum RAMPressure: String, Codable {
    case normal
    case warning
    case critical
    
    public func pressureColor() -> NSColor {
        switch self {
        case .normal:
            return NSColor.systemGreen
        case .warning:
            return NSColor.systemOrange
        case .critical:
            return NSColor.systemRed
        }
    }
    
    public func number() -> Int {
        switch self {
        case .normal:
            return 0
        case .warning:
            return 1
        case .critical:
            return 2
        }
    }
    
    public init(from: Int) {
        switch from {
        case 1:
            self = .warning
        case 2:
            self = .critical
        default:
            self = .normal
        }
    }
}

public struct TokenResponse: Codable {
    public let access_token: String
    public let refresh_token: String
}

public struct DeviceResponse: Codable {
    public let device_code: String
    public let user_code: String
    public let verification_uri_complete: URL
    public let interval: Int?
}
