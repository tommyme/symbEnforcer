//
//  Space.swift
//  symbEnforcer
//
//  Created by flag on 2023/4/26.
//

import Foundation
import Cocoa

struct Space {
    var displayID: String
    var spaceID: String
    var spaceName: String
    var spaceNumber: Int
    var desktopNumber: Int?
    var isCurrentSpace: Bool
    var isFullScreen: Bool
}

struct SpaceInfo {
    let isFullScreen: Bool
    let pid: pid_t
    let err: Bool
}

func getSpaceInfo(displays: [NSDictionary]) -> SpaceInfo {
    var activeSpaceID = -1
    var isFullScreen = false
    var pid: pid_t = 0
    
    for d in displays {
        guard let currentSpaces = d["Current Space"] as? [String: Any],
              let spaces = d["Spaces"] as? [[String: Any]]
        else {
            continue
        }
        
        activeSpaceID = currentSpaces["ManagedSpaceID"] as! Int
        
        // err handling
        if activeSpaceID == -1 {
            DispatchQueue.main.async {
                print("Can't find current space")
            }
            return SpaceInfo(isFullScreen: isFullScreen, pid: pid, err: true)
        }

        for s in spaces {
            // 判断是当前的space
            if activeSpaceID == s["ManagedSpaceID"] as! Int {
                isFullScreen = s["TileLayoutManager"] as? [String: Any] != nil
                
                if !isFullScreen {
                    return SpaceInfo(isFullScreen: isFullScreen, pid:pid, err: false)
                } else {
                    pid = s["pid"] as! pid_t
                    return SpaceInfo(isFullScreen: isFullScreen, pid:pid, err: false)
                }
            }
        }
        

    }
    return SpaceInfo(isFullScreen: isFullScreen, pid:pid, err: true)
}
