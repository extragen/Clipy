//
//  CPYHtoKeyManager.swift
//  Clipy
//
//  Created by 古林俊佑 on 2015/06/21.
//  Copyright (c) 2015年 Shunsuke Furubayashi. All rights reserved.
//

import Cocoa
import Foundation


class CPYHotKeyManager: NSObject {

    // MARK: - Properties
    static let sharedManager = CPYHotKeyManager()
    
    var hotkeyMap: [String: AnyObject] {
        
        var map = [String: AnyObject]()
        var dict = [String: AnyObject]()

        dict = [kIndex: NSNumber(unsignedInteger: 0), kSelector: "popUpClipMenu:"]
        map.updateValue(dict, forKey: kClipMenuIdentifier)
        
        dict = [kIndex: NSNumber(unsignedInteger: 1), kSelector: "popUpHistoryMenu:"]
        map.updateValue(dict, forKey: kHistoryMenuIdentifier)
        
        dict = [kIndex: NSNumber(unsignedInteger: 2), kSelector: "popUpSnippetsMenu:"]
        map.updateValue(dict, forKey: kSnippetsMenuIdentifier)
        
        dict = [kIndex: NSNumber(unsignedInteger: 3), kSelector: "popUpCopyPrevClipMenu:"]
        map.updateValue(dict, forKey: kCopyPrevClipMenuIdentifier)
        
        dict = [kIndex: NSNumber(unsignedInteger: 4), kSelector: "popUpCopyNextClipMenu:"]
        map.updateValue(dict, forKey: kCopyNextClipMenuIdentifier)
        
        return map
    }
    
    
    // MARK: - Init
    override init() {
        super.init()
        self.initManager()
    }
    
    private func initManager() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.addObserver(self, forKeyPath: kCPYPrefHotKeysKey, options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    deinit {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObserver(self, forKeyPath: kCPYPrefHotKeysKey)
    }
    
    // MARK: - KVO
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == kCPYPrefHotKeysKey {
            self.registerHotKeys()
        }
    }
    
    // MARK: - Class Methods
    static func defaultHotKeyCombos() -> [String: AnyObject] {
        var hotKeyCombos = [String: AnyObject]()
        var newCombos: [PTKeyCombo] = []
        
        var keyCombo: PTKeyCombo!
        
        // Main menu key combo  (command + shift + v)
        keyCombo = PTKeyCombo(keyCode: 9, modifiers: 768)
        newCombos.append(keyCombo)
        
        // History menu key combo (command + control + v)
        keyCombo = PTKeyCombo(keyCode: 9, modifiers: 4352)
        newCombos.append(keyCombo)
        
        // Snipeets menu key combo (command+ shift + b)
        keyCombo = PTKeyCombo(keyCode: 11, modifiers: 768)
        newCombos.append(keyCombo)
        
        // copy prev clip menu key combo (clipController + alt + Up)
        keyCombo = PTKeyCombo(keyCode: 12, modifiers: 768)
        newCombos.append(keyCombo)
        
        // copy next clip key combo (clipController + alt + Down)
        keyCombo = PTKeyCombo(keyCode: 13, modifiers: 768)
        newCombos.append(keyCombo)
        
        let hotKeyMap = self.sharedManager.hotkeyMap
        for (key, value) in hotKeyMap {
            if let dict = value as? [String: AnyObject] {
                let indexNubmer = dict[kIndex] as! NSNumber
                let index = indexNubmer.integerValue
                let newKeyCombo = newCombos[index]
                hotKeyCombos.updateValue(newKeyCombo.plistRepresentation(), forKey: key)
            }
        }

        return hotKeyCombos
    }
    
