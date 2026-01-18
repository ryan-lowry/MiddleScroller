//
//  Logger.swift
//  MiddleScroller
//

import Foundation

enum Logger {
    static var isDebugEnabled: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["MIDDLESCROLLER_DEBUG"] != nil
        #else
        return false
        #endif
    }()

    static func debug(_ message: String) {
        if isDebugEnabled {
            print("[DEBUG] \(message)")
        }
    }
}
