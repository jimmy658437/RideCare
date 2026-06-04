//
//  AIAdvisorSheet.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/24.
//

import SwiftUI
import SwiftData
import Pow
import FoundationModels

struct AIAdvisorSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - SwiftData
    @Query(sort: \FuelRecord.date, order: .reverse)
    private var fuelRecords: [FuelRecord]
    
    @Query(sort: \MaintenanceRecord.date, order: .reverse)
    private var maintenanceRecords: [MaintenanceRecord]
    
    // MARK: - AppStorage
    @AppStorage("currentMileage")
    private var currentMileage = 13500.0
    @AppStorage("maintenanceInterval")
    private var maintenanceInterval = 1000.0

    @AppStorage("gearoilInterval")
    private var gearoilInterval = 2000.0

    @AppStorage("tireInterval")
    private var tireInterval = 10000.0

    @AppStorage("airFilterInterval")
    private var airFilterInterval = 5000.0

    @AppStorage("gasType")
    private var gasType = "95 無鉛汽油"
    
    // MARK: - State
    @State private var isAnalyzing = true
    @State private var aiReport = ""
    @State private var glowIntensity: CGFloat = 0.5
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // MARK: - Services
    @State private var aiService = AIService()
    // 1️⃣ 引入天氣 ViewModel
    @StateObject private var weatherVM = WeatherViewModel()
    
    // MARK: - Gradient
    let aiGradient = LinearGradient(
        colors: [
            .purple,
            .blue,
            .indigo,
            .cyan
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        
                        // MARK: - AI Orb
                        Circle()
                            .fill(aiGradient)
                            .frame(width: 110, height: 110)
                            .overlay {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 38))
                                    .foregroundStyle(.white)
                            }
                            .shadow(
                                color: .purple.opacity(glowIntensity),
                                radius: isAnalyzing ? 35 : 12
                            )
                            .scaleEffect(isAnalyzing ? 1.08 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.6)
                                    .repeatForever(autoreverses: true),
                                value: isAnalyzing
                            )
                            .padding(.top, 24)
                        
                        // MARK: - Title
                        VStack(spacing: 8) {
                            Text(
                                isAnalyzing
                                ? "AI 正在分析您的車況資料..."
                                : "AI 車況健檢報告"
                            )
                            .font(.title2)
                            .fontWeight(.bold)
                            
                            Text(
                                isAnalyzing
                                ? "正在整理油耗、保養紀錄與即時天氣"
                                : "由 Apple Foundation Models 產生"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        
                        // MARK: - Loading
                        if isAnalyzing {
                            VStack(spacing: 18) {
                                ProgressView()
                                    .tint(.purple)
                                    .scaleEffect(1.2)
                                
                                Text("請稍候...")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 20)
                            
                        } else {
                            // MARK: - AI Report Card
                            VStack(alignment: .leading, spacing: 18) {
                                Label(
                                    "分析結果",
                                    systemImage: "brain.head.profile"
                                )
                                .font(.headline)
                                
                                Text(aiReport)
                                    .font(.body)
                                    .lineSpacing(8)
                                    .foregroundStyle(
                                        AppTheme.onSurfaceVariant
                                    )
                                    .contentTransition(.opacity)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(
                                AppTheme.surfaceContainerLowest
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: 28)
                            )
                            .shadow(
                                color: .black.opacity(0.06),
                                radius: 10
                            )
                            .transition(.movingParts.pop)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("AI 顧問")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
            .alert(
                "AI 分析失敗",
                isPresented: $showErrorAlert
            ) {
                Button("知道了") { }
            } message: {
                Text(errorMessage)
            }
            .task {
                // 2️⃣ 先抓取當前天氣，再產生 AI 報告
                await weatherVM.fetchWeather()
                await generateAIReport()
            }
        }
    }
    
    //保養里程
    private func lastMaintenanceMileage(
        keyword: String
    ) -> Double? {

        maintenanceRecords
            .filter {
                $0.item.localizedCaseInsensitiveContains(keyword)
            }
            .sorted {
                $0.date > $1.date
            }
            .first?
            .mileage
    }
    
    // MARK: - Generate AI Report
    private func generateAIReport() async {
        do {
            // MARK: 平均油耗
            let avgKmPerLiter =
                fuelRecords.isEmpty
                ? 0
                : fuelRecords
                    .map { $0.kmPerLiter }
                    .reduce(0, +)
                    / Double(fuelRecords.count)
            
            // MARK: 最近保養
            let latestMaintenance =
                maintenanceRecords.first?.item
                ?? "尚無保養紀錄"
            
            let lastOilMileage =
                lastMaintenanceMileage(keyword: "機油")
                ?? 0

            let oilRemaining =
                maintenanceInterval -
                (currentMileage - lastOilMileage)
            
            let lastGearOilMileage =
                lastMaintenanceMileage(keyword: "齒輪油")
                ?? 0

            let gearOilRemaining =
                gearoilInterval -
                (currentMileage - lastGearOilMileage)
            
            let lastTireMileage =
                lastMaintenanceMileage(keyword: "輪胎")
                ?? 0

            let tireRemaining =
                tireInterval -
                (currentMileage - lastTireMileage)
            
            let lastAirFilterMileage =
                lastMaintenanceMileage(keyword: "空濾")
                ?? 0

            let airFilterRemaining =
                airFilterInterval -
                (currentMileage - lastAirFilterMileage)
            
            // MARK: AI 呼叫 (3️⃣ 傳入天氣參數)
            let result = try await aiService.generateVehicleReport(
                currentMileage: currentMileage,
                avgKmPerLiter: avgKmPerLiter,
                latestMaintenance: latestMaintenance,

                oilRemaining: oilRemaining,
                gearOilRemaining: gearOilRemaining,
                tireRemaining: tireRemaining,
                airFilterRemaining: airFilterRemaining,

                gasType: gasType,

                temperature: weatherVM.temperature,
                weatherDescription: weatherVM.weatherDescription
            )
            
            // MARK: 更新畫面
            await MainActor.run {
                aiReport = result
                withAnimation(.spring(duration: 0.8)) {
                    isAnalyzing = false
                    glowIntensity = 0.2
                }
            }
            
        } catch {
            await MainActor.run {
                isAnalyzing = false
                errorMessage = """
                請確認：
                
                • 使用 iOS 26
                • 裝置支援 Apple Intelligence
                • Apple Intelligence 已開啟
                """
                showErrorAlert = true
            }
        }
    }
}

