//
//  main.swift
//  symbEnforcer
//
//  Created by flag on 2023/4/18.
//

import Foundation
import Carbon
import Cocoa


class FileMonitor {
    typealias EventHandler = ([FileEvent]) -> Void

    struct FileEvent {
        let path: String
        let flags: DispatchSource.FileSystemEvent
    }

    private let queue = DispatchQueue(label: "FileMonitorQueue")
    private var sources: [String: DispatchSourceFileSystemObject] = [:]
    private let eventHandler: EventHandler

    init(paths: [String], eventHandler: @escaping EventHandler) {
        self.eventHandler = eventHandler
        for path in paths {
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: open(path, O_EVTONLY),
                eventMask: .all,
                queue: queue
            )
            source.setEventHandler { [weak self] in
                self?.handleEvent(path: path, flags: source.data)
            }
            source.activate()
            sources[path] = source
        }
    }

    deinit {
        for source in sources.values {
            source.cancel()
            close(source.handle)
        }
    }

    private func handleEvent(path: String, flags: DispatchSource.FileSystemEvent) {
        let event = FileEvent(path: path, flags: flags)
        eventHandler([event])
    }

    func start() {
        // no-op
    }

    func stop() {
        // no-op
    }
}


let configFilePath = "/Users/flag/.config/symbEnforcer/config.json"

var targetApplications:[String] = []

// 定义一个函数，用于读取配置文件
func readConfigFile() {
    // 读取配置文件
    if let configData = FileManager.default.contents(atPath: configFilePath) {
        do {
            // 将 JSON 数据解析为字典
            let config = try JSONSerialization.jsonObject(with: configData, options: []) as? [String: Any]
            // 获取 "myValues" 数组中的值
            if let myValues = config?["myValues"] as? [String] {
                targetApplications = myValues
            } else {
                print("Failed to read 'myValues' from config file")
            }
        } catch {
            print("Failed to parse config file: \(error)")
        }
    } else {
        print("Failed to read config file")
    }
}

// 创建一个文件监测器，用于监测配置文件的变化
let fileMonitor = FileMonitor(paths: [configFilePath]) { events in
    // 遍历事件数组，检查是否有配置文件发生了变化
    for event in events {
        if event.path == configFilePath {
            // 如果有配置文件发生了变化，则重新读取配置文件
            readConfigFile()
        }
    }
}

// 启动文件监测器
fileMonitor.start()

// 读取配置文件
readConfigFile()


let workspace = NSWorkspace.shared
let formatter = DateFormatter()
formatter.dateFormat = "HH:mm:ss.SS"

let mapper:[Int: [UniChar]] = [18: [49, 33], 19: [50, 64], 20: [51, 35], 21: [52, 36], 23: [53, 37], 22: [54, 94], 26: [55, 38], 28: [56, 42], 25: [57, 40], 29: [48, 41], 50: [96, 126], 33: [91, 123], 30: [93, 125], 42: [92, 124], 41: [59, 58], 39: [39, 34], 27: [45, 95], 24: [61, 43], 43: [44, 60], 47: [46, 62], 44: [47, 63]]

func currentAppInList() -> Bool {
    let appName = workspace.frontmostApplication?.localizedName
    return targetApplications.contains(appName!)
}

// 创建一个键盘事件监听器
let eventTap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
    callback: { _, _, event, _ in
        // 获取键码
        let cgKeyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let keyCode = Int(cgKeyCode)
        let flags = event.flags
        let source = CGEventSource(stateID: .hidSystemState)
        // 这里12是q的keycode. 这个virtualKey没有什么用,但是keycode要存在,这里我们用一个字母代替.
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 12, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 12, keyDown: false)

        let shiftCase = flags.intersection(.maskShift) == .maskShift
        let plainCase = flags.intersection(.maskNonCoalesced) == .maskNonCoalesced
        let anyOtherModifiers = flags.intersection([.maskControl, .maskCommand, .maskAlternate, .maskSecondaryFn, .maskAlphaShift, .maskHelp])

        // show log
        var actualStringLength = 0
        var unicodeString:[UniChar] = [0, 0]
        event.keyboardGetUnicodeString(maxStringLength: 2, actualStringLength: &actualStringLength, unicodeString: &unicodeString)
        let timestamp = formatter.string(from: Date())
        print("\(timestamp)", "keycode", keyCode, "unicode", unicodeString, "shift", shiftCase, "plain", plainCase)
        
        // 把鸡肋的截图键 用来进行调试 截图键其实是组合键
        if flags == [.maskCommand, .maskShift, .maskNonCoalesced, CGEventFlags(rawValue: 0xA)] {
            print("Debug keyCode [ScreenShot]",keyCode)
            print("\t", targetApplications)                         // target applications
            // applications name in Application Switcher
            for app in NSWorkspace.shared.runningApplications {
                if app.activationPolicy == .regular {
                    print("\t", app.localizedName)
                }
            }
            return nil
        }
        if !currentAppInList() {
            return Unmanaged.passRetained(event)
        }

        if mapper[keyCode] != nil {
            var elementPointer: UnsafePointer<UniChar>? = nil

            // 不要影响其他修饰键
            if anyOtherModifiers.rawValue != 0 {
                print("other modifier")
                return Unmanaged.passRetained(event)
            }
            
            if shiftCase {
                // 拿到目标字符指针
                print("shift case")
                elementPointer = mapper[keyCode]!.withUnsafeBufferPointer { $0.baseAddress!.advanced(by: 1) }
            } else if plainCase {
                if (keyCode >= 18 && keyCode <= 29) { // 数字如果处理的话会影响输入法
                    return Unmanaged.passRetained(event)
                }
                print("plain case")
                elementPointer = mapper[keyCode]!.withUnsafeBufferPointer { $0.baseAddress!.advanced(by: 0) }
            }
            // 发送目标字符
            print(Character(UnicodeScalar(elementPointer?.pointee ?? 0)!))
            keyDown?.keyboardSetUnicodeString(stringLength: 1, unicodeString: elementPointer)
            keyDown?.post(tap: .cghidEventTap)
            keyUp?.keyboardSetUnicodeString(stringLength: 1, unicodeString: elementPointer)
            keyUp?.post(tap: .cghidEventTap)
            return nil
        } else {
            return Unmanaged.passRetained(event)
        }

    },
    userInfo: nil
)

// 将事件监听器添加到主运行循环中
if let eventTap = eventTap {
    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)
    CFRunLoopRun()
}



