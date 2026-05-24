//
//  RideCareApp.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/23.
//


import SwiftUI
import SwiftData

@main
struct RideCareApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FuelRecord.self,
            MaintenanceRecord.self,
            EquipmentItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            // 檢查是否需要初始化預設裝備
            Task { @MainActor in
                let context = container.mainContext
                let descriptor = FetchDescriptor<EquipmentItem>()
                let existingItems = try? context.fetch(descriptor)
                
                if existingItems?.isEmpty ?? true {
                    // 雨天預設
                    context.insert(EquipmentItem(name: "雨衣", isRainyDay: true))
                    context.insert(EquipmentItem(name: "鞋套", isRainyDay: true))
                    context.insert(EquipmentItem(name: "雨鞋", isRainyDay: true))
                    
                    // 晴天預設
                    context.insert(EquipmentItem(name: "袖套", isRainyDay: false))
                    context.insert(EquipmentItem(name: "涼感頭套", isRainyDay: false))
                    context.insert(EquipmentItem(name: "防曬乳", isRainyDay: false))
                    context.insert(EquipmentItem(name: "防曬外套", isRainyDay: false))
                    
                    try? context.save()
                }
            }
            return container
        } catch {
            fatalError("無法建立 ModelContainer: \(error)")
        }
    }() // 👈 關鍵修正：這裡加上了 () 來立刻執行這段閉包

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
