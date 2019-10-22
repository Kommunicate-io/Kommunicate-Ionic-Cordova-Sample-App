//
//  UIColor+Extension.swift
//  Applozic
//
//  Created by Shivam Pokhriyal on 12/10/18.
//  Copyright © 2018 applozic Inc. All rights reserved.
//

import Foundation

import UIKit

public extension UIColor {
    public convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    public convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
    //0xAARRGGBB
    static func hex8(_ netHex:Int64) -> UIColor {
        let shiftedRed = netHex >> 16
        let redBits = shiftedRed & 0xff
        
        let shiftedGreen = netHex >> 8
        let greenBits = shiftedGreen & 0xff
        
        let shiftedBlue = netHex
        let blueBits = shiftedBlue & 0xff
        
        let alpha = CGFloat((netHex >> 24) & 0xff)
        return UIColor(red:Int(redBits), green:Int(greenBits), blue:Int(blueBits)).withAlphaComponent(alpha/255.0)
    }
    
    static func mainRed() -> UIColor {
        return UIColor.init(netHex: 0xE00909)
    }
    
    static func borderGray() -> UIColor {
        return UIColor.init(netHex: 0xDBDFE2)
    }
    
    static func lineBreakerProfile() -> UIColor {
        return UIColor.init(netHex: 0xEAEAEA)
    }
    
    static func circleChartStartPointRed() -> UIColor {
        return UIColor.init(netHex: 0xCE0A11)
    }
    
    static func circleChartGray() -> UIColor {
        return UIColor.init(netHex: 0xCCCCCC)
    }
    
    static func circleChartPurple() -> UIColor {
        return UIColor.init(netHex: 0x350064)
    }
    
    static func circleChartTextColor() -> UIColor {
        return UIColor.init(netHex: 0x666666)
    }
    
    static func placeholderGray() -> UIColor {
        return UIColor.init(netHex: 0xCCCCCC)
    }
    
    static func disabledButton() -> UIColor {
        return UIColor.init(netHex: 0xCCCCCC)
    }
    
    static func onlineGreen() -> UIColor {
        return UIColor.init(netHex: 0x0EB04B)
    }
    
    static func navigationOceanBlue() -> UIColor {
        return UIColor.init(netHex: 0xECEFF1)
    }
    
    static func navigationTextOceanBlue() -> UIColor {
        return UIColor.init(netHex: 0x19A5E4)
    }
}
