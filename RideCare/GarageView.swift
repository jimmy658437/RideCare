//
//  GarageView.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/23.
//


import SwiftUI
import SwiftData
import Pow // 引入 Pow 動畫套件

struct GarageView: View {
    @Environment(\.modelContext) private var context
    
    // 加入 animation: .spring() 讓陣列變動時會有擠壓動畫
    @Query(sort: \FuelRecord.date, order: .reverse, animation: .spring())
    private var fuelRecords: [FuelRecord]
    
    @Query(sort: \MaintenanceRecord.date, order: .reverse, animation: .spring())
    private var maintenanceRecords: [MaintenanceRecord]

    @State private var selection = 0
    @State private var showAddFuel = false
    @State private var showAddMaintenance = false

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

            // 新增資料懸浮按鈕 (FAB)
            Button(action: {
                if selection == 0 { showAddFuel = true }
                else { showAddMaintenance = true }
            }) {
                Image(systemName: "plus")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(AppTheme.onPrimary)
                    .frame(width: 60, height: 60)
                    .background(AppTheme.primaryContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: AppTheme.primary.opacity(0.3), radius: 10, y: 5)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddFuel) {
            AddFuelSheet()
                .modelContext(context)
        }
        .sheet(isPresented: $showAddMaintenance) {
            AddMaintenanceSheet()
                .modelContext(context)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("車庫管理").font(.title).fontWeight(.bold).foregroundStyle(AppTheme.onSurface)
            Text("追蹤您的愛車保養與油耗狀況").font(.subheadline).foregroundStyle(AppTheme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
    }

    private var customSegmentedControl: some View {
        HStack(spacing: 0) {
            Button("油量紀錄") { selection = 0 }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(selection == 0 ? AppTheme.surfaceContainerLowest : Color.clear)
                .foregroundStyle(selection == 0 ? AppTheme.primary : AppTheme.onSurfaceVariant)
                .clipShape(Capsule())
            
            Button("保養紀錄") { selection = 1 }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(selection == 1 ? AppTheme.surfaceContainerLowest : Color.clear)
                .foregroundStyle(selection == 1 ? AppTheme.primary : AppTheme.onSurfaceVariant)
                .clipShape(Capsule())
        }
        .padding(4).background(AppTheme.outlineVariant.opacity(0.3)).clipShape(Capsule())
    }

    private var fuelSection: some View {
        VStack(spacing: 16) {
            if fuelRecords.isEmpty {
                Text("尚無加油紀錄，請點擊右下角新增。").font(.subheadline).foregroundStyle(.secondary).padding(.top, 40)
            } else {
                ForEach(fuelRecords) { record in
                    FloatingCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(record.date, format: .dateTime.month().day()) • \(record.fuelType) 無鉛")
                                    .font(.subheadline).fontWeight(.medium).foregroundStyle(AppTheme.onSurface)
                                Text("\(Int(record.mileage)) km")
                                    .font(.caption).foregroundStyle(AppTheme.onSurfaceVariant)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 6) {
                                Text("\(record.liters, specifier: "%.1f") L")
                                    .font(.subheadline).fontWeight(.bold).foregroundStyle(AppTheme.onSurface)
                                Text("\(record.kmPerLiter, specifier: "%.1f") km/L")
                                    .font(.caption).foregroundStyle(AppTheme.primary)
                            }
                        }
                    }
                    // 🌟 Pow 特效：卡片新增時的Ｑ彈進場轉場
                    .transition(.movingParts.pop)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: fuelRecords)
        // 🌟 Pow 特效：只要資料筆數改變，整個區域掃過一道閃亮光澤
        .changeEffect(.shine, value: fuelRecords.count)
    }

    private var maintenanceSection: some View {
        VStack(spacing: 16) {
            if maintenanceRecords.isEmpty {
                Text("尚無保養紀錄，請點擊右下角新增。").font(.subheadline).foregroundStyle(.secondary).padding(.top, 40)
            } else {
                ForEach(maintenanceRecords) { record in
                    FloatingCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(record.item)
                                    .font(.subheadline).fontWeight(.medium).foregroundStyle(AppTheme.onSurface)
                                Text("\(record.date, format: .dateTime.month().day()) • \(Int(record.mileage)) km")
                                    .font(.caption).foregroundStyle(AppTheme.onSurfaceVariant)
                            }
                            Spacer()
                            Text("NT$ \(Int(record.cost))")
                                .font(.subheadline).fontWeight(.bold).foregroundStyle(AppTheme.primary)
                        }
                    }
                    // 🌟 Pow 特效：卡片新增時的Ｑ彈進場轉場
                    .transition(.movingParts.pop)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: maintenanceRecords)
        // 🌟 Pow 特效：新增保養紀錄時掃過光澤
        .changeEffect(.shine, value: maintenanceRecords.count)
    }
}

#Preview {
    GarageView()
}
