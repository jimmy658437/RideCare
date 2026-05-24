//
//  MainTabView.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/23.
//


import SwiftUI

struct MainTabView: View {
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
        .tint(AppTheme.primary)
    }
}

#Preview {
    MainTabView()
}