    // MARK: - Public Methods
    func registerHotKeys() {
        let hotKeyCenter = PTHotKeyCenter.sharedCenter()
        
        let hotKeyCombs = NSUserDefaults.standardUserDefaults().objectForKey(kCPYPrefHotKeysKey) as! [String: AnyObject]
        
        let defaultHotKeyCombos = CPYHotKeyManager.defaultHotKeyCombos()
        for (key, _) in defaultHotKeyCombos {
            var keyComboPlist: AnyObject? = hotKeyCombs[key]
            if keyComboPlist == nil {
                keyComboPlist = defaultHotKeyCombos[key]
            }
            let keyCombo = PTKeyCombo(plistRepresentation: keyComboPlist!)
            
            let hotKey = PTHotKey(identifier: key, keyCombo: keyCombo)
            
            let hotKeyDict = self.hotkeyMap[key] as! [String: AnyObject]
            let selectorName = hotKeyDict[kSelector] as! String
            hotKey.setTarget(self)
            hotKey.setAction(Selector(selectorName))
            
            hotKeyCenter.registerHotKey(hotKey)
        }
    }
    
    func unRegisterHotKeys() {
        let hotKeyCenter = PTHotKeyCenter.sharedCenter()
        for hotKey in hotKeyCenter.allHotKeys() as! [PTHotKey] {
            hotKeyCenter.unregisterHotKey(hotKey)
        }
    }
    
    // MARK: - HotKey Action Methods
    func popUpClipMenu(sender: AnyObject) {
        CPYMenuManager.sharedManager.popUpMenuForType(.Main)
    }
    
    func popUpHistoryMenu(sender: AnyObject) {
        CPYMenuManager.sharedManager.popUpMenuForType(.History)
    }
    
    func popUpSnippetsMenu(sender: AnyObject) {
        CPYMenuManager.sharedManager.popUpMenuForType(.Snippets)
    }
    
    private var clipController: XCDClipController!
    
    func popUpCopyPrevClipMenu(sender: AnyObject) {
        popUpCopyClipWindow(CPYClipManager.sharedManager.copyPrevClipToPasteboard())
    }
    
    func popUpCopyNextClipMenu(sender: AnyObject) {
        popUpCopyClipWindow(CPYClipManager.sharedManager.copyNextClipToPasteboard())
    }
    
    func hideCopyClipMenu(sender: AnyObject) {
        clipController.close()
    }
    
    func popUpCopyClipWindow(clip: CPYClip?) {
        self.stopClipWindowTimer()
        
        if (clip != nil) {
            //copy a clip to the paste board
            CPYClipManager.sharedManager.copyClipToPasteboard(clip!)
            print("clip title: \(clip!.title)")

        }

        //show popup
        self.createXCDClipController()
        self.clipController.updateClip(clip)
        self.clipController.showWindow(nil)
        
        self.startClipWindowTimer()
    }
    
    private func createXCDClipController() {
        //create clipController if it is not exists or a main screen is changed.
        if (self.clipController == nil || self.clipController.window != nil && self.clipController.window?.screen != NSScreen.mainScreen()) {
            self.clipController = XCDClipController(windowNibName: "XCDClipController")
        }
    }
    
    var clipWindowTimer: NSTimer?;
    
    // MARK: - Timer Methods
    func startClipWindowTimer() {
        self.stopClipWindowTimer()
        
        let defaults = NSUserDefaults.standardUserDefaults()
        var timeInterval = defaults.floatForKey(kXCDPrefPopupIntervalKey)
        if timeInterval > 3.0{
            timeInterval = 3.0
            defaults.setFloat(timeInterval, forKey: kXCDPrefPopupIntervalKey)
        }
        
        self.clipWindowTimer = NSTimer(timeInterval: NSTimeInterval(timeInterval), target: self, selector: "hideCopyClipMenu:", userInfo: nil, repeats: false)
        NSRunLoop.currentRunLoop().addTimer(self.clipWindowTimer!, forMode: NSRunLoopCommonModes)
    }
    
    func stopClipWindowTimer() {
        if self.clipWindowTimer != nil && self.clipWindowTimer!.valid {
            self.clipWindowTimer?.invalidate()
        }
    }

}
