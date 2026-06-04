//
//  AddFuelSheet.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/24.
//


import SwiftUI
import SwiftData

// MARK: - AddFuelSheet
struct AddFuelSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // 獲取所有油量紀錄，用來尋找「上一筆」以計算油耗
    @Query(sort: \FuelRecord.date, order: .reverse) private var allRecords: [FuelRecord]
    
    // 接收外部傳入的油價服務
    var fuelService: FuelPriceService
    
    // 全域里程變數 (與 HomeView 連動)
    @AppStorage("currentMileage") private var globalCurrentMileage = 13500.0
    // 引入設定頁的偏好油種
    @AppStorage("gasType") private var preferredGasType = "95 無鉛汽油"
    
    // 🌟 主題色同步：讀取與首頁、設定頁相同的 AppStorage 快取
    @AppStorage("themeColorHex") private var themeColorHex = "Default"
    
    // 🌟 計算當前的主題顏色
    private var primaryThemeColor: Color {
        if themeColorHex == "Default" {
            return AppTheme.primary // 你的預設深藍色
        } else {
            return Color(hex: themeColorHex)
        }
    }
    
    @State private var date = Date()
    @State private var mileage = ""
    @State private var liters = ""
    @State private var fuelType = "95" // 預設值，隨後會被 onAppear 覆蓋

    var body: some View {
        NavigationStack {
            Form {
                Section("加油詳情") {
                    DatePicker("紀錄日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .tint(primaryThemeColor) // 讓彈出的日曆/時間轉盤符合主題色
                    
                    TextField("目前總里程數 (km)", text: $mileage)
                        .keyboardType(.decimalPad)
                    
                    TextField("加油公升數 (L)", text: $liters)
                        .keyboardType(.decimalPad)
                    
                    Picker("汽油種類", selection: $fuelType) {
                        Text("92").tag("92")
                        Text("95").tag("95")
                        Text("98").tag("98")
                    }
                    .pickerStyle(.segmented)
                    // 🌟 分段選擇器套用全域主題色
                    .tint(primaryThemeColor)
                }
            }
            .navigationTitle("新增加油紀錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 左側取消按鈕
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(.secondary) // 保持中性色
                }
                
                // 右側儲存按鈕
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let currentMileage = Double(mileage) ?? 0
                        let currentLiters = Double(liters) ?? 0
                        
                        // 1. 同步全域里程
                        if currentMileage > globalCurrentMileage {
                            globalCurrentMileage = currentMileage
                        }
                        
                        // 2. 計算油耗
                        let previousRecord = allRecords.filter { $0.date < date }.first
                        var calculatedKmPerLiter: Double = 0.0
                        
                        if let prev = previousRecord, currentMileage > prev.mileage, currentLiters > 0 {
                            calculatedKmPerLiter = (currentMileage - prev.mileage) / currentLiters
                        }
                        
                        // 3. 計算花費
                        var calculatedCost: Double = 0.0
                        if let priceInfo = fuelService.prices.first(where: { $0.name.contains(fuelType) }) {
                            calculatedCost = priceInfo.price * currentLiters
                        }
                        
                        let newRecord = FuelRecord(
                            date: date,
                            mileage: currentMileage,
                            liters: currentLiters,
                            fuelType: fuelType,
                            kmPerLiter: calculatedKmPerLiter,
                            cost: calculatedCost
                        )
                        
                        context.insert(newRecord)
                        try? context.save()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(primaryThemeColor) // 🌟 儲存按鈕套用全域主題色
                }
            }
            .onAppear {
                // 修正 Picker 預設選擇：精準擷取設定值的字首
                let prefix = String(preferredGasType.prefix(2))
                if ["92", "95", "98"].contains(prefix) {
                    fuelType = prefix
                }
                
                // 💡 貼心優化：進入頁面時，自動幫忙預填當前的總里程數
                if mileage.isEmpty {
                    mileage = String(Int(globalCurrentMileage))
                }
            }
        }
        .presentationDetents([.medium])
    }
}
// 定義零件結構
struct BikePart: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let category: String
}


