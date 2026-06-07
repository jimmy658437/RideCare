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
    
    @State private var aiRecommendations: [String] = []
    @State private var isAILoading = false

    // 依據當前選中的天氣，篩選裝備列表
    var filteredItems: [EquipmentItem] {
        equipments.filter { $0.isRainyDay == isRainyDaySelection }
    }
    
    // 動態決定當前主題色，讓背景光暈跟隨晴雨切換
    private var primaryThemeColor: Color {
        isRainyDaySelection ? .blue : .orange
    }

    var body: some View {
        ZStack {
            // 背景與頂部光暈效果
            AppTheme.background.ignoresSafeArea()
                .overlay(alignment: .topTrailing) {  // 預設放在右上角
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    primaryThemeColor.opacity(0.3), .clear,
                                ],  // 調整 0.3 改變光暈強度
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
                // 加入動畫，讓顏色切換時更柔和
                .animation(.easeInOut(duration: 0.5), value: primaryThemeColor)

            ScrollView(showsIndicators: false) {
                viewContent
            }
        }
        .navigationBarHidden(true)
        // 當切換晴雨天時，自動觸發 AI 重新推薦
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
            Text("設定不同天氣出門時的預設裝備提醒").font(.subheadline).foregroundStyle(AppTheme.onSurfaceVariant)
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
                                    withAnimation(.smooth) {
                                        item.isChecked.toggle()
                                        try? context.save()
                                    }
                                }
                            
                            Text(item.name)
                                .strikethrough(item.isChecked)
                                .foregroundStyle(item.isChecked ? AppTheme.onSurfaceVariant : AppTheme.onSurface)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    context.delete(item)
                                    try? context.save()
                                }
                            }) {
                                Image(systemName: "trash")
                                    .font(.subheadline)
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                        }
                    }
                    // 💥 關鍵核心：當新裝備卡片被插入畫面時，強制灌入 Pow 爆裂動畫效果
                    .modifier(PowEffectModifier(themeColor: isRainyDaySelection ? .blue : .orange))
                }
            }
        }
    }

    // MARK: - 新增裝備邏輯
    private func addItem() {
        guard !textInput.isEmpty else { return }
        let newItem = EquipmentItem(name: textInput, isRainyDay: isRainyDaySelection)
        
        // 🌟 透過強大的彈簧動畫包裹 SwiftData 資料流，讓畫面排版順暢位移
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
            context.insert(newItem)
            try? context.save()
        }
        textInput = ""
    }
    
    private func addSingleAIItem(name: String) {
        guard !filteredItems.contains(where: { $0.name == name }) else { return }
        
        let newItem = EquipmentItem(name: name, isRainyDay: isRainyDaySelection)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
            context.insert(newItem)
            try? context.save()
            aiRecommendations.removeAll { $0 == name }
        }
    }
    
    private func addAllAIItems() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
            for name in aiRecommendations {
                if !filteredItems.contains(where: { $0.name == name }) {
                    let newItem = EquipmentItem(name: name, isRainyDay: isRainyDaySelection)
                    context.insert(newItem)
                }
            }
            try? context.save()
            aiRecommendations.removeAll()
        }
    }
    
    // MARK: - ✨ Apple Foundation Model
    private func generateAIRecommendations() {
        isAILoading = true
        aiRecommendations.removeAll()

        Task {
            do {
                let items = try await RideCareAIManager.shared.generateRecommendations(isRainyDay: isRainyDaySelection)
                await MainActor.run {
                    withAnimation(.easeInOut) {
                        aiRecommendations = items.filter { item in
                            !filteredItems.contains { $0.name == item }
                        }
                        isAILoading = false
                    }
                }
            } catch {
                let fallbackItems = getSmartFallbackRecommendations()
                await MainActor.run {
                    withAnimation(.easeInOut) {
                        aiRecommendations = fallbackItems.filter { item in
                            !filteredItems.contains { $0.name == item }
                        }
                        isAILoading = false
                    }
                }
            }
        }
    }
    
    private func getSmartFallbackRecommendations() -> [String] {
        if isRainyDaySelection {
            return ["防水背包套", "安全帽除霧劑", "防水手套", "雨鞋"].shuffled().prefix(3).map { String($0) }
        } else {
            return ["太陽眼鏡", "防曬乳", "涼感噴霧", "防曬衣"].shuffled().prefix(3).map { String($0) }
        }
    }
}

// MARK: - 💥 ✨ Pow 爆裂動態修飾器與粒子發射器
struct PowEffectModifier: ViewModifier {
    var themeColor: Color = .purple
    
    @State private var animateParticle = false
    @State private var animateScale = false
    @State private var animateFlash = false
    
    func body(content: Content) -> some View {
        content
            // 1. 卡片本身的強力高頻彈簧進場（從 0.6 擴散至 1.0）
            .scaleEffect(animateScale ? 1.0 : 0.6)
            .shadow(color: themeColor.opacity(animateFlash ? 0 : 0.15), radius: animateFlash ? 0 : 10)
            .overlay(
                ZStack {
                    // 2. 震撼擊發的擴散擊穿圓環（Shockwave Ring）
                    Circle()
                        .stroke(themeColor.opacity(animateParticle ? 0 : 0.6), lineWidth: 3)
                        .frame(width: animateParticle ? 120 : 10)
                    
                    // 3. 💥 周圍向外擴散、縮小並淡出的 8 顆漫畫風粒子
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(themeColor.opacity(animateParticle ? 0 : 0.8))
                            // 隨著擴散，粒子本身會縮小成星點
                            .frame(width: animateParticle ? 3 : 8, height: animateParticle ? 3 : 8)
                            // 依據索引角計算分佈
                            .offset(x: animateParticle ? 75 : 0)
                            .rotationEffect(.degrees(Double(index) * 45))
                    }
                }
            )
            .onAppear {
                // 執行卡片彈回 Spring 動畫
                withAnimation(.spring(response: 0.32, dampingFraction: 0.52, blendDuration: 0)) {
                    animateScale = true
                }
                // 執行粒子向外爆炸擴散動畫
                withAnimation(.easeOut(duration: 0.45)) {
                    animateParticle = true
                }
                // 執行外發光一閃而逝的淡出
                withAnimation(.easeInOut(duration: 0.5)) {
                    animateFlash = true
                }
            }
    }
}
