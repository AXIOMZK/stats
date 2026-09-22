//
//  main.swift
//  Sensors
//
//  Created by Serhiy Mytrovtsiy on 17/06/2020.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2020 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import Kit

private struct FanCurveStorePayload: Codable {
    var version: Int
    var profiles: [FanCurveProfile]
    var activeProfileID: String?
}

internal final class FanCurveProfileStore {
    private let key = "Sensors_fanCurveProfiles_v1"
    private(set) var profiles: [FanCurveProfile]
    private(set) var activeProfileID: String?

    init() {
        if let data = Store.shared.data(key: self.key),
           let payload = try? JSONDecoder().decode(FanCurveStorePayload.self, from: data),
           payload.version == 1 {
            self.profiles = payload.profiles
            self.activeProfileID = payload.activeProfileID
        } else {
            self.profiles = FanCurveProfile.builtIns
            self.activeProfileID = nil
        }

        let existingIDs = Set(self.profiles.map(\.id))
        self.profiles.append(contentsOf: FanCurveProfile.builtIns.filter { !existingIDs.contains($0.id) })
        if let active = self.activeProfileID, !self.profiles.contains(where: { $0.id == active }) {
            self.activeProfileID = nil
        }
        self.persist()
    }

    func profile(id: String) -> FanCurveProfile? {
        self.profiles.first { $0.id == id }
    }

    func upsert(_ profile: FanCurveProfile) {
        if let index = self.profiles.firstIndex(where: { $0.id == profile.id }) {
            self.profiles[index] = profile
        } else {
            self.profiles.append(profile)
        }
        self.persist()
    }

    func remove(id: String) {
        guard !FanCurveProfile.builtIns.contains(where: { $0.id == id }) else { return }
        self.profiles.removeAll { $0.id == id }
        if self.activeProfileID == id {
            self.activeProfileID = nil
        }
        self.persist()
    }

    func setActive(_ id: String?) {
        self.activeProfileID = id
        self.persist()
    }

    private func persist() {
        let payload = FanCurveStorePayload(version: 1, profiles: self.profiles, activeProfileID: self.activeProfileID)
        if let data = try? JSONEncoder().encode(payload) {
            Store.shared.set(key: self.key, value: data)
        }
    }
}

/// Applies a persisted profile to real fans while leaving FanView as the
/// explicit manual-control owner. This controller only writes automatic curve
/// targets and fails closed to automatic mode when inputs are unavailable.
internal final class FanCurveController {
    private let store: FanCurveProfileStore
    private var currentFans: [Fan] = []
    private var lastTargets: [Int: Double] = [:]
    private var lastUpdate: TimeInterval = ProcessInfo.processInfo.systemUptime
    private var sustainedSince: TimeInterval?
    private var controlledFanIDs: Set<Int> = []
    private var currentSensors: [Sensor_p] = []

