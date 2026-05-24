//
//  AIAdvisorSheet.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/24.
//


import SwiftUI
import SwiftData
import Pow

struct AIAdvisorSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // 取得資料庫中的紀錄
    @Query(sort: \FuelRecord.date, order: .reverse) private var fuelRecords: [FuelRecord]
    @Query(sort: \MaintenanceRecord.date, order: .reverse) private var maintenanceRecords: [MaintenanceRecord]
    @AppStorage("currentMileage") private var currentMileage = 13500.0
    
    @State private var isAnalyzing = true
    @State private var aiReport: String = ""
    @State private var glowIntensity: CGFloat = 0.5
    
    // Apple Intelligence 風格漸層
    let aiGradient = LinearGradient(
        colors: [.purple, .blue, .indigo, .cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // AI 視覺動態區
                    Circle()
                        .fill(aiGradient)
                        .frame(width: 100, height: 100)
                        .overlay(Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(.white))
                        .shadow(color: .purple.opacity(glowIntensity), radius: isAnalyzing ? 30 : 10)
                        .scaleEffect(isAnalyzing ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnalyzing)
                    
                    Text(isAnalyzing ? "AI 正在分析您的車況數據..." : "AI 車況健檢報告")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.onSurface)
                        .contentTransition(.numericText())
                    
                    if isAnalyzing {
                        ProgressView()
                            .tint(.purple)
                            .padding(.top, 20)
                    } else {
                        // 分析結果卡片
                        ScrollView {
                            Text(aiReport)
                                .font(.body)
                                .lineSpacing(8)
                                .foregroundStyle(AppTheme.onSurfaceVariant)
                                .padding()
                                .background(AppTheme.surfaceContainerLowest)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .black.opacity(0.05), radius: 5)
                                .transition(.movingParts.pop) // Pow 彈出特效
                        }
                    }
                    Spacer()
                }
                .padding(.top, 40)
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") { dismiss() }
                }
            }
            .onAppear {
                generateAIReport()
            }
        }
    }
    
    // 模擬 AI 分析邏輯
    private func generateAIReport() {
        Task {
            // 1. 統整資料 (未來這段文字就是要送給真實 AI API 的 Prompt)
            let avgKmPerLiter = fuelRecords.isEmpty ? 0 : fuelRecords.map { $0.kmPerLiter }.reduce(0, +) / Double(fuelRecords.count)
            let latestMaintenance = maintenanceRecords.first?.item ?? "無"
            
            let promptContext = """
            當前里程：\(Int(currentMileage)) km
            平均油耗：\(String(format: "%.1f", avgKmPerLiter)) km/L
            最近一次保養項目：\(latestMaintenance)
            """
            
            // 印出 Prompt 供開發時檢查
            print("【準備發送給 AI 的資料】\n\(promptContext)")
            
            // 2. 模擬網路延遲與 AI 思考時間 (2.5秒)
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            
            // 3. 模擬 AI 回傳的結果
            let mockResponse = """
            ✨ 綜合評估：您的愛車目前狀況良好！
            
            📊 數據分析：
            • 您的平均油耗為 \(String(format: "%.1f", avgKmPerLiter)) km/L。若近期發現油耗低於此數值，建議檢查胎壓或空氣濾清器。
            • 最近一次進行了「\(latestMaintenance)」保養。
            
            💡 AI 建議：
            依照您目前的總里程 \(Int(currentMileage)) km，如果距離上次更換煞車油或皮帶已經超過一萬公里，建議在下次保養時請技師特別檢查傳動系統，確保雨天騎乘安全！
            """
            
            // 4. 更新畫面
            await MainActor.run {
                self.aiReport = mockResponse
                withAnimation {
                    self.isAnalyzing = false
                    self.glowIntensity = 0.2
                }
            }
        }
    }
}