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

    // MARK: - State

    @State private var isAnalyzing = true
    @State private var aiReport = ""
    @State private var glowIntensity: CGFloat = 0.5
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    // MARK: - AI Service

    @State private var aiService = AIService()

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
                                ? "正在整理油耗、里程與保養紀錄"
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
                await generateAIReport()
            }
        }
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

            // MARK: AI 呼叫

            let result = try await aiService.generateVehicleReport(
                currentMileage: currentMileage,
                avgKmPerLiter: avgKmPerLiter,
                latestMaintenance: latestMaintenance
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
        latestMaintenance: String
    ) async throws -> String {

        let prompt = """
        你是一位專業的台灣機車保養顧問。

        請根據以下車輛資訊：

        • 目前里程：\(Int(currentMileage)) km
        • 平均油耗：\(String(format: "%.1f", avgKmPerLiter)) km/L
        • 最近保養項目：\(latestMaintenance)

        幫我分析：

        1. 車況評估
        2. 油耗分析
        3. 保養建議
        4. 雨天騎乘注意事項
        5. 近期建議檢查的項目

        使用繁體中文。

        語氣專業但自然。

        不要太冗長。

        長度約 200 字。
        """

        let response = try await session.respond(
            to: prompt
        )

        return response.content
    }
}
