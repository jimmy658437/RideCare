//
//  Vehicle.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/23.
//


import Foundation
import SwiftData

@Model
class Vehicle {
    var name: String
    var currentMileage: Double
    var maintenanceInterval: Double
    var preferredShop: String
    var shopAddress: String

    init(
        name: String = "我的機車",
        currentMileage: Double = 0,
        maintenanceInterval: Double = 1000,
        preferredShop: String = "",
        shopAddress: String = ""
    ) {
        self.name = name
        self.currentMileage = currentMileage
        self.maintenanceInterval = maintenanceInterval
        self.preferredShop = preferredShop
        self.shopAddress = shopAddress
    }
}