//
//  CombinedView.swift
//  Stats
//
//  Created by Serhiy Mytrovtsiy on 09/01/2023
//  Using Swift 5.0
//  Running on macOS 13.1
//
//  Copyright © 2023 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import Kit

internal class CombinedView: NSObject, NSGestureRecognizerDelegate {
    private var menuBarItem: NSStatusItem? = nil
    private var view: NSView = NSView(frame: NSRect(x: 0, y: 0, width: 0, height: Constants.Widget.height))
    private var popup: PopupWindow? = nil
    private var auxiliaryModule: Module? = nil
    private var localMouseMonitor: Any? = nil
    private var globalMouseMonitor: Any? = nil
    private var auxiliaryCloseWorkItem: DispatchWorkItem? = nil
    
    private var status: Bool {
        Store.shared.bool(key: "CombinedModules", defaultValue: false)
    }
    private var spacing: CGFloat {
        CGFloat(Int(Store.shared.string(key: "CombinedModules_spacing", defaultValue: "")) ?? 0)
    }
    private var separator: Bool {
        Store.shared.bool(key: "CombinedModules_separator", defaultValue: false)
    }
    
    private var activeModules: [Module] {
        modules.filter({ $0.enabled }).sorted(by: { $0.combinedPosition < $1.combinedPosition })
    }
    
    private var combinedModulesPopup: Bool {
        get { Store.shared.bool(key: "CombinedModules_popup", defaultValue: true) }
        set { Store.shared.set(key: "CombinedModules_popup", value: newValue) }
    }
    
    override init() {
        super.init()
        
        modules.forEach { (m: Module) in
            m.menuBar.callback = { [weak self] in
                if let s = self?.status, s {
                    DispatchQueue.main.async(execute: {
                        self?.recalculate()
                    })
                }
            }
        }
        
        self.popup = PopupWindow(title: "Combined modules", module: .combined, view: Popup()) { [weak self] state in
            self?.combinedPopupVisibilityChanged(state)
        }

        if self.status {
            self.enable()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(listenForOneView), name: .toggleOneView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(listenForModuleRearrrange), name: .moduleRearrange, object: nil)
    }
    
    deinit {
        self.removeMouseMonitors()
        self.hideAuxiliaryPopup()
        NotificationCenter.default.removeObserver(self, name: .toggleOneView, object: nil)
        NotificationCenter.default.removeObserver(self, name: .moduleRearrange, object: nil)
    }
    
    public func enable() {
        self.installMouseMonitors()
        self.menuBarItem = NSStatusBar.system.statusItem(withLength: 0)
        DispatchQueue.main.async(execute: {
            self.menuBarItem?.autosaveName = "CombinedModules"
        })
        self.menuBarItem?.button?.addSubview(self.view)
        self.menuBarItem?.button?.image = NSImage()
        self.menuBarItem?.button?.toolTip = localizedString("Combined modules")
        
        self.menuBarItem?.button?.target = self
        self.menuBarItem?.button?.action = #selector(self.handleClick)
        self.menuBarItem?.button?.sendAction(on: [.leftMouseDown, .rightMouseDown])
        
        DispatchQueue.main.async(execute: {
            self.recalculate()
        })
    }
    
    public func disable() {
        self.hideAuxiliaryPopup()
        self.popup?.hide()
        self.removeMouseMonitors()
        if let item = self.menuBarItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        self.menuBarItem = nil
    }
    
    private func recalculate() {
        self.view.subviews.forEach({ $0.removeFromSuperview() })
        
        let visibleModules = self.activeModules.filter({ !$0.menuBar.activeWidgets.isEmpty })
        var w: CGFloat = 0
        visibleModules.enumerated().forEach { (i, m) in
            if i != 0 {
                w += self.spacing
                if self.separator {
                    self.view.addSubview(SeparatorLineView(frame: NSRect(x: w, y: 3, width: 1, height: Constants.Widget.height-6)))
                    w += 3 + self.spacing
                }
            }
            self.view.addSubview(m.menuBar.view)
            m.menuBar.view.setFrameOrigin(NSPoint(x: w, y: 0))
            w += m.menuBar.view.frame.width
        }
        self.view.setFrameSize(NSSize(width: w, height: self.view.frame.height))
        self.menuBarItem?.length = w
    }