// MARK: - AI Service

@Observable
final class AIService {
    
    private let session = LanguageModelSession()
    
    func generateVehicleReport(
        currentMileage: Double,
        avgKmPerLiter: Double,
        latestMaintenance: String,

        oilRemaining: Double,
        gearOilRemaining: Double,
        tireRemaining: Double,
        airFilterRemaining: Double,

        gasType: String,

        temperature: Double?,
        weatherDescription: String?
    ) async throws -> String {
        
        // 將天氣資訊格式化，處理可能沒有網路或沒有設定 API Key 的情況
        let weatherContext: String
        if let temp = temperature, let desc = weatherDescription {
            weatherContext = "氣溫 \(String(format: "%.1f", temp))°C，天氣狀況：\(desc)"
        } else {
            weatherContext = "未知"
        }
        
        // 5️⃣ 更新 Prompt 指令
        let prompt = """
        你是一位專業的台灣速克達機車保養顧問。
        
                使用繁體中文。

                每一次的內容都不要使用：
                #
                ##
                ###
                *
                -
                •
                每一次的內容都不要使用 Markdown。

                請直接輸出自然語言。

                格式如下：

                【車況評估】
                內容

                【油耗分析】
                內容

                【保養建議】
                內容

                【天氣與騎乘注意事項】
                內容

                【近期檢查項目】
                內容
        
        請根據以下車輛與環境資訊：
        
        • 目前里程：
        \(Int(currentMileage)) km

        • 平均油耗：
        \(String(format: "%.1f", avgKmPerLiter)) km/L

        • 偏好油種：
        \(gasType)

        • 最近保養：
        \(latestMaintenance)

        • 機油剩餘：
        \(Int(oilRemaining)) km

        • 齒輪油剩餘：
        \(Int(gearOilRemaining)) km

        • 輪胎剩餘：
        \(Int(tireRemaining)) km

        • 空濾剩餘：
        \(Int(airFilterRemaining)) km

        • 天氣：
        \(weatherContext)
        
        
        幫我分析：
        1. 車況評估
        2. 油耗分析
        3. 保養建議
        4. 基於「當前天氣狀況」的騎乘與注意事項 (若天氣未知則提供一般建議)
        5. 近期建議檢查的項目
        
        若某項耗材剩餘里程低於：

        100 km → 高優先級
        300 km → 中優先級

        請明確指出。

        依照：

        立即處理
        近期處理
        持續觀察

        三個等級整理。
        
        
        語氣專業但自然。
        不要太冗長。
        長度約 200-250 字。
        """
        
        let response = try await session.respond(
            to: prompt
        )
        
        return response.content
    }
}
