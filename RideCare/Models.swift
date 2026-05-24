//
//  FuelRecord.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/23.
//


import Foundation
import SwiftData

@Model
class FuelRecord {
    var id: UUID
    var date: Date
    var mileage: Double
    var liters: Double
    var fuelType: String
    
    init(id: UUID = UUID(), date: Date = Date(), mileage: Double, liters: Double, fuelType: String) {
        self.id = id
        self.date = date
        self.mileage = mileage
        self.liters = liters
        self.fuelType = fuelType
    }
    
    var kmPerLiter: Double {
        guard liters > 0 else { return 0.0 }
        return mileage / liters
    }
}

@Model
class MaintenanceRecord {
    var id: UUID
    var date: Date
    var mileage: Double
    var item: String
    var cost: Double
    
    init(id: UUID = UUID(), date: Date = Date(), mileage: Double, item: String, cost: Double) {
        self.id = id
        self.date = date
        self.mileage = mileage
        self.item = item
        self.cost = cost
    }
}

// 🛠️ 升級裝備模型，支援晴雨天分類與打勾狀態
@Model
class EquipmentItem {
    var id: UUID
    var name: String
    var isRainyDay: Bool  // true = 雨天裝備, false = 晴天裝備
    var isChecked: Bool   // 用於首頁/裝備頁的防呆打勾
    
    init(id: UUID = UUID(), name: String, isRainyDay: Bool, isChecked: Bool = false) {
        self.id = id
        self.name = name
        self.isRainyDay = isRainyDay
        self.isChecked = isChecked
    }
}