    private func installMouseMonitors() {
        guard self.localMouseMonitor == nil, self.globalMouseMonitor == nil else { return }

        self.localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handlePointerLocation(NSEvent.mouseLocation)
            return event
        }
        self.globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.handlePointerLocation(NSEvent.mouseLocation)
        }
    }

    private func removeMouseMonitors() {
        if let monitor = self.localMouseMonitor {
            NSEvent.removeMonitor(monitor)
            self.localMouseMonitor = nil
        }
        if let monitor = self.globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            self.globalMouseMonitor = nil
        }
        self.auxiliaryCloseWorkItem?.cancel()
        self.auxiliaryCloseWorkItem = nil
    }

    private func combinedPopupVisibilityChanged(_ state: Bool) {
        if !state {
            self.hideAuxiliaryPopup()
        }
    }

    private func moduleInCombinedPopup(at screenPoint: NSPoint) -> Module? {
        guard let popup = self.popup, popup.isVisible else { return nil }
        return self.activeModules.first { module in
            guard let portal = module.portal, let window = portal.window else { return false }
            let rectInWindow = portal.convert(portal.bounds, to: nil)
            return window.convertToScreen(rectInWindow).contains(screenPoint)
        }
    }

    private func module(at screenPoint: NSPoint) -> Module? {
        self.moduleInCombinedPopup(at: screenPoint)
    }

    private func handlePointerLocation(_ screenPoint: NSPoint) {
        guard let popup = self.popup, popup.isVisible else {
            self.hideAuxiliaryPopup()
            return
        }

        if let auxiliaryModule = self.auxiliaryModule, !auxiliaryModule.popupIsVisible {
            self.hideAuxiliaryPopup()
        }

        if let module = self.module(at: screenPoint) {
            self.auxiliaryCloseWorkItem?.cancel()
            self.auxiliaryCloseWorkItem = nil
            self.showAuxiliaryPopup(for: module, beside: popup.frame)
            return
        }

        let auxiliaryFrame = self.auxiliaryModule?.popupFrame ?? .zero
        let regions = PopupHoverRegions(main: popup.frame, auxiliary: auxiliaryFrame)
        if regions.contains(screenPoint) {
            self.auxiliaryCloseWorkItem?.cancel()
            self.auxiliaryCloseWorkItem = nil
            return
        }

        self.scheduleAuxiliaryPopupDismissal()
    }

    private func scheduleAuxiliaryPopupDismissal() {
        guard self.auxiliaryModule != nil, self.auxiliaryCloseWorkItem == nil else { return }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard let popup = self.popup, popup.isVisible else {
                self.hideAuxiliaryPopup()
                return
            }

            let point = NSEvent.mouseLocation
            let auxiliaryFrame = self.auxiliaryModule?.popupFrame ?? .zero
            let regions = PopupHoverRegions(main: popup.frame, auxiliary: auxiliaryFrame)
            if !regions.contains(point), self.module(at: point) == nil {
                self.hideAuxiliaryPopup()
                popup.hide()
            }
            self.auxiliaryCloseWorkItem = nil
        }
        self.auxiliaryCloseWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }

    private func showAuxiliaryPopup(for module: Module, beside mainFrame: NSRect) {
        guard module.hasPopup else { return }
        if self.auxiliaryModule === module, module.popupIsVisible {
            return
        }

        self.auxiliaryModule?.hidePopup()
        let size = module.popupContentSize
        guard size.width > 0, size.height > 0 else { return }

        self.auxiliaryModule = module
        self.popup?.setKeepVisibleOnResign(true)

        let gap: CGFloat = 6
        let screen = NSScreen.screens.first(where: { $0.frame.intersects(mainFrame) }) ?? NSScreen.main
        var x = mainFrame.minX - size.width - gap
        if let screen, x < screen.frame.minX {
            x = mainFrame.maxX + gap
        }
        var y = mainFrame.maxY - size.height
        if let screen {
            y = min(max(y, screen.visibleFrame.minY + 3), screen.visibleFrame.maxY - size.height - 3)
        }

        module.showPopup(at: NSPoint(x: x, y: y), keepVisibleOnResign: true)
    }

    private func hideAuxiliaryPopup() {
        self.auxiliaryCloseWorkItem?.cancel()
        self.auxiliaryCloseWorkItem = nil
        self.auxiliaryModule?.hidePopup()
        self.auxiliaryModule = nil
        self.popup?.setKeepVisibleOnResign(false)
    }
    
    // call when popup appear/disappear
    private func visibilityCallback(_ state: Bool) {}
    
    @objc private func handleClick() {
        if self.combinedModulesPopup {
            self.togglePopup()
        } else {
            self.openModulePopup()
        }
    }
    
    private func openModulePopup() {
        guard let window = self.menuBarItem?.button?.window else { return }
        let location = self.view.convert(window.convertPoint(fromScreen: NSEvent.mouseLocation), from: nil)
        let visibleModules = self.activeModules.filter({ !$0.menuBar.activeWidgets.isEmpty })
        guard let module = visibleModules.last(where: { $0.menuBar.view.frame.minX <= location.x }) ?? visibleModules.first else { return }
        
        var userInfo: [String: Any] = [
            "module": module.name,
            "origin": window.frame.origin,
            "center": window.frame.width/2
        ]
        let widgetLocation = module.menuBar.view.convert(location, from: self.view)
        let widgets = module.menuBar.activeWidgets
        if let widget = widgets.last(where: { $0.item.frame.minX <= widgetLocation.x }) ?? widgets.first {
            userInfo["widget"] = widget.type
        }
        NotificationCenter.default.post(name: .togglePopup, object: nil, userInfo: userInfo)
    }
    
    private func togglePopup() {
        guard let popup = self.popup, let item = self.menuBarItem, let window = item.button?.window else { return }
        let openedWindows = NSApplication.shared.windows.filter{ $0 is NSPanel }
        openedWindows.forEach{ $0.setIsVisible(false) }
        
        if popup.occlusionState.rawValue == 8192 {
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            popup.contentView?.invalidateIntrinsicContentSize()
            
            let windowCenter = popup.contentView!.intrinsicContentSize.width / 2
            var x = window.frame.origin.x - windowCenter + window.frame.width/2
            let y = window.frame.origin.y - popup.contentView!.intrinsicContentSize.height - 3
            
            let buttonPoint = NSPoint(x: window.frame.midX, y: window.frame.midY)
            if let screen = NSScreen.screens.first(where: { $0.frame.contains(buttonPoint) }) ?? NSScreen.main {
                if x + popup.contentView!.intrinsicContentSize.width > screen.frame.maxX {
                    x = screen.frame.maxX - popup.contentView!.intrinsicContentSize.width - 3
                }
                if x < screen.frame.minX {
                    x = screen.frame.minX + 3
                }
            }
            
            popup.show(at: NSPoint(x: x, y: y))
        } else {
            self.hideAuxiliaryPopup()
            popup.hide()
        }
    }
    
    @objc private func listenForOneView(_ notification: Notification) {
        guard notification.userInfo?["module"] == nil else { return }
        
        if self.status {
            self.enable()
        } else {
            self.disable()
        }
    }
    
    @objc private func listenForModuleRearrrange() {
        self.recalculate()
    }
}

