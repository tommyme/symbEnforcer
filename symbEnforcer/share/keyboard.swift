//
//  keyboard.swift
//  symbEnforcer
//
//  Created by flag on 2023/4/26.
//
import Carbon
import Cocoa
import Foundation

let screenShotCombine: CGEventFlags = [.maskCommand, .maskShift, .maskNonCoalesced, CGEventFlags(rawValue: 0xA)]

let vk2ascii:[Int: [UniChar]] = [
    18: [49, 33], 19: [50, 64], 20: [51, 35], 21: [52, 36], 23: [53, 37], 22: [54, 94], 26: [55, 38], 28: [56, 42], 25: [57, 40], 29: [48, 41], 50: [96, 126], 33: [91, 123], 30: [93, 125], 42: [92, 124], 41: [59, 58], 39: [39, 34], 27: [45, 95], 24: [61, 43], 43: [44, 60], 47: [46, 62], 44: [47, 63]
]

let conn = _CGSDefaultConnection()


func checkFlags(flags: CGEventFlags) -> String {
    var modifiers = [String]()

    if flags.contains(.maskShift) == true {
        modifiers.append("Shift")
    }
    if flags.contains(.maskControl) == true {
        modifiers.append("Control")
    }
    if flags.contains(.maskAlternate) == true {
        modifiers.append("Option")
    }
    if flags.contains(.maskCommand) == true {
        modifiers.append("Command")
    }
    if flags.contains(.maskAlphaShift) == true {
        modifiers.append("Caps Lock")
    }
    if flags.contains(.maskHelp) == true {
        modifiers.append("Help")
    }
    if flags.contains(.maskSecondaryFn) == true {
        modifiers.append("Fn")
    }
    if flags.contains(.maskNumericPad) == true {
        modifiers.append("Numeric Pad")
    }
    if flags.contains(.maskNonCoalesced) == true {
        modifiers.append("Non-Coalesced")
    }
    // 在我使用的keychron k3 pro中:
    // 只要按下方向键就会包含 maskNumericPad maskSecondaryFn
    // 任何按键都会包含 maskNonCoalesced
    
    let allFlags: CGEventFlags = [.maskNonCoalesced, .maskNumericPad, .maskSecondaryFn, .maskHelp, .maskAlphaShift, .maskCommand, .maskAlternate, .maskControl, .maskShift ]
    
    // 交集 取反 再交  遇到类似于 截图键的情况的时候就能够捕捉到特殊cgeventFlag
    let res = CGEventFlags(rawValue: ~flags.intersection(allFlags).rawValue).intersection(flags)
    
    if res.rawValue > 0 {
        modifiers.append("0x"+String(res.rawValue, radix: 16))
    }

    let modifiersString = modifiers.joined(separator: ", ")
    return "已按下的标志：\(modifiersString)"
}


func getFrontMostAppName() -> String {
    return frontAppName
}
func checkFullScreen() -> Bool {
//    NSScreen.main
    let displays = CGSCopyManagedDisplaySpaces(conn) as! [NSDictionary]
    let spInfo: SpaceInfo = getSpaceInfo(displays: displays)
    return spInfo.isFullScreen
}

func getFrontmostProcessID() -> pid_t? {
    if let frontmostAppPID = NSWorkspace.shared.frontmostApplication?.processIdentifier {
        return frontmostAppPID
    }
    return nil
}

func customEventFlow(_to: CGEventTapLocation, vk: CGKeyCode, _from: CGEventSource? = nil, flags: CGEventFlags = CGEventFlags()) {
    let keyDownEvent = CGEvent(keyboardEventSource: _from, virtualKey: vk, keyDown: true)!
    let keyUpEvent = CGEvent(keyboardEventSource: _from, virtualKey: vk, keyDown: false)!
    (keyDownEvent.flags, keyUpEvent.flags) = (flags, flags)
    keyDownEvent.post(tap: _to)
    keyUpEvent.post(tap: _to)
}

class EventInfo {
    let event: CGEvent
    let keyCode: Int        // Int 类型兼容性较好
    let flags: CGEventFlags
    let shiftCase: Bool
    let plainCase: Bool
    let anyOtherModifiers: CGEventFlags
    let frontAppName: String
    let nowIsFullScreen: Bool

    init(event: CGEvent) {
        self.event = event
        self.keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        self.flags = event.flags
        self.shiftCase = self.flags.intersection(.maskShift) == .maskShift
        self.plainCase = self.flags.intersection(.maskNonCoalesced) == .maskNonCoalesced
        self.anyOtherModifiers = self.flags.intersection([.maskControl, .maskCommand, .maskAlternate, .maskSecondaryFn, .maskAlphaShift, .maskHelp])
        self.frontAppName = (workspace.frontmostApplication?.localizedName!)!
        self.nowIsFullScreen = checkFullScreen()     // better performance
    }
    
