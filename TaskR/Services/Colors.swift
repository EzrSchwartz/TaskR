//
//  Colors.swift
//  TaskR
//
//  Created by Ezra Schwartz on 4/27/25.
//

import SwiftUI

struct AppColors {
    static let pearlWhite = Color(red: 245/255, green: 245/255, blue: 240/255)
    static let forestGreen = Color(red: 34/255, green: 139/255, blue: 34/255)
    
    static let primaryGreen = forestGreen
    static let secondaryGreen = primaryGreen.opacity(0.8)
    static let lightGreen = primaryGreen.opacity(0.1)
    static let primaryBlue = Color(red: 0.20, green: 0.60, blue: 0.86)
    static let secondaryBlue = Color(red: 0.28, green: 0.71, blue: 0.91)
    static let lightBlue = Color(red: 0.80, green: 0.92, blue: 0.96)
    static let primaryYellow = Color(red: 0.95, green: 0.77, blue: 0.06)
    static let secondaryYellow = Color(red: 0.98, green: 0.84, blue: 0.14)
    static let lightYellow = Color(red: 0.99, green: 0.94, blue: 0.80)
    static let primaryRed = Color(red: 0.91, green: 0.26, blue: 0.21)
    static let secondaryRed = Color(red: 0.94, green: 0.38, blue: 0.31)
    static let lightRed = Color(red: 0.98, green: 0.82, blue: 0.81)
    static let primaryGray = Color.gray
    static let secondaryGray = Color.gray.opacity(0.7)
    static let lightGray = Color.gray.opacity(0.2)
    static let offWhite = pearlWhite
}
