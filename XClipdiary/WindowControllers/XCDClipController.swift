//
//  XCDClipController.swift
//  XClipdiary
//
//  Created by Viacheslav Boretskyi on 2/17/16.
//  Copyright © 2016 Viacheslav Boretskyi. All rights reserved.
//

import Cocoa

class XCDClipController: NSWindowController {
        
    @IBOutlet weak var textCell: NSTextFieldCell!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var dateCell: NSTextFieldCell!
    
    var clip: CPYClip?
    private let SHORTEN_SYMBOL = "..."
    private var shortVersion = ""
    private let MAX_LINES = 7
    private let MAX_LINE_LENGTH = 60

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        updateClip(self.clip)
    }
}

protocol XCDClipDelegate {
    func updateClip(clip: CPYClip?)
}

extension XCDClipController: XCDClipDelegate {
    
    func updateClip(clip: CPYClip?) {
        self.clip = clip
        
        if self.textCell != nil {
            //hide imageView
            self.imageView.hidden = true
            self.imageView.image = nil
            
            if self.clip == nil {
                self.textCell.title = kEmptyString;
            }
            else {
                let primaryPboardType = clip!.primaryType
                var title = self.trimTitle(clip!.title)
                
                if primaryPboardType == NSTIFFPboardType {
                    title = "(Image)"
                } else if primaryPboardType == NSPDFPboardType {
                    title = "(PDF)"
                } else if primaryPboardType == NSFilenamesPboardType {
                    title = "(Files:)\n\(title)"
                }
                
                self.textCell.title = title
                
                let date = NSDate(timeIntervalSince1970: NSTimeInterval(clip!.updateTime))
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "HH:mm:ss yyyy-MM-dd"
                self.dateCell.title = dateFormatter.stringFromDate(date)
                
                let defaults = NSUserDefaults.standardUserDefaults()
                let isShowImage = defaults.boolForKey(kCPYPrefShowImageInTheMenuKey)
                if !clip!.thumbnailPath.isEmpty && isShowImage {
                    PINCache.sharedCache().objectForKey(clip!.thumbnailPath, block: { (cache, key, object) -> Void in
                        if let image = object as? NSImage {
                            self.imageView.hidden = false
                            self.imageView.image = image
                        }
                    })
                }
            }
        }
    }
    
    private func trimTitle(clipString: String?) -> String {
        if clipString == nil {
            return kEmptyString
        }
        
        let text = clipString!
        
        var i = 0
        var rows = [String]()
        text.enumerateLines({ (row, stop) -> () in
            let line = row as NSString
            let aRange = NSMakeRange(0, 0)
            var lineStart = 0, lineEnd = 0, contentsEnd = 0
            line.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, forRange: aRange)
            
            var lineString = (lineEnd == line.length) ? line : line.substringToIndex(contentsEnd)
            
            if lineString.length > self.MAX_LINE_LENGTH {
                lineString = lineString.substringToIndex(self.MAX_LINE_LENGTH - self.SHORTEN_SYMBOL.characters.count) + self.SHORTEN_SYMBOL
            }
            
            rows.append(lineString as String)
            
            if (++i) == self.MAX_LINES {
                stop = true
            }
        })
        
        if rows.count == MAX_LINES {
            rows.append(SHORTEN_SYMBOL)
        }
        
        return rows.joinWithSeparator("\n")
    }
}