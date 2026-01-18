//
//  main.swift
//  MiddleScroller
//

import Cocoa

print("DEBUG: main.swift starting")

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

print("DEBUG: Starting NSApplication.run()")
app.run()