    init(store: FanCurveProfileStore) {
        self.store = store
        NotificationCenter.default.addObserver(self, selector: #selector(self.manualOverride), name: .fanCurveManualOverride, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.fanControlStateChanged), name: .toggleFanControl, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.sleep), name: NSWorkspace.willSleepNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    var activeProfileID: String? { self.store.activeProfileID }

    func apply(profileID: String, fans: [Fan]) {
        guard self.store.profile(id: profileID) != nil else { return }
        self.store.setActive(profileID)
        self.lastTargets.removeAll()
        self.sustainedSince = nil
        self.currentFans = fans
        self.postState()
        // Apply the selected profile immediately when a sensor snapshot is
        // already available. Without this, Apply only changed persisted state
        // and the first hardware write waited for the next reader tick.
        if !self.currentSensors.isEmpty {
            self.update(self.currentSensors)
        }
    }

    func restoreAutomatic(fans: [Fan]? = nil) {
        let fans = fans ?? self.currentFans
        self.store.setActive(nil)
        self.lastTargets.removeAll()
        self.sustainedSince = nil
        self.controlledFanIDs.removeAll()
        // The first automatic update may be the operation that establishes
        // the XPC connection. Do not gate this on isActive(), which is only a
        // snapshot of a connection that may not exist yet.
        fans.filter { $0.id >= 0 }.forEach { fan in
            SMCHelper.shared.setFanMode(fan.id, mode: FanMode.automatic.rawValue)
        }
        self.postState()
    }

    func update(_ sensors: [Sensor_p]) {
        self.currentSensors = sensors
        let fans = sensors.compactMap { $0 as? Fan }.filter { $0.id >= 0 }
        guard !fans.isEmpty else { return }
        self.currentFans = fans
        guard let profileID = self.store.activeProfileID,
              let profile = self.store.profile(id: profileID) else { return }

        let temperatures = sensors.filter {
            $0.type == .temperature && ($0.group == .CPU || $0.group == .GPU) && $0.value.isFinite && $0.value > 0
        }.map(\.value)
        let fallbackTemperatures = sensors.filter {
            $0.type == .temperature && $0.value.isFinite && $0.value > 0
        }.map(\.value)
        guard let temperature = (temperatures.isEmpty ? fallbackTemperatures : temperatures).max() else {
            self.restoreAutomatic(fans: fans)
            return
        }

        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = min(max(now - self.lastUpdate, 0.1), 10)
        self.lastUpdate = now

        if profile.parameters.sustainedTriggerSeconds > 0 && temperature >= profile.parameters.startTemperatureC {
            if self.sustainedSince == nil {
                self.sustainedSince = now
            }
            guard now - (self.sustainedSince ?? now) >= profile.parameters.sustainedTriggerSeconds else { return }
        } else if temperature < profile.parameters.startTemperatureC {
            self.sustainedSince = nil
        }

        fans.forEach { fan in
            let desired = profile.speedPercent(at: temperature, fanID: fan.id)
            let current = self.lastTargets[fan.id] ?? Double(max(fan.percentage, 0)) / 100
            let target: Double
            if profile.parameters.instantEngage {
                target = desired
            } else {
                let rate = desired >= current ? profile.parameters.rampUpPerSecond : profile.parameters.rampDownPerSecond
                let delta = max(rate, 0) * elapsed
                target = delta == 0 ? desired : min(max(desired, current - delta), current + delta)
            }
            self.lastTargets[fan.id] = target

            // setFanMode/setFanSpeed establish the helper connection lazily;
            // checking isActive() here would make Apply a no-op on first use.
            if target <= 0.001 {
                if self.controlledFanIDs.contains(fan.id) {
                    SMCHelper.shared.setFanMode(fan.id, mode: FanMode.automatic.rawValue)
                    self.controlledFanIDs.remove(fan.id)
                }
                return
            }

            let minimum = max(fan.minSpeed, 0)
            let maximum = max(fan.maxSpeed, minimum)
            let speed = Int(round(minimum + (maximum - minimum) * min(max(target, 0), 1)))
            self.controlledFanIDs.insert(fan.id)
            SMCHelper.shared.setFanMode(fan.id, mode: FanMode.forced.rawValue)
            SMCHelper.shared.setFanSpeed(fan.id, speed: speed)
        }
    }

    @objc private func manualOverride(_ notification: Notification) {
        guard self.store.activeProfileID != nil else { return }
        self.store.setActive(nil)
        self.lastTargets.removeAll()
        self.sustainedSince = nil
        self.controlledFanIDs.removeAll()
        self.postState()
    }

    @objc private func sleep() {
        self.restoreAutomatic()
    }

    @objc private func fanControlStateChanged(_ notification: Notification) {
        guard let state = notification.userInfo?["state"] as? Bool, !state else { return }
        self.restoreAutomatic()
    }

    private func postState() {
        var userInfo: [AnyHashable: Any] = [:]
        if let activeID = self.store.activeProfileID {
            userInfo["activeID"] = activeID
        }
        NotificationCenter.default.post(name: .fanCurveProfileState, object: nil, userInfo: userInfo)
    }
}

public class Sensors: Module {
    private var sensorsReader: SensorsReader?
    private let popupView: Popup
    private let settingsView: Settings
    private let portalView: Portal
    private let notificationsView: Notifications
    private let fanCurveStore: FanCurveProfileStore
    private let fanCurveController: FanCurveController
    
    private var fanValueState: FanValue {
        FanValue(rawValue: Store.shared.string(key: "\(self.config.name)_fanValue", defaultValue: "percentage")) ?? .percentage
    }
    
    private var selectedSensor: String
    
    public init() {
        self.settingsView = Settings(.sensors)
        self.popupView = Popup()
        self.portalView = Portal(.sensors)
        self.notificationsView = Notifications(.sensors)
        self.fanCurveStore = FanCurveProfileStore()
        self.fanCurveController = FanCurveController(store: self.fanCurveStore)
        self.selectedSensor = Store.shared.string(key: "\(ModuleType.sensors.stringValue)_sensor", defaultValue: "Average System Total")
        
        super.init(
            moduleType: .sensors,
            popup: self.popupView,
            settings: self.settingsView,
            portal: self.portalView,
            notifications: self.notificationsView
        )
        guard self.available else { return }
        
        self.sensorsReader = SensorsReader { [weak self] value in
            self?.usageCallback(value)
        }
        
        self.settingsView.setList(self.sensorsReader?.list.sensors)
        self.popupView.setup(self.sensorsReader?.list.sensors)
        self.configureFanCurvePopup()
        self.portalView.setup(self.sensorsReader?.list.sensors)
        self.notificationsView.setup(self.sensorsReader?.list.sensors)
        
        self.settingsView.callback = { [weak self] in
            self?.sensorsReader?.read()
        }
        self.settingsView.setInterval = { [weak self] value in
            self?.sensorsReader?.setInterval(value)
        }
        self.settingsView.HIDcallback = { [weak self] in
            DispatchQueue.global(qos: .background).async {
                self?.sensorsReader?.HIDCallback()
                DispatchQueue.main.async {
                    self?.popupView.setup(self?.sensorsReader?.list.sensors)
                    self?.portalView.setup(self?.sensorsReader?.list.sensors)
                    self?.settingsView.setList(self?.sensorsReader?.list.sensors)
                    self?.notificationsView.setup(self?.sensorsReader?.list.sensors)
                }
            }
        }
        self.settingsView.unknownCallback = { [weak self] in
            DispatchQueue.global(qos: .background).async {
                self?.sensorsReader?.unknownCallback()
                DispatchQueue.main.async {
                    self?.popupView.setup(self?.sensorsReader?.list.sensors)
                    self?.portalView.setup(self?.sensorsReader?.list.sensors)
                    self?.settingsView.setList(self?.sensorsReader?.list.sensors)
                    self?.notificationsView.setup(self?.sensorsReader?.list.sensors)
                }
            }
        }
        self.selectedSensor = Store.shared.string(key: "\(ModuleType.sensors.stringValue)_sensor", defaultValue: self.selectedSensor)
        self.settingsView.selectedHandler = { [weak self] value in
            self?.selectedSensor = value
            self?.sensorsReader?.read()
        }
        
        self.setReaders([self.sensorsReader])
    }
    
    public override func willTerminate() {
        self.fanCurveController.restoreAutomatic(fans: self.sensorsReader?.list.sensors.compactMap { $0 as? Fan })
        guard SMCHelper.shared.isActive(), let reader = self.sensorsReader else { return }
        
        reader.list.sensors.filter({ $0 is Fan }).forEach { (s: Sensor_p) in
            if let f = s as? Fan, let mode = f.customMode {
                if !mode.isAutomatic {
                    SMCHelper.shared.setFanMode(f.id, mode: FanMode.automatic.rawValue)
                }
            }
        }
    }
    
    private func usageCallback(_ raw: Sensors_List?) {
        guard let value = raw, self.enabled else { return }

        self.fanCurveController.update(value.sensors)
        
        self.popupView.usageCallback(value.sensors)
        self.portalView.usageCallback(value.sensors)
        self.notificationsView.usageCallback(value.sensors)
        
        let activeWidgets = self.menuBar.widgets.filter{ $0.isActive }
        self.sensorsReader?.sleepMode(state: activeWidgets.contains(where: {$0.item is Label}) && activeWidgets.count == 1)
        
        activeWidgets.forEach { (w: SWidget) in
            switch w.item {
            case let widget as Mini:
                if let active = value.sensors.first(where: { $0.key == self.selectedSensor }) {
                    var value: Double = active.localValue/100
                    var unit: String = active.miniUnit
                    if let fan = active as? Fan, self.fanValueState == .percentage {
                        value = Double(fan.percentage)/100
                        unit = "%"
                    }
                    if value > 999 {
                        unit = ""
                    }
                    widget.setValue(value)
                    widget.setSuffix(unit)
                }
            case let widget as StackWidget:
                var list: [Stack_t] = []
                
                value.sensors.forEach { (s: Sensor_p) in
                    if s.state {
                        var value = s.formattedMiniValue
                        if let f = s as? Fan {
                            if self.fanValueState == .percentage {
                                value = "\(f.percentage)%"
                            }
                        }
                        list.append(Stack_t(key: s.key, value: value))
                    }
                }
                
                widget.setValues(list)
            case let widget as BarChart:
                var flatList: [[ColorValue]] = []
                value.sensors.filter{ $0 is Fan }.forEach { (s: Sensor_p) in
                    if s.state, let f = s as? Fan {
                        flatList.append([ColorValue(Double(f.percentage) / 100)])
                    }
                }
                widget.setValue(flatList)
            default: break
            }
        }
    }

    private func configureFanCurvePopup() {
        self.popupView.configureFanProfiles(
            profiles: self.fanCurveStore.profiles,
            activeID: self.fanCurveStore.activeProfileID,
            apply: { [weak self] profile in
                guard let self else { return }
                self.fanCurveController.apply(
                    profileID: profile.id,
                    fans: self.sensorsReader?.list.sensors.compactMap { $0 as? Fan } ?? []
                )
            },
            restore: { [weak self] in
                self?.fanCurveController.restoreAutomatic()
            },
            save: { [weak self] profile in
                guard let self else { return }
                self.fanCurveStore.upsert(profile)
                self.configureFanCurvePopup()
            },
            delete: { [weak self] id in
                guard let self else { return }
                self.fanCurveStore.remove(id: id)
                self.configureFanCurvePopup()
            }
        )
    }
}
