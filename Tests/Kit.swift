//
//  Kit.swift
//  Tests
//
//  Created by Serhiy Mytrovtsiy on 04/07/2026.
//  Using Swift 6.0.
//  Running on macOS 26.5.
//
//  Copyright © 2026 Serhiy Mytrovtsiy. All rights reserved.
//

import XCTest
import Cocoa
import Kit

class KitTests: XCTestCase {
    func testFanCurveProfile_respectsTemperatureBoundariesAndCap() throws {
        let profile = FanCurveProfile(
            id: "test",
            name: "Test",
            parameters: FanCurveParameters(
                stopTemperatureC: 45,
                startTemperatureC: 50,
                ceilingTemperatureC: 80,
                maxSpeedPercent: 0.8
            ),
            points: [
                FanCurvePoint(temperatureC: 50, speedPercent: 0.2),
                FanCurvePoint(temperatureC: 65, speedPercent: 0.5),
                FanCurvePoint(temperatureC: 80, speedPercent: 1.0)
            ]
        )

        XCTAssertEqual(profile.speedPercent(at: 40), 0, accuracy: 0.0001)
        XCTAssertEqual(profile.speedPercent(at: 50), 0.2, accuracy: 0.0001)
        XCTAssertEqual(profile.speedPercent(at: 57.5), 0.35, accuracy: 0.0001)
        XCTAssertEqual(profile.speedPercent(at: 80), 0.8, accuracy: 0.0001)
        XCTAssertEqual(profile.speedPercent(at: 100), 0.8, accuracy: 0.0001)
    }

    func testFanCurveProfile_shapesRemainMonotonic() throws {
        let temperatures = stride(from: 50.0, through: 80.0, by: 2.5)
        for shape in FanCurveShape.allCases {
            let profile = FanCurveProfile(
                id: shape.rawValue,
                name: shape.rawValue,
                parameters: FanCurveParameters(
                    startTemperatureC: 50,
                    ceilingTemperatureC: 80,
                    curveShape: shape
                )
            )
            var previous = -1.0
            for temperature in temperatures {
                let current = profile.speedPercent(at: temperature)
                XCTAssertGreaterThanOrEqual(current, previous, "shape=\(shape.rawValue)")
                previous = current
            }
        }
    }

    func testFanCurveProfile_roundTripsThroughJSON() throws {
        let profile = FanCurveProfile(
            id: "custom",
            name: "Custom",
            parameters: FanCurveParameters(
                stopTemperatureC: 48,
                startTemperatureC: 52,
                ceilingTemperatureC: 88,
                maxSpeedPercent: 0.75,
                rampUpPerSecond: 0.1,
                rampDownPerSecond: 0.03,
                sustainedTriggerSeconds: 6,
                curveShape: .sCurve,
                instantEngage: true,
                alwaysOn: false,
                handsOff: false
            ),
            points: [FanCurvePoint(temperatureC: 52, speedPercent: 0.1)],
            fanOverrides: [1: [FanCurvePoint(temperatureC: 60, speedPercent: 0.4)]]
        )

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(FanCurveProfile.self, from: data)
        XCTAssertEqual(decoded, profile)
    }

    func testFanCurveProfile_hasThermalForgeBuiltIns() throws {
        XCTAssertEqual(Set(FanCurveProfile.builtIns.map(\.id)), Set(["silent", "balanced", "performance", "max", "smart"]))
    }

    func testPopupHoverRegionsKeepOpenWhenPointerIsInEitherWindow() throws {
        let regions = PopupHoverRegions(
            main: NSRect(x: 100, y: 100, width: 240, height: 300),
            auxiliary: NSRect(x: 0, y: 120, width: 90, height: 180)
        )

        XCTAssertTrue(regions.contains(NSPoint(x: 120, y: 140)))
        XCTAssertTrue(regions.contains(NSPoint(x: 40, y: 160)))
        XCTAssertFalse(regions.contains(NSPoint(x: 300, y: 160)))
    }

