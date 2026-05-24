//
//  AddFuelSheet.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/24.
//


import SwiftUI
import SwiftData

struct AddFuelSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var mileage = ""
    @State private var liters = ""
    @State private var fuelType = "95"

    var body: some View {
        NavigationStack {
            Form {
                Section("加油詳情") {
                    TextField("當前單趟/總里程數 (km)", text: $mileage).keyboardType(.decimalPad)
                    TextField("加油公升數 (L)", text: $liters).keyboardType(.decimalPad)
                    Picker("汽油種類", selection: $fuelType) {
                        Text("92").tag("92")
                        Text("95").tag("95")
                        Text("98").tag("98")
                    }.pickerStyle(.segmented)
                }
            }
            .navigationTitle("新增加油紀錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let newRecord = FuelRecord(
                            mileage: Double(mileage) ?? 0,
                            liters: Double(liters) ?? 0,
                            fuelType: fuelType
                        )
                        context.insert(newRecord)
                        try? context.save() // 修正：強制存檔
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct AddMaintenanceSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var mileage = ""
    @State private var item = ""
    @State private var cost = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("保養詳情") {
                    TextField("當前里程數 (km)", text: $mileage).keyboardType(.decimalPad)
                    TextField("保養項目 (例: 機油、齒輪油)", text: $item)
                    TextField("花費金額 (NT$)", text: $cost).keyboardType(.numberPad)
                }
            }
            .navigationTitle("新增保養紀錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        let newRecord = MaintenanceRecord(
                            mileage: Double(mileage) ?? 0,
                            item: item,
                            cost: Double(cost) ?? 0
                        )
                        context.insert(newRecord)
                        try? context.save() // 修正：強制存檔
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
