//
//  Color.swift
//  Bolito
//
//  Created by Alex Marcelle on 01/10/26.
//

import SwiftUI
import AppKit

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }
    
    func toHex() -> String? {
        guard let components = NSColor(self)
            .usingColorSpace(.sRGB)?
            .cgColor
            .components,
              components.count >= 3 else {
            return nil
        }
        
        let red = Int(components[0] * 255)
        let green = Int(components[1] * 255)
        let blue = Int(components[2] * 255)
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