struct AddMaintenanceSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // 🌟 1. 加入全域里程變數 (與 HomeView 即時連動)
    @AppStorage("currentMileage") private var globalCurrentMileage = 13500.0
    
    // 🌟 2. 主題色同步：讀取與其他頁面相同的快取
    @AppStorage("themeColorHex") private var themeColorHex = "Default"
    
    // 計算當前的主題顏色
    private var primaryThemeColor: Color {
        if themeColorHex == "Default" {
            return AppTheme.primary // 原本預設的主題色
        } else {
            return Color(hex: themeColorHex)
        }
    }
    
    @State private var date = Date()
    @State private var mileage = ""
    @State private var cost = ""
    
    // 選取零件的狀態 (可多選)
    @State private var selectedParts: Set<String> = []
    @State private var customItem = ""
    
    // 依照第一張圖精準建立的四大系統資料
    let categorizedParts = [
        "引擎保養": [
            BikePart(name: "機油", icon: "oilcan.fill", category: "引擎保養"),
            BikePart(name: "齒輪油", icon: "gearshape.2.fill", category: "引擎保養"),
            BikePart(name: "機油濾芯", icon: "fuelpump.fill", category: "引擎保養"),
            BikePart(name: "空氣濾清器", icon: "wind", category: "引擎保養"),
            BikePart(name: "火星塞", icon: "sparkles", category: "引擎保養")
        ],
        "傳動系統": [
            BikePart(name: "傳動皮帶", icon: "link", category: "傳動系統"),
            BikePart(name: "普利珠", icon: "circle.grid.2x2.fill", category: "傳動系統"),
            BikePart(name: "離合器 / 碗公", icon: "arrow.clockwise", category: "傳動系統")
        ],
        "制動系統": [
            BikePart(name: "來令片 (煞車皮)", icon: "rectangle.grid.1x2.fill", category: "制動系統"),
            BikePart(name: "煞車油", icon: "drop.fill", category: "制動系統")
        ],
        "行車安全": [
            BikePart(name: "輪胎", icon: "circle.circle.fill", category: "行車安全"),
            BikePart(name: "電瓶 (電瓶)", icon: "batteryblock.fill", category: "行車安全")
        ]
    ]
    
    // 系統排序順序
    let categoriesOrder = ["引擎保養", "傳動系統", "制動系統", "行車安全"]
    
    // 自適應網格：一排顯示 3 個剛剛好，不會擁擠
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("保養詳情") {
                    DatePicker("紀錄日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .tint(primaryThemeColor) // 🌟 同步日曆選擇器顏色
                    
                    TextField("當前里程數 (km)", text: $mileage)
                        .keyboardType(.decimalPad)
                    
                    TextField("總花費金額 (NT$)", text: $cost)
                        .keyboardType(.numberPad)
                }
                
                Section("更換零件選擇") {
                    ForEach(categoriesOrder, id: \.self) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            // 系統標題
                            Text(category)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(primaryThemeColor) // 🌟 同步分類標題顏色
                                .padding(.top, 6)
                            
                            // 零件網格小卡片
                            if let parts = categorizedParts[category] {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(parts) { part in
                                        let isSelected = selectedParts.contains(part.name)
                                        
                                        Button(action: {
                                            if isSelected {
                                                selectedParts.remove(part.name)
                                            } else {
                                                selectedParts.insert(part.name)
                                            }
                                        }) {
                                            VStack(spacing: 8) {
                                                Image(systemName: part.icon)
                                                    .font(.title3)
                                                Text(part.name)
                                                    .font(.caption2)
                                                    .fontWeight(.medium)
                                                    .multilineTextAlignment(.center)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            // 🌟 點選時背景變成「主題色的 15% 透明度」，未選取時維持原底色
                                            .background(isSelected ? primaryThemeColor.opacity(0.15) : AppTheme.surfaceContainerLowest)
                                            // 🌟 文字與圖標顏色同步主題色
                                            .foregroundStyle(isSelected ? primaryThemeColor : AppTheme.onSurface)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    // 🌟 邊框顏色同步主題色
                                                    .stroke(isSelected ? primaryThemeColor.opacity(0.5) : AppTheme.outlineVariant.opacity(0.4), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle()) // 防呆：避免 Form 點擊衝突
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    
                    TextField("其他項目 (選填)", text: $customItem)
                        .padding(.top, 4)
                }
            }
            .navigationTitle("新增保養紀錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(.secondary) // 保持中性色
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let currentMileage = Double(mileage) ?? 0
                        
                        // 核心邏輯：判斷輸入的里程是否比全域里程高，如果是就覆蓋更新
                        if currentMileage > globalCurrentMileage {
                            globalCurrentMileage = currentMileage
                        }
                        
                        // 彙整選取的項目與自訂項目
                        var finalItems = Array(selectedParts)
                        if !customItem.trimmingCharacters(in: .whitespaces).isEmpty {
                            finalItems.append(customItem)
                        }
                        let combinedString = finalItems.joined(separator: "、")
                        
                        let newRecord = MaintenanceRecord(
                            date: date,
                            mileage: currentMileage,
                            item: combinedString.isEmpty ? "未指定項目" : combinedString,
                            cost: Double(cost) ?? 0
                        )
                        context.insert(newRecord)
                        try? context.save()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(primaryThemeColor) // 🌟 儲存按鈕同步主題色
                }
            }
        }
        .presentationDetents([.large])
    }
}
