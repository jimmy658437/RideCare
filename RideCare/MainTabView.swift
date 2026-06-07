//
//  MainTabView.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/23.
//


import SwiftUI

struct MainTabView: View {
    // 🌟 1. 引入設定頁的偏好設定 (比照 GarageView 的寫法)
    @AppStorage("themeColorHex") private var themeColorHex = "Blue"
    
    // 🌟 2. 將主題色字串轉換為 SwiftUI Color (比照 GarageView 的判斷邏輯)
    private var currentThemeColor: Color {
        if themeColorHex == "Default" {
            return AppTheme.primary
        } else {
            // 確保有加上 ?? fallback，避免解析 hex 失敗時報錯
            return Color(hex: themeColorHex)
        }
    }

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("首頁", systemImage: "house.fill")
            }
            
            NavigationStack {
                GarageView()
            }
            .tabItem {
                Label("車庫", systemImage: "scooter")
            }
            
            NavigationStack {
                TripView()
            }
            .tabItem {
                Label("裝備", systemImage: "bag.fill")
            }
        }
        // 🌟 3. 將原本固定的顏色替換為動態主題色
        .tint(currentThemeColor)
        // 🌟 4. 加入動畫修飾，讓切換主題色時 TabBar 上的 icon 顏色也能順滑過渡
        .animation(.easeInOut(duration: 0.4), value: themeColorHex)
    }
}

#Preview {
    MainTabView()
}
