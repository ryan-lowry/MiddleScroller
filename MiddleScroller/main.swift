//
//  main.swift
//  MiddleScroller
//

import Cocoa

Logger.debug("main.swift starting")

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

Logger.debug("Starting NSApplication.run()")
app.run()
