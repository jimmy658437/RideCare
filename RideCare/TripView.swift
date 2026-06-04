//
//  TripView.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/23.
//


import SwiftUI
import SwiftData
import Foundation
import FoundationModels

struct TripView: View {
    @Environment(\.modelContext) private var context
    @Query private var equipments: [EquipmentItem]

    @AppStorage("selectedWeatherTab") private var isRainyDaySelection = false // 與首頁共用的晴雨狀態
    @State private var textInput = ""
    
    // ✨ 新增 AI 狀態控管
    @State private var aiRecommendations: [String] = []
    @State private var isAILoading = false

    // 依據當前選中的天氣，篩選裝備列表
    var filteredItems: [EquipmentItem] {
        equipments.filter { $0.isRainyDay == isRainyDaySelection }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                viewContent
            }
        }
        .navigationBarHidden(true)
        // ✨ 當切換晴雨天時，自動觸發 AI 重新推薦
        .onChange(of: isRainyDaySelection, initial: true) { _, _ in
            generateAIRecommendations()
        }
    }
    
    // MARK: - 主視圖排版
    @ViewBuilder
    private var viewContent: some View {
        VStack(spacing: 20) {
            titleSection
            customSegmentedControl // 晴天/雨天切換
            
            // ✨ 新增：AI 智慧推薦卡片區塊
            aiRecommendationCard
            
            inputCard // 自定義新增按鈕
            
            equipmentSectionList
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
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

    // MARK: - ✨ 新增：AI 智慧推薦卡片視圖
    private var aiRecommendationCard: some View {
        FloatingCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.purple)
                        Text("Apple Intelligence 推薦裝備")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    if isAILoading {
                        ProgressView()
                            .controlSize(.small)
                    } else if !aiRecommendations.isEmpty {
                        // 一鍵全部加入
                        Button(action: addAllAIItems) {
                            Text("全部加入")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.purple)
                        }
                    }
                }
                
                if isAILoading {
                    Text("RideCare 正在為您精選合適的騎士裝備...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else if aiRecommendations.isEmpty {
                    Text("暫無推薦裝備，點擊可重試。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .onTapGesture { generateAIRecommendations() }
                } else {
                    // 顯示 AI 推薦的晶片（Chips）
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(aiRecommendations, id: \.self) { itemName in
                                Button(action: { addSingleAIItem(name: itemName) }) {
                                    HStack(spacing: 4) {
                                        Text(itemName)
                                        Image(systemName: "plus")
                                            .font(.caption2)
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.purple.opacity(0.1))
                                    .foregroundStyle(.purple)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
        }
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

    // MARK: - 新增裝備邏輯
    private func addItem() {
        guard !textInput.isEmpty else { return }
        let newItem = EquipmentItem(name: textInput, isRainyDay: isRainyDaySelection)
        context.insert(newItem)
        try? context.save()
        textInput = ""
    }
    
    // ✨ 新增：單個加入 AI 推薦裝備
    private func addSingleAIItem(name: String) {
        // 防呆：如果裝備庫中已經有同名的，就不重複加入
        guard !filteredItems.contains(where: { $0.name == name }) else { return }
        
        let newItem = EquipmentItem(name: name, isRainyDay: isRainyDaySelection)
        context.insert(newItem)
        try? context.save()
        
        // 從推薦列表中移除已加入的
        withAnimation {
            aiRecommendations.removeAll { $0 == name }
        }
    }
    
    // ✨ 新增：批次加入所有 AI 推薦裝備
    private func addAllAIItems() {
        for name in aiRecommendations {
            if !filteredItems.contains(where: { $0.name == name }) {
                let newItem = EquipmentItem(name: name, isRainyDay: isRainyDaySelection)
                context.insert(newItem)
            }
        }
        try? context.save()
        withAnimation {
            aiRecommendations.removeAll()
        }
    }
    
    // MARK: - ✨ AI Foundation Model 整合控制核心
    private func generateAIRecommendations() {

        isAILoading = true
        aiRecommendations.removeAll()

        Task {

            do {

                let items =
                    try await RideCareAIManager.shared
                        .generateRecommendations(
                            isRainyDay: isRainyDaySelection
                        )

                await MainActor.run {

                    aiRecommendations =
                        items.filter { item in
                            !filteredItems.contains {
                                $0.name == item
                            }
                        }

                    isAILoading = false
                }

            } catch {

                let fallbackItems =
                    getSmartFallbackRecommendations()

                await MainActor.run {

                    aiRecommendations =
                        fallbackItems.filter { item in
                            !filteredItems.contains {
                                $0.name == item
                            }
                        }

                    isAILoading = false
                }
            }
        }
    }
    
    // 💡 智慧離線推薦池（當 AI 尚未解析完成前，依據當前狀態提供高水準的裝備池組合）
    private func getSmartFallbackRecommendations() -> [String] {
        if isRainyDaySelection {
            return ["防水背包套", "安全帽除霧劑", "防水手套", "大包塑膠袋"].shuffled().prefix(3).map { String($0) }
        } else {
            return ["抗UV護目鏡", "騎士運動水壺", "手套透氣墊", "防曬貼片"].shuffled().prefix(3).map { String($0) }
        }
    }
}

#Preview {
    TripView()
}