    func log() {
        // show log
        var actualStringLength = 0
        var unicodeString:[UniChar] = [0, 0]
        event.keyboardGetUnicodeString(maxStringLength: 2, actualStringLength: &actualStringLength, unicodeString: &unicodeString)
        let timestamp = formatter.string(from: Date())
        
        // logging
        print("\(timestamp)", "keycode", keyCode)
        print("\tunicode: \(unicodeString)", "shift: \(shiftCase)", "plain: \(plainCase)\n",
              "\tfront-appname: <\(frontAppName)>\n",
              "\tfull-screen: \(prevIsFullScreen)\n",
              "\t\(checkFlags(flags: flags))")
    }

    func doSymbEnforcer() -> Bool {
        return targetApplications.contains(frontAppName)
    }

    func doBanner() -> Bool {
        let apps: [String] = ["Microsoft Remote Desktop Beta"]
        return apps.contains(frontAppName) && nowIsFullScreen
    }
        
    func doFunctional() -> Bool {
        return true
    }

    func doHook() -> Bool {
        return true
    }
}

// 创建一个键盘事件监听器
let eventTap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
    callback: { _, _, event, _ in

        let info = EventInfo(event: event)

        info.log()
        
        if info.doHook() {
            if info.nowIsFullScreen != prevIsFullScreen {
                // update value
                prevIsFullScreen = info.nowIsFullScreen
                // karabiner write variable
                let task = Process()
                task.launchPath = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
                let b: String = "{\"fullscreen\": \(prevIsFullScreen!)}"
                task.arguments = ["--set-variables", b]
                task.launch()
            }
        }

        // functional layer  截图键 和command shift z冲突
        if info.doFunctional() {
            // 把鸡肋的截图键 用来进行调试 显示当前app switcher里面的程序 截图键其实是组合键
            if info.flags == screenShotCombine {
                print("Debug keyCode [ScreenShot]", info.keyCode)
                print("\t", targetApplications)                         // target applications
                // applications name in Application Switcher
                for app in NSWorkspace.shared.runningApplications {
                    if app.activationPolicy == .regular {
                        print("\t", app.localizedName!)
                    }
                }
                return nil
            }
            
        }

        // banner layer
        if info.doBanner() {
            // 禁止触发全局 command space
            if (info.keyCode == CGKeyCode(kVK_Space) && info.flags == [.maskCommand, .maskNonCoalesced, CGEventFlags(rawValue: 0x8)]) {
                customEventFlow(_to: .cgAnnotatedSessionEventTap, vk: CGKeyCode(kVK_Space), flags: [.maskCommand, .maskNonCoalesced, CGEventFlags(rawValue: 0x8)])
                return nil
            }
            // 禁止触发全局 option space
            if (info.keyCode == CGKeyCode(kVK_Space) && info.flags == [.maskAlternate, .maskNonCoalesced, CGEventFlags(rawValue: 0x20)]) {
                customEventFlow(_to: .cgAnnotatedSessionEventTap, vk: CGKeyCode(kVK_Space), flags: [.maskAlternate, .maskNonCoalesced, CGEventFlags(rawValue: 0x20)])
                return nil
            }
            // 禁止触发切换输入法
            if (info.keyCode == CGKeyCode(kVK_Space) && info.flags == [.maskControl, .maskNonCoalesced, CGEventFlags(rawValue: 0x1)]) {
                customEventFlow(_to: .cgAnnotatedSessionEventTap, vk: CGKeyCode(kVK_Space), flags: [.maskControl, .maskNonCoalesced, CGEventFlags(rawValue: 0x1)])
                return nil
            }
        }
        
        // symb enforcer layer
        if info.doSymbEnforcer() {
            // 符号覆盖逻辑
            if vk2ascii[info.keyCode] != nil {
                var elementPointer: UnsafePointer<UniChar>? = nil

                // 不要影响其他修饰键
                if info.anyOtherModifiers.rawValue != 0 {
                    return Unmanaged.passRetained(event)
                }
                
                if info.shiftCase {
                    // 拿到目标字符指针
                    elementPointer = vk2ascii[info.keyCode]!.withUnsafeBufferPointer { $0.baseAddress!.advanced(by: 1) }
                } else if info.plainCase {
                    if (info.keyCode >= 18 && info.keyCode <= 29) { // 数字如果处理的话会影响输入法
                        return Unmanaged.passRetained(event)
                    }
                    elementPointer = vk2ascii[info.keyCode]!.withUnsafeBufferPointer { $0.baseAddress!.advanced(by: 0) }
                }
                // 发送目标字符
                // 这里12是q的keycode. 这个virtualKey没有什么用,但是keycode要存在,这里我们用一个字母代替.
                //        let source = CGEventSource(stateID: .hidSystemState) // source 可以省略
                let keyDown = CGEvent(keyboardEventSource: nil ,virtualKey: 12, keyDown: true)
                let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 12, keyDown: false)
//                print(Character(UnicodeScalar(elementPointer?.pointee ?? 0)!))
                keyDown?.keyboardSetUnicodeString(stringLength: 1, unicodeString: elementPointer)
                keyUp?.keyboardSetUnicodeString(stringLength: 1, unicodeString: elementPointer)
                keyDown?.post(tap: .cghidEventTap)
                keyUp?.post(tap: .cghidEventTap)
                return nil
            } else {
                return Unmanaged.passRetained(event)
            }
        }

        return Unmanaged.passRetained(event)
    },
    userInfo: nil
)
