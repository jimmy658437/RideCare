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
    
    @State private var fuelService = FuelPriceService()
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppTheme.background.ignoresSafeArea()
            
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
                    .background(AppTheme.primaryContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(
                        color: AppTheme.primary.opacity(0.3),
                        radius: 10,
                        y: 5
                    )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
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
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("車庫管理").font(.title).fontWeight(.bold).foregroundStyle(
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
                    ? AppTheme.primary : AppTheme.onSurfaceVariant
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
                    ? AppTheme.primary : AppTheme.onSurfaceVariant
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
                        VStack(spacing: 4) {
                            Text(
                                fuel.name.replacingOccurrences(
                                    of: "無鉛汽油",
                                    with: " 無鉛"
                                )
                            )
                            .font(.caption2).foregroundStyle(
                                AppTheme.onSurfaceVariant
                            )
                            Text("$\(fuel.price, specifier: "%.1f")")
                                .font(.headline).fontWeight(.black)
                                .foregroundStyle(AppTheme.primary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(AppTheme.surfaceContainerLowest)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(
                            color: AppTheme.outlineVariant.opacity(0.2),
                            radius: 5,
                            y: 2
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
        // 過濾掉油耗為 0 的首筆資料
        let validRecords = fuelRecords.filter { $0.kmPerLiter > 0 }
        
        VStack(alignment: .leading, spacing: 10) {
            Text("平均油耗趨勢 (km/L)")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.onSurfaceVariant)
            
            // 🌟 折線圖至少需要 2 個點才能畫出線，若不足則顯示空狀態提示
            if validRecords.count < 2 {
                FloatingCard {
                    Text("新增第二筆油耗紀錄後，即可查看趨勢圖！")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center) // 🌟 撐滿寬度
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
                    .foregroundStyle(AppTheme.primary)
                    
                    AreaMark(
                        x: .value("日期", record.date),
                        y: .value("油耗", record.kmPerLiter)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.primary.opacity(0.25), .clear],
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
            fuelChartSection  // 注入折線圖
            
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
                                    .foregroundStyle(AppTheme.primary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity) // 🌟 撐開卡片寬度
                    }
                    .transition(.movingParts.pop)
                    // 🌟 加上長按刪除選單
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
            
            // 上次保養項目的卡片區塊
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
                                    .foregroundStyle(AppTheme.primary)
                                
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
                        .frame(maxWidth: .infinity) // 🌟 撐開卡片寬度
                        .padding(.vertical, 4)
                    }
                    // 🌟 首筆紀錄也支援長按刪除
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
                // 排除第一筆（因為已經放到獨立精選卡片了）
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
                                .foregroundStyle(AppTheme.primary)
                        }
                        .frame(maxWidth: .infinity) // 🌟 撐開卡片寬度
                    }
                    .transition(.movingParts.pop)
                    // 🌟 歷史紀錄加上長按刪除選單
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

#Preview {
    GarageView()
}
