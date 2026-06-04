//
//  RideCareAIManager.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/6/4.
//


import Foundation
import FoundationModels

@Generable
struct EquipmentRecommendation {

    @Guide(description: "機車騎士裝備名稱")
    let name: String
}

@MainActor
final class RideCareAIManager {

    static let shared = RideCareAIManager()

    private let model = SystemLanguageModel.default

    func generateRecommendations(
        isRainyDay: Bool
    ) async throws -> [String] {

        guard model.availability == .available else {
            throw AIError.notAvailable
        }

        let session = LanguageModelSession(
            instructions:
            """
            你是 RideCare 的機車騎士裝備顧問。

            根據天氣情境推薦實用裝備。

            避免推薦過於基礎的物品。
            """
        )

        let weatherContext =
            isRainyDay
            ? "雨天、道路濕滑、能見度差"
            : "晴天、高溫、烈日曝曬"

        let response = try await session.respond(
            to:
            """
            天氣情境：

            \(weatherContext)

            請推薦 4 個機車騎士適合攜帶的裝備。
            """,
            generating: [EquipmentRecommendation].self
        )

        return response.content.map(\.name)
    }
}

enum AIError: Error {
    case notAvailable
}