private class SeparatorLineView: NSView {
    override var wantsUpdateLayer: Bool { true }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        self.wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateLayer() {
        self.layer?.backgroundColor = (self.isDarkMode ? NSColor.white : NSColor.black).cgColor
    }
    
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        self.needsDisplay = true
    }
}

private class Popup: NSStackView, Popup_p {
    fileprivate var keyboardShortcut: [UInt16] = []
    fileprivate var sizeCallback: ((NSSize) -> Void)? = nil
    
    init() {
        self.keyboardShortcut = Store.shared.array(key: "CombinedModules_popup_keyboardShortcut", defaultValue: []) as? [UInt16] ?? []
        
        super.init(frame: NSRect(x: 0, y: 0, width: Constants.Popup.width, height: 0))
        
        self.orientation = .vertical
        self.distribution = .fill
        self.alignment = .width
        self.spacing = Constants.Popup.spacing*3
        
        self.reinit()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reinit), name: .toggleModule, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .toggleOneView, object: nil)
    }
    
    fileprivate func settings() -> NSView? { return nil }
    fileprivate func appear() {}
    fileprivate func disappear() {}
    fileprivate func setKeyboardShortcut(_ binding: [UInt16]) {
        self.keyboardShortcut = binding
        Store.shared.set(key: "CombinedModules_popup_keyboardShortcut", value: binding)
    }
    
    @objc private func reinit() {
        self.subviews.forEach({ $0.removeFromSuperview() })
        
        let availableModules = modules.filter({ $0.enabled && $0.portal != nil })
        var modulesHeight: CGFloat = 0
        availableModules.forEach { (m: Module) in
            if let p = m.portal {
                modulesHeight += p.height
                self.addArrangedSubview(p)
            }
        }
        
        let h = modulesHeight + (CGFloat(availableModules.count-1)*self.spacing)
        if h > 0 {
            self.setFrameSize(NSSize(width: self.frame.width, height: h))
            self.sizeCallback?(self.frame.size)
        }
    }
}
