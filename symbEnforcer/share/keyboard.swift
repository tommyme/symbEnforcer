//
//  keyboard.swift
//  symbEnforcer
//
//  Created by flag on 2023/4/26.
//
import Carbon
import Cocoa
import Foundation

class FlagSet {
    static let screenShotCombine: CGEventFlags = [
        .maskCommand,
        .maskShift,
        .maskNonCoalesced,
        CGEventFlags(rawValue: 0xA)
    ]
    static let OptionSPCharCombine: CGEventFlags = [
        .maskAlternate,
        .maskNonCoalesced,
        CGEventFlags(rawValue: 0x20)
    ]
    static let OptionSPCharCombineStrip: CGEventFlags = [
        .maskAlternate
    ]
    static let OptionSPCharShiftCombine: CGEventFlags = [
        .maskAlternate,
        .maskNonCoalesced,
        .maskShift,
        CGEventFlags(rawValue: 0x22)
    ]
    static let OptionSPCharShiftCombineStrip: CGEventFlags = [
        .maskAlternate,
        .maskNonCoalesced,
        .maskShift,
    ]
    static let CommandSpace: CGEventFlags = [.maskCommand, .maskNonCoalesced, CGEventFlags(rawValue: 0x8)]
    static let OptionSpace: CGEventFlags = [.maskAlternate, .maskNonCoalesced, CGEventFlags(rawValue: 0x20)]
    static let CtrlSpace: CGEventFlags = [.maskControl, .maskNonCoalesced, CGEventFlags(rawValue: 0x1)]
}

// 用来放空的unicode 打不出字
let null2ascii:[UniChar] = [0, 0]
// 18 vk, 49 '1', 33 '!'
let vk2ascii:[Int: [UniChar]] = [
    // 18-24 -- `1234567890-=
    50: [96, 126],
    18: [49, 33],
    19: [50, 64],
    20: [51, 35],
    21: [52, 36],
    23: [53, 37],
    22: [54, 94],
    26: [55, 38],
    28: [56, 42],
    25: [57, 40],
    29: [48, 41],
    27: [45, 95],
    24: [61, 43],
    // []\
    33: [91, 123],
    30: [93, 125],
    42: [92, 124],
    // ;',./
    41: [59, 58],
    39: [39, 34],
    43: [44, 60],
    47: [46, 62],
    44: [47, 63],
]

let vk2asciiFull:[Int: [UniChar]] = [
    // 18-24 -- `1234567890-=
    50: [96, 126],
    18: [49, 33],
    19: [50, 64],
    20: [51, 35],
    21: [52, 36],
    23: [53, 37],
    22: [54, 94],
    26: [55, 38],
    28: [56, 42],
    25: [57, 40],
    29: [48, 41],
    27: [45, 95],
    24: [61, 43],
    // []\
    33: [91, 123],
    30: [93, 125],
    42: [92, 124],
    // ;',./
    41: [59, 58],
    39: [39, 34],
    43: [44, 60],
    47: [46, 62],
    44: [47, 63],
    // 正常的字符 qwertyuiopasfghjklzxcvbnm
    12: [81, 113],
    13: [87, 119],
    14: [69, 101],
    15: [82, 114],
    17: [84, 116],
    16: [89, 121],
    32: [85, 117],
    34: [73, 105],
    31: [79, 111],
    35: [80, 112],
    0: [65, 97],
    1: [83, 115],
    2: [68, 100],
    3: [70, 102],
    5: [71, 103],
    4: [72, 104],
    38: [74, 106],
    40: [75, 107],
    37: [76, 108],
    6: [90, 122],
    7: [88, 120],
    8: [67, 99],
    9: [86, 118],
    11: [66, 98],
    45: [78, 110],
    46: [77, 109]
]


let conn = _CGSDefaultConnection()

func getPointer(array: [UniChar], offset: Int) -> UnsafePointer<UniChar> {
    return array.withUnsafeBufferPointer { $0.baseAddress!.advanced(by: offset) }
}

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
    
    // 交集 取反 再交  能够捕捉到 特殊的 以raw值为代表的 cgeventFlag
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

struct KeyUnicode {
    var actualStringLength: Int
    var unicodeString: [UniChar]
}

//var currentKeyUnicode = KeyUnicode(actualStringLength: 1, unicodeString: [UniChar](repeating: 0, count: 4))

class EventInfo {
    let event: CGEvent
    let keyCode: Int        // Int 类型兼容性较好
    let flags: CGEventFlags
    let shiftCase: Bool
    let plainCase: Bool
    let anyOtherModifiers: CGEventFlags
    let frontAppName: String
    let nowIsFullScreen: Bool
    let send: Bool          // 保留字段
    var keyUnicode: UniChar = 0 // 存放当前event的unicode

