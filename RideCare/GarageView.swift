//
//  GarageView.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/23.
//

import Charts  // 🌟 引入圖表套件
import Pow
import SwiftData
import SwiftUI

struct GarageView: View {
    @Environment(\.modelContext) private var context
    
    // 🌟 引入設定頁的偏好設定
    @AppStorage("gasType") private var preferredGasType = "95 無鉛汽油"
    @AppStorage("themeColorHex") private var themeColorHex = "Blue" // 🌟 同步主題色字串
    
    // 🌟 將主題色字串轉換為 SwiftUI Color
    private var currentThemeColor: Color {
        if themeColorHex == "Default" {
            return AppTheme.primary
        } else {
            return Color(hex: themeColorHex)
        }
    }
    
    // 刪除加油紀錄
    private func deleteFuelRecord(_ record: FuelRecord) {
        context.delete(record)
        try? context.save()
    }
    
    // 刪除保養紀錄
    private func deleteMaintenanceRecord(_ record: MaintenanceRecord) {
        context.delete(record)
        try? context.save()
    }
    
    @Query(sort: \FuelRecord.date, order: .reverse, animation: .spring())
    private var fuelRecords: [FuelRecord]
    
    @Query(sort: \MaintenanceRecord.date, order: .reverse, animation: .spring())
    private var maintenanceRecords: [MaintenanceRecord]
    
    @State private var selection = 0
    @State private var showAddFuel = false
    @State private var showAddMaintenance = false
    
    // 🌟 控制 FAB 動畫的狀態
    @State private var showFAB = false
    