    func testIsNewestVersion_release() throws {
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.0", latestVersion: "v2.11.0"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0", latestVersion: "v2.11.1"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.1", latestVersion: "v2.11.0"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0", latestVersion: "v2.12.0"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.12.0", latestVersion: "v2.11.5"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0", latestVersion: "v3.0.0"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v3.0.0", latestVersion: "v2.99.99"))
    }
    
    func testIsNewestVersion_beta() throws {
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.0-beta1", latestVersion: "v2.11.0-beta1"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.0-beta2", latestVersion: "v2.11.0-beta1"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0-beta1", latestVersion: "v2.11.0-beta2"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0-beta1", latestVersion: "v2.11.0"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.0-beta1", latestVersion: "v2.10.9"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v2.11.0", latestVersion: "v2.11.1-beta1"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v2.11.0-beta1", latestVersion: "v2.11.1-beta1"))
    }
    
    func testIsNewestVersion_malformed() throws {
        XCTAssertFalse(isNewestVersion(currentVersion: "v3", latestVersion: "v3.0.0"))
        XCTAssertTrue(isNewestVersion(currentVersion: "v3", latestVersion: "v3.0.1"))
        XCTAssertFalse(isNewestVersion(currentVersion: "v3.0", latestVersion: "v3.0.0"))
        XCTAssertFalse(isNewestVersion(currentVersion: "", latestVersion: ""))
    }
    
    func testUnitsGetReadableSpeed_byte() throws {
        XCTAssertEqual(Units(bytes: 0).getReadableSpeed(base: .byte), "0 KB/s")
        XCTAssertEqual(Units(bytes: 999).getReadableSpeed(base: .byte), "0 KB/s")
        XCTAssertEqual(Units(bytes: 1_000).getReadableSpeed(base: .byte), "1 KB/s")
        XCTAssertEqual(Units(bytes: 500_000).getReadableSpeed(base: .byte), "500 KB/s")
        XCTAssertEqual(Units(bytes: 2_500_000).getReadableSpeed(base: .byte), "2.5 MB/s")
        XCTAssertEqual(Units(bytes: 150_000_000).getReadableSpeed(base: .byte), "150 MB/s")
        XCTAssertEqual(Units(bytes: 2_000_000_000).getReadableSpeed(base: .byte), "2.0 GB/s")
        XCTAssertEqual(Units(bytes: 2_000_000_000_000).getReadableSpeed(base: .byte), "2.0 TB/s")
        XCTAssertEqual(Units(bytes: -5).getReadableSpeed(base: .byte), "0 KB/s")
    }
    
    func testUnitsGetReadableSpeed_bit() throws {
        XCTAssertEqual(Units(bytes: 100).getReadableSpeed(base: .bit), "0 Kb/s")
        XCTAssertEqual(Units(bytes: 50_000).getReadableSpeed(base: .bit), "400 Kb/s")
        XCTAssertEqual(Units(bytes: 500_000).getReadableSpeed(base: .bit), "4.0 Mb/s")
        XCTAssertEqual(Units(bytes: 200_000_000).getReadableSpeed(base: .bit), "1.6 Gb/s")
        XCTAssertEqual(Units(bytes: 200_000_000_000).getReadableSpeed(base: .bit), "1.6 Tb/s")
    }
    
    func testUnitsGetReadableSpeed_fixedUnit() throws {
        XCTAssertEqual(Units(bytes: 500_000).getReadableSpeed(base: .byte, unit: "KB"), "500 KB/s")
        XCTAssertEqual(Units(bytes: 500_000).getReadableSpeed(base: .byte, unit: "MB"), "0.5 MB/s")
        XCTAssertEqual(Units(bytes: 500_000).getReadableSpeed(base: .bit, unit: "MB"), "4 Mb/s")
    }
}