    init(event: CGEvent) {
        self.event = event
        self.keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        self.flags = event.flags
        self.shiftCase = self.flags.intersection(.maskShift) == .maskShift
        self.plainCase = self.flags.intersection(.maskNonCoalesced) == .maskNonCoalesced
        self.anyOtherModifiers = self.flags.intersection([.maskControl, .maskCommand, .maskAlternate, .maskSecondaryFn, .maskAlphaShift, .maskHelp])
        self.frontAppName = (workspace.frontmostApplication?.localizedName!)!
        self.nowIsFullScreen = checkFullScreen()     // better performance
        self.send = false
        self.keyUnicode = getUnicode()
    }
    func getUnicode() -> UniChar {
        let maxStringLength = 4
        var actualStringLength = 0
        var unicodeString = [UniChar](repeating: 0, count: Int(maxStringLength))
        self.event.keyboardGetUnicodeString(maxStringLength: 1, actualStringLength: &actualStringLength, unicodeString: &unicodeString)
        return unicodeString[0]
    }
    func log() {
        // show log
        let timestamp = formatter.string(from: Date())
        
        // logging
        print("\(timestamp)", "keycode", keyCode)
        print("\tunicode: \(self.keyUnicode)", "shift: \(shiftCase)", "plain: \(plainCase)\n",
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
    
    func doSpChIgnore() -> Bool {
        // 忽略option+字母键 带来的特殊字符
        return true
    }
    
    func flow(
        _to: CGEventTapLocation = .cgSessionEventTap,
        vk: CGKeyCode? = nil, // vk of 'q'
        _from: CGEventSource? = nil,
        flags: CGEventFlags? = nil,
        unicode: UnsafePointer<UniChar>? = nil
    ) {
        // 定义一个函数，用于获取默认值
        func defaultValue<T>(for parameter: T?, fallback: () -> T) -> T {
            return parameter ?? fallback()
        }
        
        // 使用新的默认参数语法来获取默认值
        let vk_inuse = defaultValue(for: vk, fallback: { CGKeyCode(self.keyCode) })
        let flags_inuse = defaultValue(for: flags, fallback: { self.flags })
        
        
        let keyDownEvent = CGEvent(keyboardEventSource: _from, virtualKey: vk_inuse, keyDown: true)!
        let keyUpEvent = CGEvent(keyboardEventSource: _from, virtualKey: vk_inuse, keyDown: false)!
        // 保持flags
        (keyDownEvent.flags, keyUpEvent.flags) = (flags_inuse, flags_inuse)
        // 更改unicode
        if unicode != nil {
            keyDownEvent.keyboardSetUnicodeString(stringLength: 1, unicodeString: unicode)
            keyUpEvent.keyboardSetUnicodeString(stringLength: 1, unicodeString: unicode)
        }
        // 发送event
        keyDownEvent.post(tap: _to)
        keyUpEvent.post(tap: _to)
    }
    
    func pass() -> Unmanaged<CGEvent> {
        return Unmanaged.passRetained(event)
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
            if info.flags == FlagSet.screenShotCombine && info.keyCode == 21 {
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

        // banner layer  把快捷键直接发送给应用程序
        if info.doBanner() {
            // 禁止触发全局 command space
            // 禁止触发全局 option space
            // 禁止触发切换输入法
            if (info.keyCode == CGKeyCode(kVK_Space) &&
                // 对三种情况一起进行处理
                [FlagSet.CommandSpace, FlagSet.CtrlSpace, FlagSet.OptionSpace].contains(info.flags)
            ) {
                info.flow(_to: .cgAnnotatedSessionEventTap, vk: CGKeyCode(kVK_Space))
                return nil
            }
        }
        
        // symb enforcer layer
        if info.doSymbEnforcer() {
            // 符号覆盖逻辑
            var target: [UniChar]? = vk2ascii[info.keyCode]

            if target != nil {
                var elementPointer: UnsafePointer<UniChar>? = nil

                if ((info.anyOtherModifiers.rawValue != 0) ||                       // 不要影响其他修饰键
                    (info.plainCase && info.keyCode >= 18 && info.keyCode <= 29)    // 如果 没有 shift 并且是 数字
                ) { return info.pass() }
                                
                let offset: Int = info.shiftCase ? 1 : 0
                elementPointer = getPointer(array: target!, offset: offset)
                
                // 发送目标字符  这里12是q的keycode. 这个virtualKey没有什么用,但是keycode要存在,这里我们用一个字母代替.
                // 不指定vk为12的话 会进入无限循环
                // 进入无限循环是因为 如果保持原有vk 还是会进入symbEnforcer逻辑
                
//                if info.keyUnicode == target![offset] { // 已经处理过了
//                    return nil
//                }
                info.flow(_to: .cghidEventTap, vk: 12, unicode: elementPointer)
                return nil
            }
        }

        if info.doSpChIgnore() {
            if (info.flags == FlagSet.OptionSPCharCombine) || (info.flags == FlagSet.OptionSPCharShiftCombine) {
                if vk2asciiFull[info.keyCode] != nil {
                    if info.flags == FlagSet.OptionSPCharCombine{
                        // 使用null2ascii 让键盘输出不了特殊字符
                        info.flow(flags: FlagSet.OptionSPCharCombineStrip, unicode: getPointer(array: null2ascii, offset: 0))
                    }
                    else {
                        // 目前没有对option shift xxx进行hook, 下面的代码基本无效
                        info.flow(flags: FlagSet.OptionSPCharShiftCombineStrip)
                    }
                    return nil
                }
            }
        }
        return info.pass()
    },
    userInfo: nil
)
