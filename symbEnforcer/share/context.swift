//
//  context.swift
//  symbEnforcer
//
//  Created by flag on 2023/4/26.
//

import Carbon
import Cocoa
import Foundation

let workspace = NSWorkspace.shared
let formatter = DateFormatter()
var frontAppName = ""
var prevIsFullScreen: Bool? = nil
var nowIsFullScreen: Bool? = nil
