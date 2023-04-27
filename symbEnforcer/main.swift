//
//  main.swift
//  symbEnforcer
//
//  Created by flag on 2023/4/18.
//

import Foundation
import Carbon
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var globalHotkey: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        formatter.dateFormat = "HH:mm:ss.SS"

        // 启动文件监测器
        fileMonitor.start()

        // 读取配置文件
        readConfigFile()

//        // 注册全局快捷键
//        let hotkey = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
//            if event.keyCode == 49 && event.modifierFlags.contains(.command){
//                print("Command-space pressed")
//            }
//        }
//
//        globalHotkey = hotkey
        
        // 将事件监听器添加到主运行循环中
        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
            CFRunLoopRun() // loop forever
        }

    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("over")
        // 注销全局快捷键
//        if let hotkey = globalHotkey {
//            NSEvent.removeMonitor(hotkey)
//            globalHotkey = nil
//        }
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.run()