    @State private var fuelService = FuelPriceService()
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            
            // 🌟 替換為帶有光暈效果的背景
            AppTheme.background.ignoresSafeArea()
                .overlay(alignment: .topTrailing) {  // 預設放在右上角，若要左上角可改為 .topLeading
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    currentThemeColor.opacity(0.5), .clear, // 🌟 使用 currentThemeColor 讓光暈同步主題色
                                ],  // 調整 0.5 改變光暈強度
                                center: .center,
                                startRadius: 0,
                                endRadius: 700  // 控制光暈擴散範圍
                            )
                        )
                        .frame(width: 700, height: 700)  // 光暈的整體大小
                        .offset(x: 200, y: -80)  // 往外偏移，營造只有邊緣露出來的「圓弧」感
                        .blur(radius: 100)  // 柔化邊緣，產生微光感
                        .ignoresSafeArea()
                }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    titleSection
                    customSegmentedControl
                    
                    if selection == 0 {
                        fuelSection
                    } else {
                        maintenanceSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            
            // FAB 懸浮按鈕
            Button(action: {
                if selection == 0 {
                    showAddFuel = true
                } else {
                    showAddMaintenance = true
                }
            }) {
                Image(systemName: "plus")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(AppTheme.onPrimary)
                    .frame(width: 60, height: 60)
                    .background(currentThemeColor) // 🌟 FAB 套用動態主題色
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(
                        color: currentThemeColor.opacity(0.4), // 🌟 陰影同步主題色
                        radius: 10,
                        y: 5
                    )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            // 🌟 加入 FAB 縮放與透明度動畫效果
            .scaleEffect(showFAB ? 1 : 0.001)
            .opacity(showFAB ? 1 : 0)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddFuel) {
            AddFuelSheet(fuelService: fuelService)
                .modelContext(context)
        }
        .sheet(isPresented: $showAddMaintenance) {
            AddMaintenanceSheet().modelContext(context)
        }
        .task {
            if fuelService.prices.isEmpty {
                await fuelService.fetchPrices()
            }
        }
        // 🌟 畫面出現時觸發 Spring 動畫，消失時重置狀態
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                showFAB = true
            }
        }
        .onDisappear {
            showFAB = false
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("愛車管理").font(.title).fontWeight(.bold).foregroundStyle(
                AppTheme.onSurface
            )
            Text("追蹤您的愛車保養與油耗狀況").font(.subheadline).foregroundStyle(
                AppTheme.onSurfaceVariant
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
    }
    
    private var customSegmentedControl: some View {
        HStack(spacing: 0) {
            Button("油量紀錄") { selection = 0 }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(
                    selection == 0
                    ? AppTheme.surfaceContainerLowest : Color.clear
                )
                .foregroundStyle(
                    selection == 0
                    ? currentThemeColor : AppTheme.onSurfaceVariant // 🌟 選取文字套用主題色
                )
                .clipShape(Capsule())
            
            Button("保養紀錄") { selection = 1 }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(
                    selection == 1
                    ? AppTheme.surfaceContainerLowest : Color.clear
                )
                .foregroundStyle(
                    selection == 1
                    ? currentThemeColor : AppTheme.onSurfaceVariant // 🌟 選取文字套用主題色
                )
                .clipShape(Capsule())
        }
        .padding(4).background(AppTheme.outlineVariant.opacity(0.3)).clipShape(
            Capsule()
        )
    }
    
    // 中油今日牌價
    @ViewBuilder
    private var currentFuelPriceView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("中油今日牌價").font(.footnote).fontWeight(.bold).foregroundStyle(
                AppTheme.onSurfaceVariant
            )
            if fuelService.isLoading {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 10)
            } else if let error = fuelService.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            } else {
                HStack(spacing: 12) {
                    ForEach(fuelService.prices) { fuel in
                        // 🌟 將動態主題色傳入獨立的卡片元件中
                        FuelPriceCard(
                            name: fuel.name,
                            price: fuel.price,
                            preferredGasType: preferredGasType,
                            themeColor: currentThemeColor
                        )
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    // 平均油耗趨勢折線圖
    @ViewBuilder
    private var fuelChartSection: some View {
        let validRecords = fuelRecords.filter { $0.kmPerLiter > 0 }
        
        VStack(alignment: .leading, spacing: 10) {
            Text("平均油耗趨勢 (km/L)")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.onSurfaceVariant)
            
            if validRecords.count < 2 {
                FloatingCard {
                    Text("新增第二筆油耗紀錄後，即可查看趨勢圖！")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
            } else {
                let sortedRecords = validRecords.sorted { $0.date < $1.date }
                
                Chart(sortedRecords) { record in
                    LineMark(
                        x: .value("日期", record.date),
                        y: .value("油耗", record.kmPerLiter)
                    )
                    .symbol(Circle())
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(currentThemeColor) // 🌟 折線圖線條同步主題色
                    
                    AreaMark(
                        x: .value("日期", record.date),
                        y: .value("油耗", record.kmPerLiter)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [currentThemeColor.opacity(0.25), .clear], // 🌟 漸層同步主題色
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 150)
                .padding()
                .background(AppTheme.surfaceContainerLowest)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: AppTheme.outlineVariant.opacity(0.15),
                    radius: 5,
                    y: 2
                )
            }
        }
        .padding(.bottom, 8)
    }
    
    private var fuelSection: some View {
        VStack(spacing: 16) {
            currentFuelPriceView
            fuelChartSection
            
            if fuelRecords.isEmpty {
                Text("尚無加油紀錄，請點擊右下角新增。").font(.subheadline).foregroundStyle(
                    .secondary
                ).padding(.top, 40)
            } else {
                ForEach(fuelRecords) { record in
                    FloatingCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(
                                    "\(record.date, format: .dateTime.month().day()) • \(record.fuelType) 無鉛"
                                )
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(AppTheme.onSurface)
                                Text("\(Int(record.mileage)) km")
                                    .font(.caption).foregroundStyle(
                                        AppTheme.onSurfaceVariant
                                    )
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 6) {
                                Text("\(record.liters, specifier: "%.1f") L")
                                    .font(.subheadline).fontWeight(.bold)
                                    .foregroundStyle(AppTheme.onSurface)
                                
                                HStack(spacing: 8) {
                                    Text("NT$ \(Int(record.cost))")
                                        .font(.caption)
                                        .foregroundStyle(
                                            AppTheme.onSurfaceVariant
                                        )
                                    
                                    Text(
                                        record.kmPerLiter > 0
                                        ? "\(record.kmPerLiter, specifier: "%.1f") km/L"
                                        : "-- km/L"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(currentThemeColor) // 🌟 列表油耗數據同步主題色
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .transition(.movingParts.pop)
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation {
                                deleteFuelRecord(record)
                            }
                        } label: {
                            Label("刪除紀錄", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .animation(
            .spring(response: 0.4, dampingFraction: 0.7),
            value: fuelRecords
        )
        .changeEffect(.shine, value: fuelRecords.count)
    }
    
    private var maintenanceSection: some View {
        VStack(spacing: 16) {
            
            if let lastRecord = maintenanceRecords.first {
                VStack(alignment: .leading, spacing: 10) {
                    Text("上次保養項目")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                    
                    FloatingCard {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(lastRecord.item)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(currentThemeColor) // 🌟 精選保養項目標題同步主題色
                                
                                HStack(spacing: 12) {
                                    Label(
                                        "\(Int(lastRecord.mileage)) km",
                                        systemImage: "speedometer"
                                    )
                                    Label(
                                        "\(lastRecord.date, format: .dateTime.year().month().day())",
                                        systemImage: "calendar"
                                    )
                                }
                                .font(.caption)
                                .foregroundStyle(AppTheme.onSurfaceVariant)
                            }
                            Spacer()
                            Text("NT$ \(Int(lastRecord.cost))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.onSurface)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation {
                                deleteMaintenanceRecord(lastRecord)
                            }
                        } label: {
                            Label("刪除紀錄", systemImage: "trash")
                        }
                    }
                }
                .padding(.bottom, 8)
                
                HStack {
                    Text("歷史保養紀錄").font(.footnote).fontWeight(.bold)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                    Spacer()
                }
            }
            
            if maintenanceRecords.isEmpty {
                Text("尚無保養紀錄，請點擊右下角新增。").font(.subheadline).foregroundStyle(
                    .secondary
                ).padding(.top, 40)
            } else {
                ForEach(maintenanceRecords.dropFirst()) { record in
                    FloatingCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(record.item)
                                    .font(.subheadline).fontWeight(.medium)
                                    .foregroundStyle(AppTheme.onSurface)
                                Text(
                                    "\(record.date, format: .dateTime.month().day()) • \(Int(record.mileage)) km"
                                )
                                .font(.caption).foregroundStyle(
                                    AppTheme.onSurfaceVariant
                                )
                            }
                            Spacer()
                            Text("NT$ \(Int(record.cost))")
                                .font(.subheadline).fontWeight(.bold)
                                .foregroundStyle(currentThemeColor) // 🌟 歷史保養費用同步主題色
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .transition(.movingParts.pop)
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation {
                                deleteMaintenanceRecord(record)
                            }
                        } label: {
                            Label("刪除紀錄", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .animation(
            .spring(response: 0.4, dampingFraction: 0.7),
            value: maintenanceRecords
        )
        .changeEffect(.shine, value: maintenanceRecords.count)
    }
}

// MARK: - 獨立的油價卡片視圖 (已完美同步全域主題色)
struct FuelPriceCard: View {
    let name: String
    let price: Double
    let preferredGasType: String
    let themeColor: Color // 🌟 接收來自外層的動態主題色
    
    @State private var isPow = false
    
    var isPreferred: Bool {
        let prefPrefix = String(preferredGasType.prefix(2))
        return name.contains(prefPrefix)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(name.replacingOccurrences(of: "無鉛汽油", with: " 無鉛"))
                .font(.caption2)
                .foregroundStyle(isPreferred ? themeColor : AppTheme.onSurfaceVariant) // 🌟 高亮文字顏色同步
            
            Text("$\(price, specifier: "%.1f")")
                .font(.headline)
                .fontWeight(.black)
                .foregroundStyle(isPreferred ? themeColor : AppTheme.primary) // 🌟 高亮金額顏色同步
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        // 🌟 偏好油種高亮背景與邊框同步套用 themeColor
        .background(isPreferred ? themeColor.opacity(0.15) : AppTheme.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPreferred ? themeColor.opacity(0.6) : Color.clear, lineWidth: 1.5)
        )
        .shadow(
            color: AppTheme.outlineVariant.opacity(0.2),
            radius: 5,
            y: 2
        )
        .scaleEffect(isPreferred && isPow ? 1.05 : 1.0)
        .onAppear {
            if isPreferred {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.1)) {
                    isPow = true
                }
            }
        }
    }
}

#Preview {
    GarageView()
}
