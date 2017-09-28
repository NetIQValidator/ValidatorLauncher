//
//  AppDelegate.swift
//  ValidatorLauncher for Mac
//
//  Created by Lothar Haeger on 03.09.15.
//  Copyright (c) 2015 Lothar Haeger. All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import CoreServices
import Cocoa
import Foundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // Preferences
    @IBOutlet weak var window: NSWindow!
    // Service tab
    @IBOutlet weak var BasePath: NSTextField!
    @IBOutlet weak var BasePathSelector: NSButton!
    @IBOutlet weak var optionUseCustomLicenseFile: NSButton!
    @IBOutlet weak var CustomLicenseFile: NSTextField!
    @IBOutlet weak var CustomLicenseFileSelector: NSButton!
    @IBOutlet weak var optionStartServiceOnLaunch: NSButton!
    @IBOutlet weak var optionStartServiceInDebugMode: NSButton!
    @IBOutlet weak var optionShowServiceConsole: NSButton!
    // Client tab
    @IBOutlet weak var optionOpenValidatorClient: NSButton!
    @IBOutlet weak var optionOpenRunnerClient: NSButton!
    @IBOutlet weak var optionOpenSchedulerClient: NSButton!
    @IBOutlet weak var optionClientBrowser: NSPopUpButtonCell!
    // About tab
    @IBOutlet weak var aboutText: NSTextField!
    @IBOutlet weak var homePage: NSButton!
    
    let appAbout =  "Launcher for Validator\n\n" +
                    "Version 0.9.3, 2017-08-22\n\n" +
                    "© 2015-17 Lothar Haeger (lothar.haeger@is4it.de)\n\n"
    let homePageUrl = "http://www.is4it.de/en/solution/identity-access-management/"

    let supportedBrowsers = [(name: "Safari",  id: "com.apple.Safari"),
                             (name: "Firefox", id: "org.mozilla.firefox"),
                             (name: "Chrome",  id: "com.google.Chrome")]


    let prefs = UserDefaults.standard

    var statusBar = NSStatusBar.system
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var menuItemService : NSMenuItem = NSMenuItem()
    var menuItemConsole : NSMenuItem = NSMenuItem()
    var menuItemValidator : NSMenuItem = NSMenuItem()
    var menuItemRunner : NSMenuItem = NSMenuItem()
    var menuItemScheduler : NSMenuItem = NSMenuItem()
    var menuItemPrefs : NSMenuItem = NSMenuItem()
    var menuItemQuit : NSMenuItem = NSMenuItem()
    var validatorUrl : URL!
    var validatorService: Process = Process()
    
    override func awakeFromNib() {

        // Build status bar menu
        let icon = NSImage(named: NSImage.Name(rawValue: "MenuIcon"))
        icon!.isTemplate = true
        menu.autoenablesItems = false
        
        statusBarItem = statusBar.statusItem(withLength: -1)
        statusBarItem.menu = menu
        statusBarItem.image = icon
        statusBarItem.title = ""
        
        //"Start/Stop Service" menuItem
        menuItemService.title = "Start Service"
        menu.addItem(menuItemService)
        
        //"Show/Hide Service Console" menuItem (hidden until implemented)
        menuItemConsole.title = "Show Console"
        menuItemConsole.action = #selector(AppDelegate.showConsole(_:))
        menuItemConsole.isHidden = true
        menu.addItem(menuItemConsole)
        
        // Separator
        menu.addItem(NSMenuItem.separator())
        
        //"Open Validator" menuItem
        menuItemValidator.title = "Open Validator"
        menuItemValidator.action = #selector(AppDelegate.openValidator(_:))
        menu.addItem(menuItemValidator)

        
        //"Open Runner" menuItem
        menuItemRunner.title = "Open Runner"
        menuItemRunner.action = #selector(AppDelegate.openRunner(_:))
        menu.addItem(menuItemRunner)
        menuItemRunner.isEnabled = false
        
        //"Open Scheduler" menuItem
        menuItemScheduler.title = "Open Scheduler"
        menuItemScheduler.action = #selector(AppDelegate.openScheduler(_:))
        menu.addItem(menuItemScheduler)
        
        // Separator
        menu.addItem(NSMenuItem.separator())
        
        //"Preferences" menuItem
        menuItemPrefs.title = "Preferences"
        menuItemPrefs.action = #selector(AppDelegate.Preferences(_:))
        menu.addItem(menuItemPrefs)
        
        // Separator
        menu.addItem(NSMenuItem.separator())
        
        // "Quit" menuItem
        menuItemQuit.title = "Quit"
        menuItemQuit.action = #selector(AppDelegate.quitApplication(_:))
        menu.addItem(menuItemQuit)

        // Update dynamic settings depending on Validator service status
        menuItemServiceUpdate()
    }
    
    @IBAction func optionUseCustomLicenseFile(_ sender: NSButton) {
        self.prefs.set(optionUseCustomLicenseFile.state, forKey: "optionUseCustomLicenseFile")
        if optionUseCustomLicenseFile.selected {
            CustomLicenseFile.isEnabled = true
            CustomLicenseFileSelector.isEnabled = true
            if let customLicenseFilePath = prefs.string(forKey: "customLicenseFilePath") {
                CustomLicenseFile.stringValue = customLicenseFilePath
            } else {
                CustomLicenseFile.stringValue = ""
            }
        } else {
            CustomLicenseFile.isEnabled = false
            CustomLicenseFileSelector.isEnabled = false
            CustomLicenseFile.stringValue = "config/license.dat"
        }
    }
    
    @IBAction func buttonStartServiceOnLaunch(_ sender: NSButton) {
        self.prefs.set(optionStartServiceOnLaunch.state, forKey: "optionStartServiceOnLaunch")
    }
    
    @IBAction func buttonStartServiceInDebugMode(_ sender: NSButton) {
        self.prefs.set(optionStartServiceInDebugMode.state, forKey: "optionStartServiceInDebugMode")
    }
    
    @IBAction func buttonShowServiceConsole(_ sender: NSButton) {
        self.prefs.set(optionShowServiceConsole.state, forKey: "optionShowServiceConsole")
    }
    
    @IBAction func buttonOpenValidatorClient(_ sender: NSButton) {
        self.prefs.set(optionOpenValidatorClient.state, forKey: "optionOpenValidatorClient")
    }
    
    @IBAction func buttonOpenRunnerClient(_ sender: NSButton) {
        self.prefs.set(optionOpenRunnerClient.state, forKey: "optionOpenRunnerClient")
    }
    
    @IBAction func buttonOpenSchedulerClient(_ sender: NSButton) {
        self.prefs.set(optionOpenSchedulerClient.state, forKey: "optionOpenSchedulerClient")
    }
    
    @IBAction func popupClientBrowser(_ sender: NSPopUpButtonCell) {
        self.prefs.setValue(optionClientBrowser.titleOfSelectedItem, forKey: "optionClientBrowser")
    }

    @IBAction func homePagePressed(_ sender: NSButton) {
        let url = URL(string: homePageUrl)
        openBrowser(url!)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.floatingWindow)))

        // hide checkbox until option is implemented
        optionShowServiceConsole.isHidden = true

        // initialize browser list
        optionClientBrowser.removeAllItems()
        for browser in supportedBrowsers {
            optionClientBrowser.addItem(withTitle: browser.name)
            optionClientBrowser.item(withTitle: browser.name)!.isEnabled = false
        }
        if let installedBrowsers = LSCopyAllHandlersForURLScheme("https" as CFString)?.takeUnretainedValue() {
            for installedBrowser in installedBrowsers {
                for browser in supportedBrowsers {
                    if browser.id == String(describing: installedBrowser){
                        optionClientBrowser.item(withTitle: browser.name)?.isEnabled = true
                    }
                }
            }
        }

        // update about tab contents
        aboutText.stringValue = appAbout
        // homepage link
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = NSTextAlignment.center
        homePage.attributedTitle = NSAttributedString(
                                        string: homePageUrl,
                                        attributes: [ NSAttributedStringKey.font: NSFont.systemFont(ofSize: 13.0),
                                                      NSAttributedStringKey.foregroundColor: NSColor.blue,
                                                      NSAttributedStringKey.underlineStyle: 1,
                                                      NSAttributedStringKey.paragraphStyle: pstyle])

        if readPreferences() {
            window!.orderOut(self)
            readPropertiesFile()
            if optionStartServiceOnLaunch.selected {
                startService(self)
                sleep(3)
            }
            if validatorService.isRunning {
                if optionShowServiceConsole.selected {
                    showConsole(self)
                }
                if optionOpenValidatorClient.selected {
                    openValidator(self)
                }
                if optionOpenRunnerClient.selected && isRunnerAvailable() {
                    openRunner(self)
                }
                if optionOpenSchedulerClient.selected {
                    openScheduler(self)
                }
            }
        } else {
            window!.orderFront(self)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        stopService(self)
    }
 
    @IBAction func BasePathSelector(_ sender: NSButton) {
        setValidatorBasePath()
    }

    @IBAction func BasePath(_ sender: NSTextField) {
    }
    
    @IBAction func CustomLicenseFileSelector(_ sender: NSButton) {
        setCustomLicenseFilePath()
    }
    
    func setCustomLicenseFilePath() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["lic", "dat"]
        openPanel.allowsOtherFileTypes = true
        while true {
            let result = openPanel.runModal()
            if result.rawValue == NSFileHandlingPanelOKButton {
                    CustomLicenseFile.stringValue = openPanel.url!.path
                    self.prefs.set(openPanel.url!, forKey: "customLicenseFilePath")
                    break
            } else {
                break
            }
        }
    }

    func setValidatorBasePath() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        while true {
            let result = openPanel.runModal()
            if result.rawValue == NSFileHandlingPanelOKButton {
                if isValidatorInstallPath(openPanel.url!.path) {
                    BasePath.stringValue = openPanel.url!.path
                    self.prefs.set(openPanel.url!, forKey: "validatorBasePath")
                    readPropertiesFile()
                    optionOpenRunnerClient.isEnabled = isRunnerAvailable()
                    optionOpenRunnerClient.isHidden = !isRunnerAvailable()
                    menuItemRunner.isEnabled = validatorService.isRunning && isRunnerAvailable()
                    menuItemRunner.isHidden = !isRunnerAvailable()
                    break
                }
            } else {
                break
            }
        }
    }

    func isRunnerAvailable() -> Bool {
        // runner has been removed in v1.5.0 and later
        let runnerWebPath = prefs.string(forKey: "validatorBasePath")! + "/web/runner/runner.html"
        return FileManager().fileExists(atPath: runnerWebPath)
    }

    func messageBox(_ message: String, description: String?=nil) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.alertStyle = NSAlert.Style.critical
        myPopup.addButton(withTitle: "OK")
        myPopup.messageText = message
        if let informativeText = description {
            myPopup.informativeText = informativeText
        }
        return (myPopup.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn)
    }
    
    func readPreferences() -> Bool {
        
        if let validatorBasePath = prefs.string(forKey: "validatorBasePath") {
            
            // Service tab
            BasePath.stringValue = validatorBasePath
            optionUseCustomLicenseFile.state = NSControl.StateValue(rawValue: prefs.integer(forKey: "optionUseCustomLicenseFile"))
            CustomLicenseFile.isEnabled = optionUseCustomLicenseFile.state.rawValue == 1
            CustomLicenseFileSelector.isEnabled = CustomLicenseFile.isEnabled
            if CustomLicenseFile.isEnabled {
                CustomLicenseFile.stringValue = prefs.url(forKey: "customLicenseFilePath")!.path
            } else {
                CustomLicenseFile.stringValue = "config/license.dat"
            }
            optionStartServiceOnLaunch.state = NSControl.StateValue(rawValue: prefs.integer(forKey: "optionStartServiceOnLaunch"))
            optionStartServiceInDebugMode.state = NSControl.StateValue(rawValue: prefs.integer(forKey: "optionStartServiceInDebugMode"))
            optionShowServiceConsole.state = NSControl.StateValue(rawValue: prefs.integer(forKey: "optionShowServiceConsole"))

            // Clients tab
            optionOpenValidatorClient.state = NSControl.StateValue(rawValue: prefs.integer(forKey: "optionOpenValidatorClient"))
            optionOpenRunnerClient.state = NSControl.StateValue(rawValue: prefs.integer(forKey: "optionOpenRunnerClient"))
            optionOpenRunnerClient.isEnabled = isRunnerAvailable()
            optionOpenRunnerClient.isHidden = !isRunnerAvailable()
            menuItemRunner.isEnabled = (validatorService.isRunning && isRunnerAvailable())
            menuItemRunner.isHidden = !isRunnerAvailable()
            optionOpenSchedulerClient.state = NSControl.StateValue(rawValue: prefs.integer(forKey: "optionOpenSchedulerClient"))
            optionClientBrowser.selectItem(withTitle: String(describing: prefs.value(forKey: "optionClientBrowser")!))

            if isValidatorInstallPath(validatorBasePath) {
                return true
            }
        } else {
            messageBox("Please select your NetIQ Validator program folder.",
                description: "Validator Launcher could not find your NetIQ Validator program folder.")
        }
        return false
    }
    
    func isValidatorInstallPath(_ validatorBasePath: String) -> Bool {
        let validatorCmdPath = validatorBasePath + "/runValidator.command"
        if FileManager().fileExists(atPath: validatorCmdPath) {
            let validatorPropsPath = validatorBasePath + "/config/validator.properties"
            if FileManager().fileExists(atPath: validatorPropsPath) {

                return true
            } else {
                messageBox("Please select a valid NetIQ Validator program folder.",
                    description: "The config/validator.properties file could not be found in \(validatorBasePath).")
            }
        } else {
            messageBox("Please select your NetIQ Validator program folder.",
                description: "The runValidator.command script could not be found in \(validatorBasePath).")
        }
        return false
    }

    @objc func Preferences(_ sender: AnyObject){
        readPreferences()
        self.window.makeKeyAndOrderFront(self)
    }
    
    func readPropertiesFile() {
        if let validatorBasePath = prefs.string(forKey: "validatorBasePath")
        {
            let validatorPropsPath = validatorBasePath + "/config/validator.properties"
            if FileManager().fileExists(atPath: validatorPropsPath) {
                let propertiesArray = (try! String(contentsOfFile: validatorPropsPath, encoding: String.Encoding.utf8)).components(separatedBy: "\n")
                var property: [String]
                for propertyLine in propertiesArray {
                    property = propertyLine.components(separatedBy: "=")
                    if property.count == 2 {
                        property[1] = property[1].replacingOccurrences(of: "\\", with: "")
                    }
                    switch property[0] {
                    case "MAIN_URL":
                        prefs.set(URL(string: property[1])!, forKey: "validatorUrl")
                        prefs.set(URL(string: property[1].replacingOccurrences(of: "/validator", with: "/runner"))!, forKey: "runnerUrl")
                    case "MAIN_SCHEDULER_URL":
                        prefs.set(URL(string: property[1])!, forKey: "schedulerUrl")
                    case "TESTS_LOC":
                        prefs.set(URL(string: property[1])!, forKey: "testPath")
                    default:
                        _ = 0
                    }
                }
            } else {
                messageBox("Please select a valid NetIQ Validator program folder in Preferences.",
                    description: "The config/validator.properties file could not be found in " + validatorBasePath)
            }
        }
    }
    
    @objc func startService(_ sender: AnyObject) {
        if !validatorService.isRunning {
            validatorService = Process()

            if let validatorBasePath = prefs.string(forKey: "validatorBasePath")
            {
                let validatorCmdPath = validatorBasePath + "/runValidator.command"
                if FileManager().fileExists(atPath: validatorCmdPath) {
                    if optionUseCustomLicenseFile.selected {
                        let myLicense: String = CustomLicenseFile.stringValue
                        let exLicense: String = validatorBasePath + "/config/license.dat"
                        if FileManager().fileExists(atPath: myLicense) {
                            do {
                                if FileManager().fileExists(atPath: exLicense)
                                    && !FileManager().contentsEqual(atPath: myLicense, andPath: exLicense) {
                                    try FileManager().removeItem(atPath: exLicense)
                                }
                                if !FileManager().fileExists(atPath: exLicense) {
                                    try FileManager().copyItem(atPath: myLicense, toPath: exLicense)
                                }
                            } catch let error as NSError {
                                messageBox("Custom license could not be activated, starting Validator with existing license.",
                                    description: error.description)
                            }
                        }
                    }
                    validatorService.currentDirectoryPath = validatorBasePath
                    validatorService.launchPath = "/bin/bash"
                    if optionStartServiceInDebugMode.selected {
                        validatorService.arguments = [validatorCmdPath, "debug"]
                    } else {
                        validatorService.arguments = [validatorCmdPath]
                    }
                    validatorService.launch()
                }
            }
        }
        menuItemServiceUpdate()
    }
    
    @objc func stopService(_ sender: AnyObject) {
        if validatorService.isRunning {
            validatorService.terminate()
            validatorService.waitUntilExit()
        }
        menuItemServiceUpdate()
    }
    
    @objc func showConsole(_ sender: AnyObject) {
        // not yet implemented
    }
    
    func hideConsole(_ sender: AnyObject) {
        // not yet implemented
    }
    
    func menuItemServiceUpdate() {
        if validatorService.isRunning {
            menuItemService.title = "Stop Service"
            menuItemService.action = #selector(AppDelegate.stopService(_:))
            menuItemValidator.isEnabled = true
            menuItemRunner.isEnabled = isRunnerAvailable()
            menuItemScheduler.isEnabled = true
        } else {
            menuItemService.title = "Start Service"
            menuItemService.action = #selector(AppDelegate.startService(_:))
            menuItemValidator.isEnabled = false
            menuItemRunner.isEnabled = false
            menuItemScheduler.isEnabled = false
        }
    }
    
    func openBrowser(_ url: URL) {
        if let selectedBrowser = optionClientBrowser.selectedItem?.title {
            for browser in supportedBrowsers {
                if browser.name == selectedBrowser {
                    NSWorkspace.shared.open([url], withAppBundleIdentifier: browser.id, options: NSWorkspace.LaunchOptions.default, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
                    return
                }
            }
        } else {
            NSWorkspace.shared.open(url)
        }

    }

    @objc func openValidator(_ sender: AnyObject) {
        if let url = prefs.url(forKey: "validatorUrl") {
            openBrowser(url)
        }
    }

    @objc func openRunner(_ sender: AnyObject) {
        if let url = prefs.url(forKey: "runnerUrl")
        {
            openBrowser(url)
        }
    }
    
    @objc func openScheduler(_ sender: AnyObject) {
        if let url = prefs.url(forKey: "schedulerUrl")
        {
            openBrowser(url)
        }
    }
    
    @objc func quitApplication(_ sender: AnyObject) {
        NSApplication.shared.terminate(sender)
    }
    
}

