//
//  TripView.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/23.
//


import SwiftUI
import SwiftData

struct TripView: View {
    @Environment(\.modelContext) private var context
    @Query private var equipments: [EquipmentItem]

    @AppStorage("selectedWeatherTab") private var isRainyDaySelection = false // 與首頁共用的晴雨狀態
    @State private var textInput = ""

    // 依據當前選中的天氣，篩選裝備列表
    var filteredItems: [EquipmentItem] {
        equipments.filter { $0.isRainyDay == isRainyDaySelection }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    titleSection
                    customSegmentedControl // 晴天/雨天切換
                    
                    inputCard // 自定義新增按鈕
                    
                    equipmentSectionList
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - 組件
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("裝備庫管理").font(.title).fontWeight(.bold).foregroundStyle(AppTheme.onSurface)
            Text("設定不同天氣出門時的防呆預設提醒").font(.subheadline).foregroundStyle(AppTheme.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
    }

    private var customSegmentedControl: some View {
        HStack(spacing: 0) {
            Button(action: { isRainyDaySelection = false }) {
                HStack {
                    Image(systemName: "sun.max.fill")
                    Text("晴天配置")
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(!isRainyDaySelection ? AppTheme.surfaceContainerLowest : Color.clear)
                .foregroundStyle(!isRainyDaySelection ? .orange : AppTheme.onSurfaceVariant)
                .clipShape(Capsule())
            }
            
            Button(action: { isRainyDaySelection = true }) {
                HStack {
                    Image(systemName: "cloud.rain.fill")
                    Text("雨天配置")
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(isRainyDaySelection ? AppTheme.surfaceContainerLowest : Color.clear)
                .foregroundStyle(isRainyDaySelection ? .blue : AppTheme.onSurfaceVariant)
                .clipShape(Capsule())
            }
        }
        .padding(4).background(AppTheme.outlineVariant.opacity(0.3)).clipShape(Capsule())
    }

    private var inputCard: some View {
        FloatingCard {
            HStack {
                TextField(isRainyDaySelection ? "自定義新增雨天裝備..." : "自定義新增晴天裝備...", text: $textInput)
                    .textFieldStyle(.plain)
                
                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.primary)
                }
            }
        }
    }

    private var equipmentSectionList: some View {
        VStack(spacing: 12) {
            if filteredItems.isEmpty {
                Text("此分類下沒有裝備，請由上方新增").font(.caption).foregroundStyle(.secondary).padding(.top, 20)
            } else {
                ForEach(filteredItems) { item in
                    FloatingCard {
                        HStack(spacing: 16) {
                            // 打勾按鈕（會與首頁同步）
                            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isChecked ? .green : AppTheme.outlineVariant)
                                .onTapGesture {
                                    item.isChecked.toggle()
                                    try? context.save()
                                }
                            
                            Text(item.name)
                                .strikethrough(item.isChecked)
                                .foregroundStyle(item.isChecked ? AppTheme.onSurfaceVariant : AppTheme.onSurface)
                            
                            Spacer()
                            
                            // 刪除按鈕
                            Button(action: {
                                context.delete(item)
                                try? context.save()
                            }) {
                                Image(systemName: "trash")
                                    .font(.subheadline)
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - 新增裝備
    private func addItem() {
        guard !textInput.isEmpty else { return }
        let newItem = EquipmentItem(name: textInput, isRainyDay: isRainyDaySelection)
        context.insert(newItem)
        try? context.save()
        textInput = ""
    }
}

#Preview {
    TripView()
}
