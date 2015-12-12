//
//  AppDelegate.swift
//  ValidatorLauncher for Mac
//
//  Created by Lothar Haeger on 03.09.15.
//  Copyright (c) 2015 Lothar Haeger. All rights reserved.
//

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
    
    let appAbout =  "Launcher for NetIQ Validator\n\n" +
                    "Version 0.9.1, 2015-09-24\n\n" +
                    "© 2015 Lothar Haeger (lothar.haeger@is4it.de)\n\n"
    let homePageUrl = "http://www.is4it.de/en/solution/identity-access-management/"

    let supportedBrowsers = [(name: "Safari",  id: "com.apple.Safari"),
                             (name: "Firefox", id: "org.mozilla.firefox"),
                             (name: "Chrome",  id: "com.google.Chrome")]


    let prefs = NSUserDefaults.standardUserDefaults()

    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var menuItemService : NSMenuItem = NSMenuItem()
    var menuItemConsole : NSMenuItem = NSMenuItem()
    var menuItemValidator : NSMenuItem = NSMenuItem()
    var menuItemRunner : NSMenuItem = NSMenuItem()
    var menuItemScheduler : NSMenuItem = NSMenuItem()
    var menuItemPrefs : NSMenuItem = NSMenuItem()
    var menuItemQuit : NSMenuItem = NSMenuItem()
    var validatorUrl : NSURL!
    var validatorService: NSTask = NSTask()
    
    override func awakeFromNib() {

        // Build status bar menu
        let icon = NSImage(named: "MenuIcon")
        icon!.template = true
        menu.autoenablesItems = false
        
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = menu
        statusBarItem.image = icon
        statusBarItem.title = ""
        
        //"Start/Stop Service" menuItem
        menuItemService.title = "Start Service"
        menu.addItem(menuItemService)
        
        //"Show/Hide Service Console" menuItem (hidden until implemented)
        menuItemConsole.title = "Show Console"
        menuItemConsole.action = Selector("showConsole:")
        menuItemConsole.hidden = true
        menu.addItem(menuItemConsole)
        
        // Separator
        menu.addItem(NSMenuItem.separatorItem())
        
        //"Open Validator" menuItem
        menuItemValidator.title = "Open Validator"
        menuItemValidator.action = Selector("openValidator:")
        menu.addItem(menuItemValidator)

        
        //"Open Runner" menuItem
        menuItemRunner.title = "Open Runner"
        menuItemRunner.action = Selector("openRunner:")
        menu.addItem(menuItemRunner)
        menuItemRunner.enabled = false
        
        //"Open Scheduler" menuItem
        menuItemScheduler.title = "Open Scheduler"
        menuItemScheduler.action = Selector("openScheduler:")
        menu.addItem(menuItemScheduler)
        
        // Separator
        menu.addItem(NSMenuItem.separatorItem())
        
        //"Preferences" menuItem
        menuItemPrefs.title = "Preferences"
        menuItemPrefs.action = Selector("Preferences:")
        menu.addItem(menuItemPrefs)
        
        // Separator
        menu.addItem(NSMenuItem.separatorItem())
        
        // "Quit" menuItem
        menuItemQuit.title = "Quit"
        menuItemQuit.action = Selector("quitApplication:")
        menu.addItem(menuItemQuit)

        // Update dynamic settings depending on Validator service status
        menuItemServiceUpdate()
    }
    
    @IBAction func optionUseCustomLicenseFile(sender: NSButton) {
        self.prefs.setInteger(optionUseCustomLicenseFile.state, forKey: "optionUseCustomLicenseFile")
        if optionUseCustomLicenseFile.selected {
            CustomLicenseFile.enabled = true
            CustomLicenseFileSelector.enabled = true
            if let customLicenseFilePath = prefs.stringForKey("customLicenseFilePath") {
                CustomLicenseFile.stringValue = customLicenseFilePath
            } else {
                CustomLicenseFile.stringValue = ""
            }
        } else {
            CustomLicenseFile.enabled = false
            CustomLicenseFileSelector.enabled = false
            CustomLicenseFile.stringValue = "config/license.dat"
        }
    }
    
    @IBAction func buttonStartServiceOnLaunch(sender: NSButton) {
        self.prefs.setInteger(optionStartServiceOnLaunch.state, forKey: "optionStartServiceOnLaunch")
    }
    
    @IBAction func buttonStartServiceInDebugMode(sender: NSButton) {
        self.prefs.setInteger(optionStartServiceInDebugMode.state, forKey: "optionStartServiceInDebugMode")
    }
    
    @IBAction func buttonShowServiceConsole(sender: NSButton) {
        self.prefs.setInteger(optionShowServiceConsole.state, forKey: "optionShowServiceConsole")
    }
    
    @IBAction func buttonOpenValidatorClient(sender: NSButton) {
        self.prefs.setInteger(optionOpenValidatorClient.state, forKey: "optionOpenValidatorClient")
    }
    
    @IBAction func buttonOpenRunnerClient(sender: NSButton) {
        self.prefs.setInteger(optionOpenRunnerClient.state, forKey: "optionOpenRunnerClient")
    }
    
    @IBAction func buttonOpenSchedulerClient(sender: NSButton) {
        self.prefs.setInteger(optionOpenSchedulerClient.state, forKey: "optionOpenSchedulerClient")
    }
    
    @IBAction func popupClientBrowser(sender: NSPopUpButtonCell) {
        self.prefs.setValue(optionClientBrowser.titleOfSelectedItem, forKey: "optionClientBrowser")
    }

    @IBAction func homePagePressed(sender: NSButton) {
        let url = NSURL(string: homePageUrl)
        openBrowser(url!)
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        window.level = Int(CGWindowLevelForKey(CGWindowLevelKey.FloatingWindowLevelKey))
        
        // hide checkbox until option is implemented
        optionShowServiceConsole.hidden = true
        
        // initialize browser list
        optionClientBrowser.removeAllItems()
        for browser in supportedBrowsers {
            optionClientBrowser.addItemWithTitle(browser.name)
            optionClientBrowser.itemWithTitle(browser.name)!.enabled = false
        }
        if let installedBrowsers = LSCopyAllHandlersForURLScheme("https")?.takeUnretainedValue() {
            for installedBrowser in installedBrowsers {
                for browser in supportedBrowsers {
                    if browser.id == String(installedBrowser){
                        optionClientBrowser.itemWithTitle(browser.name)?.enabled = true
                    }
                }
            }
        }

        // update about tab contents
        aboutText.stringValue = appAbout
        // homepage link
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = NSTextAlignment.Center
        homePage.attributedTitle = NSAttributedString(
                                        string: homePageUrl,
                                        attributes: [ NSFontAttributeName: NSFont.systemFontOfSize(13.0),
                                                      NSForegroundColorAttributeName: NSColor.blueColor(),
                                                      NSUnderlineStyleAttributeName: 1,
                                                      NSParagraphStyleAttributeName: pstyle])
        
        if readPreferences() {
            self.window!.orderOut(self)
            readPropertiesFile()
            if optionStartServiceOnLaunch.selected {
                startService(self)
                sleep(3)
            }
            if validatorService.running {
                if optionShowServiceConsole.selected {
                    showConsole(self)
                }
                if optionOpenValidatorClient.selected {
                    openValidator(self)
                }
                if optionOpenRunnerClient.selected {
                    openRunner(self)
                }
                if optionOpenSchedulerClient.selected {
                    openScheduler(self)
                }
            }
        } else {
            self.window!.orderFrontRegardless()
        }
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        stopService(self)
    }
 
    @IBAction func BasePathSelector(sender: NSButton) {
        setValidatorBasePath()
    }

    @IBAction func BasePath(sender: NSTextField) {
    }
    
    @IBAction func CustomLicenseFileSelector(sender: NSButton) {
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
            if result == NSFileHandlingPanelOKButton {
                    CustomLicenseFile.stringValue = openPanel.URL!.path!
                    self.prefs.setURL(openPanel.URL!, forKey: "customLicenseFilePath")
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
            if result == NSFileHandlingPanelOKButton {
                if isValidatorInstallPath(openPanel.URL!.path!) {
                    BasePath.stringValue = openPanel.URL!.path!
                    self.prefs.setURL(openPanel.URL!, forKey: "validatorBasePath")
                    readPropertiesFile()
                    break
                }
            } else {
                break
            }
        }
    }
    
    func messageBox(message: String, description: String?=nil) -> Bool {
        let myPopup: NSAlert = NSAlert()
        myPopup.alertStyle = NSAlertStyle.CriticalAlertStyle
        myPopup.addButtonWithTitle("OK")
        myPopup.messageText = message
        if let informativeText = description {
            myPopup.informativeText = informativeText
        }
        return (myPopup.runModal() == NSAlertFirstButtonReturn)
    }
    
    func readPreferences() -> Bool {
        
        if let validatorBasePath = prefs.stringForKey("validatorBasePath") {
            
            // Service tab
            BasePath.stringValue = validatorBasePath
            optionUseCustomLicenseFile.state = prefs.integerForKey("optionUseCustomLicenseFile")
            CustomLicenseFile.enabled = Bool(optionUseCustomLicenseFile.state)
            CustomLicenseFileSelector.enabled = CustomLicenseFile.enabled
            if CustomLicenseFile.enabled {
                CustomLicenseFile.stringValue = prefs.URLForKey("customLicenseFilePath")!.path!
            } else {
                CustomLicenseFile.stringValue = "config/license.dat"
            }
            optionStartServiceOnLaunch.state = prefs.integerForKey("optionStartServiceOnLaunch")
            optionStartServiceInDebugMode.state = prefs.integerForKey("optionStartServiceInDebugMode")
            optionShowServiceConsole.state = prefs.integerForKey("optionShowServiceConsole")

            // Clients tab
            optionOpenValidatorClient.state = prefs.integerForKey("optionOpenValidatorClient")
            optionOpenRunnerClient.state = prefs.integerForKey("optionOpenRunnerClient")
            optionOpenSchedulerClient.state = prefs.integerForKey("optionOpenSchedulerClient")
            optionClientBrowser.selectItemWithTitle(String(prefs.valueForKey("optionClientBrowser")!))

            if isValidatorInstallPath(validatorBasePath) {
                return true
            }
        } else {
            messageBox("Please select your NetIQ Validator program folder.",
                description: "Validator Launcher could not find your NetIQ Validator program folder.")
        }
        return false
    }
    
    func isValidatorInstallPath(validatorBasePath: String) -> Bool {
        let validatorCmdPath = validatorBasePath + "/runValidator.command"
        if NSFileManager().fileExistsAtPath(validatorCmdPath) {
            let validatorPropsPath = validatorBasePath + "/config/validator.properties"
            if NSFileManager().fileExistsAtPath(validatorPropsPath) {
                return true
            }else{
                messageBox("Please select a valid NetIQ Validator program folder.",
                    description: "The config/validator.properties file could not be found in \(validatorBasePath).")
            }
        } else {
            messageBox("Please select your NetIQ Validator program folder.",
                description: "The runValidator.command script could not be found in \(validatorBasePath).")
        }
        return false
    }

    func Preferences(sender: AnyObject){
        readPreferences()
        self.window!.orderFrontRegardless()
    }
    
    func readPropertiesFile() -> Bool {
        if let validatorBasePath = prefs.stringForKey("validatorBasePath")
        {
            let validatorPropsPath = validatorBasePath + "/config/validator.properties"
            if NSFileManager().fileExistsAtPath(validatorPropsPath) {
                let propertiesArray = (try! String(contentsOfFile: validatorPropsPath, encoding: NSUTF8StringEncoding)).componentsSeparatedByString("\n")
                var property: [String]
                for propertyLine in propertiesArray {
                    property = propertyLine.componentsSeparatedByString("=")
                    if property.count == 2 {
                        property[1] = property[1].stringByReplacingOccurrencesOfString("\\", withString: "")
                    }
                    switch property[0] {
                    case "MAIN_URL":
                        prefs.setURL(NSURL(string: property[1])!, forKey: "validatorUrl")
                        prefs.setURL(NSURL(string: property[1].stringByReplacingOccurrencesOfString("/validator", withString: "/runner"))!, forKey: "runnerUrl")
                    case "MAIN_SCHEDULER_URL":
                        prefs.setURL(NSURL(string: property[1])!, forKey: "schedulerUrl")
                    case "TESTS_LOC":
                        prefs.setURL(NSURL(string: property[1])!, forKey: "testPath")
                    default:
                        _ = 0
                    }
                }
                return true
            } else {
                messageBox("Please select a valid NetIQ Validator program folder in Preferences.",
                    description: "The config/validator.properties file could not be found in " + validatorBasePath)
            }
        }
        return false
    }
    
    func startService(sender: AnyObject) {
        if !validatorService.running {
            validatorService = NSTask()

            if let validatorBasePath = prefs.stringForKey("validatorBasePath")
            {
                let validatorCmdPath = validatorBasePath + "/runValidator.command"
                if NSFileManager().fileExistsAtPath(validatorCmdPath) {
                    if optionUseCustomLicenseFile.selected {
                        let myLicense: String = CustomLicenseFile.stringValue
                        let exLicense: String = validatorBasePath + "/config/license.dat"
                        if NSFileManager().fileExistsAtPath(myLicense) {
                            do {
                                if NSFileManager().fileExistsAtPath(exLicense)
                                    && !NSFileManager().contentsEqualAtPath(myLicense, andPath: exLicense) {
                                    try NSFileManager().removeItemAtPath(exLicense)
                                }
                                if !NSFileManager().fileExistsAtPath(exLicense) {
                                    try NSFileManager().copyItemAtPath(myLicense, toPath: exLicense)
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
    
    func stopService(sender: AnyObject) {
        if validatorService.running {
            validatorService.terminate()
            validatorService.waitUntilExit()
        }
        menuItemServiceUpdate()
    }
    
    func showConsole(sender: AnyObject) {
        // not yet implemented
    }
    
    func hideConsole(sender: AnyObject) {
        // not yet implemented
    }
    
    func menuItemServiceUpdate() {
        if validatorService.running {
            menuItemService.title = "Stop Service"
            menuItemService.action = Selector("stopService:")
            menuItemValidator.enabled = true
            menuItemRunner.enabled = true
            menuItemScheduler.enabled = true
        } else {
            menuItemService.title = "Start Service"
            menuItemService.action = Selector("startService:")
            menuItemValidator.enabled = false
            menuItemRunner.enabled = false
            menuItemScheduler.enabled = false
        }
    }
    
    func openBrowser(url: NSURL) {
        if let selectedBrowser = optionClientBrowser.selectedItem?.title {
            for browser in supportedBrowsers {
                if browser.name == selectedBrowser {
                    NSWorkspace.sharedWorkspace().openURLs([url], withAppBundleIdentifier: browser.id, options: NSWorkspaceLaunchOptions.Default, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
                    return
                }
            }
        } else {
            NSWorkspace.sharedWorkspace().openURL(url)
        }

    }

    func openValidator(sender: AnyObject) {
        if let url = prefs.URLForKey("validatorUrl") {
            openBrowser(url)
        }
    }

    func openRunner(sender: AnyObject) {
        if let url = prefs.URLForKey("runnerUrl")
        {
            openBrowser(url)
        }
    }
    
    func openScheduler(sender: AnyObject) {
        if let url = prefs.URLForKey("schedulerUrl")
        {
            openBrowser(url)
        }
    }
    
    func quitApplication(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(sender)
    }
    
}

func matches(searchString:String, pattern : String)->Bool{
    do {
        let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions.DotMatchesLineSeparators)
        let matchCount = regex.numberOfMatchesInString(searchString, options: NSMatchingOptions.init(rawValue: 0), range: NSMakeRange(0,searchString.characters.count))
        return matchCount > 0
    } catch {
    }
    return false
}

func replace(searchString:String, pattern : String, replacementPattern:String)->String{
    do {
        let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions.DotMatchesLineSeparators)
        let replacedString = regex.stringByReplacingMatchesInString(searchString, options: NSMatchingOptions.init(rawValue: 0), range: NSMakeRange(0, searchString.characters.count), withTemplate: replacementPattern)
        return replacedString
    } catch {}
    return searchString
}

extension CFArray: SequenceType {
    public func generate() -> AnyGenerator<AnyObject> {
        var index = -1
        let maxIndex = CFArrayGetCount(self)
        return anyGenerator{
            guard ++index < maxIndex else {
                return nil
            }
            let unmanagedObject: UnsafePointer<Void> = CFArrayGetValueAtIndex(self, index)
            let rec = unsafeBitCast(unmanagedObject, AnyObject.self)
            return rec
        }
    }
}

extension NSButton {
    var selected: Bool {
        get {
            return self.state == NSOnState
        }
        set {
            if newValue {
                self.state = NSOnState
            } else {
                self.state = NSOffState
            }
        }
    }
}