func matches(_ searchString:String, pattern : String)->Bool{
    do {
        let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.dotMatchesLineSeparators)
        let matchCount = regex.numberOfMatches(in: searchString, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0,searchString.characters.count))
        return matchCount > 0
    } catch {
    }
    return false
}

func replace(_ searchString:String, pattern : String, replacementPattern:String)->String{
    do {
        let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.dotMatchesLineSeparators)
        let replacedString = regex.stringByReplacingMatches(in: searchString, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, searchString.characters.count), withTemplate: replacementPattern)
        return replacedString
    } catch {}
    return searchString
}

extension CFArray: Sequence {
    public func makeIterator() -> AnyIterator<AnyObject> {
        var index = -1
        let maxIndex = CFArrayGetCount(self)
        return AnyIterator{
            index += 1
            guard index < maxIndex else {
                return nil
            }
            let unmanagedObject: UnsafeRawPointer = CFArrayGetValueAtIndex(self, index)
            let rec = unsafeBitCast(unmanagedObject, to: AnyObject.self)
            return rec
        }
    }
}

extension NSButton {
    var selected: Bool {
        get {
            return self.state == NSControl.StateValue.on
        }
        set {
            if newValue {
                self.state = NSControl.StateValue.on
            } else {
                self.state = NSControl.StateValue.on
            }
        }
    }
}

