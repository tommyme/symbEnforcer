//
//  tool.swift
//  symbEnforcer
//
//  Created by flag on 2023/4/26.
//

import Foundation

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

let configFilePath = "\(NSHomeDirectory())/.config/symbEnforcer/config.json"
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
