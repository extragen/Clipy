//
//  XCDClipWindow.swift
//  XClipdiary
//
//  Created by Viacheslav Boretskyi on 2/18/16.
//  Copyright © 2016 Viacheslav Boretskyi. All rights reserved.
//

class XCDClipWindow: NSWindow, NSApplicationDelegate, NSWindowDelegate {
    
    override init(contentRect: NSRect, styleMask aStyle: Int, backing bufferingType: NSBackingStoreType, `defer` flag: Bool) {
        var mask: Int = aStyle
        if #available(OSX 10.10, *) {
            mask |= NSFullSizeContentViewWindowMask
        }
        
        super.init(contentRect: contentRect, styleMask: mask, backing: bufferingType, `defer`: flag)
        
        self.contentView!.wantsLayer = true;/*this can and is set in the view*/
        self.backgroundColor = NSColor.grayColor().colorWithAlphaComponent(0.8)
        self.opaque = false
        self.level =  Int(CGWindowLevelForKey(.MaximumWindowLevelKey))
        
        if #available(OSX 10.10, *) {
            
            self.titlebarAppearsTransparent = true
            self.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
            
            //<---the width and height is set to 0, as this doesn't matter.
            let visualEffectView = NSVisualEffectView(frame: NSMakeRect(0, 0, 0, 0))
            visualEffectView.wantsLayer = true
            //Dark,MediumLight,PopOver,UltraDark,AppearanceBased,Titlebar,Menu
            visualEffectView.material = NSVisualEffectMaterial.Light
            //I think if you set this to WithinWindow you get the effect safari has in its TitleBar. It should have an Opaque background behind it or else it will not work well
            visualEffectView.blendingMode = NSVisualEffectBlendingMode.BehindWindow
            visualEffectView.state = NSVisualEffectState.Inactive//FollowsWindowActiveState,Inactive
            
            self.contentView = visualEffectView/*you can also add the visualEffectView to the contentview, just add some width and height to the visualEffectView, you also need to flip the view if you like to work from TopLeft, do this through subclassing*/
        }
    }
    
    required init?(coder: NSCoder) {fatalError("init(coder:) has not been implemented")}/*Required by the NSWindow*/
}
