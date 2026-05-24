//
//  HomeView.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/23.
//


import SwiftUI
import SwiftData
import Pow // 引入 Pow 動畫套件

struct HomeView: View {
    @Environment(\.modelContext) private var context
    // 撈取全部裝備以便即時連動
    @Query private var allEquipments: [EquipmentItem]
    
    @State private var showSettings = false
    @State private var showUpdateMileage = false
    @State private var showAIAdvisor = false // 控制 AI 健檢頁面彈出
    @State private var newMileageInput = ""
    
    // 控制呼吸光暈的狀態
    @State private var isCriticalGlow = false
    
    // AppStorage 全域快取設定
    @AppStorage("username") private var username = "使用者"
    @AppStorage("currentMileage") private var currentMileage = 13500.0
    @AppStorage("maintenanceInterval") private var maintenanceInterval = 1000.0
    @AppStorage("selectedWeatherTab") private var isRainyDaySelection = false // 晴雨天狀態保存
    @AppStorage("userBirthdayString") private var userBirthdayString = "01-01"

    // 篩選當前天氣選中的裝備
    var currentGearList: [EquipmentItem] {
        allEquipments.filter { $0.isRainyDay == isRainyDaySelection }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerView
                    mileageCard
                    maintenanceAlertCard // 包含呼吸燈與閃光特效的保養進度條
                    aiAdvisorButton      // Apple Intelligence 風格的 AI 健檢按鈕
                    gearChecklistCard    // 今日裝備防呆（連動晴雨天）
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) {
            SettingsSheet().modelContext(context)
        }
        .sheet(isPresented: $showAIAdvisor) {
            AIAdvisorSheet().modelContext(context) // 彈出 AI 分析視窗
        }
    }

    // MARK: - 畫面組件
    private var headerView: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable().frame(width: 36, height: 36)
                .foregroundStyle(AppTheme.onSurfaceVariant)
            Spacer()
            Text("RideCare").font(.title2).fontWeight(.bold).foregroundStyle(AppTheme.primary)
            Spacer()
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill").font(.title2).foregroundStyle(AppTheme.primary)
            }
        }
        .padding(.top, 10)
    }

    private var mileageCard: some View {
        FloatingCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("\(greetingTitle)，\(username)").font(.subheadline).foregroundStyle(AppTheme.onSurfaceVariant)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().frame(width: 8, height: 8).foregroundStyle(.green)
                        Text("狀態良好").font(.caption).fontWeight(.medium)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(AppTheme.primaryFixed).clipShape(Capsule())
                }
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(Int(currentMileage))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primary)
                    Text("km").font(.title3).foregroundStyle(AppTheme.onSurfaceVariant).padding(.bottom, 8)
                    
                    Spacer()
                    
                    Button(action: { showUpdateMileage = true }) {
                        Text("更新")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(AppTheme.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.primaryFixed)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .alert("更新目前里程", isPresented: $showUpdateMileage) {
            TextField("輸入最新里程數", text: $newMileageInput)
                .keyboardType(.numberPad)
            Button("取消", role: .cancel) { newMileageInput = "" }
            Button("確定") {
                if let val = Double(newMileageInput) {
                    currentMileage = val
                }
                newMileageInput = ""
            }
        }
    }

    private var maintenanceAlertCard: some View {
        let currentIntervalProgress = currentMileage.truncatingRemainder(dividingBy: maintenanceInterval)
        let remainingKm = maintenanceInterval - currentIntervalProgress
        
        // 判斷是否進入 100 公里內的紅色警戒
        let isCritical = remainingKm <= 100
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Circle().fill(AppTheme.surfaceContainerLowest).frame(width: 48, height: 48)
                    .overlay(Image(systemName: "wrench.and.screwdriver").foregroundStyle(isCritical ? .red : AppTheme.primary))
                Text("保養提醒").font(.title3).foregroundStyle(isCritical ? .red : AppTheme.onSurface)
            }
            
            Text("每 \(Int(maintenanceInterval)) km 保養：剩餘 \(Int(remainingKm)) km 需進行檢修。")
                .font(.subheadline).foregroundStyle(AppTheme.onSurfaceVariant).lineSpacing(4)
            
            ProgressView(value: currentIntervalProgress, total: maintenanceInterval)
                .tint(isCritical ? .red : AppTheme.primary)
        }
        .padding(24)
        .background(AppTheme.secondaryContainer)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        // 🌟 動畫 1：原生循環呼吸光暈 (低於 100 公里自動啟動)
        .shadow(
            color: isCritical ? .red.opacity(isCriticalGlow ? 0.6 : 0.0) : Color.black.opacity(0.02),
            radius: isCritical ? (isCriticalGlow ? 15 : 5) : 8,
            x: 0,
            y: isCritical ? 0 : 4
        )
        .onAppear {
            if isCritical {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isCriticalGlow = true
                }
            }
        }
        .onChange(of: isCritical) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isCriticalGlow = true
                }
            } else {
                withAnimation { isCriticalGlow = false }
            }
        }
        // 🌟 動畫 2：Pow 數值異動特效 (剛好低於 100 時刷一道科技反光)
        .changeEffect(.shine, value: isCritical)
    }

    // 🌟 新增：Apple Intelligence 風格 AI 按鈕
    private var aiAdvisorButton: some View {
        Button(action: { showAIAdvisor = true }) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                Text("AI 車況健檢專區")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding()
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [.purple, .indigo],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }

    private var gearChecklistCard: some View {
        FloatingCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "checklist").foregroundStyle(AppTheme.primary)
                    Text("今日裝備防呆").font(.title3).foregroundStyle(AppTheme.onSurface)
                    Spacer()
                    
                    // 晴雨天切換按鈕
                    HStack(spacing: 0) {
                        Button(action: { isRainyDaySelection = false }) {
                            Image(systemName: "sun.max.fill")
                                .padding(8)
                                .background(!isRainyDaySelection ? AppTheme.surfaceContainerLowest : Color.clear)
                                .foregroundStyle(!isRainyDaySelection ? .orange : AppTheme.onSurfaceVariant)
                                .clipShape(Circle())
                        }
                        Button(action: { isRainyDaySelection = true }) {
                            Image(systemName: "cloud.rain.fill")
                                .padding(8)
                                .background(isRainyDaySelection ? AppTheme.surfaceContainerLowest : Color.clear)
                                .foregroundStyle(isRainyDaySelection ? .blue : AppTheme.onSurfaceVariant)
                                .clipShape(Circle())
                        }
                    }
                    .padding(4)
                    .background(AppTheme.outlineVariant.opacity(0.3))
                    .clipShape(Capsule())
                }
                
                if currentGearList.isEmpty {
                    Text("目前無預設裝備，可前往裝備頁新增。")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(currentGearList) { gear in
                        HStack(spacing: 12) {
                            Image(systemName: gear.isChecked ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(gear.isChecked ? .green : AppTheme.outlineVariant)
                            Text(gear.name)
                                .strikethrough(gear.isChecked)
                                .foregroundStyle(gear.isChecked ? AppTheme.onSurfaceVariant : AppTheme.onSurface)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            gear.isChecked.toggle()
                            try? context.save()
                        }
                    }
                }
            }
        }
    }

    // MARK: - 生日與時間 Greeting 邏輯
    private var greetingTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        let todayString = formatter.string(from: Date())
        
        if todayString == userBirthdayString {
            return "🎂 生日快樂"
        }
        
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 0..<12: return "早安"
        case 12..<18: return "午安"
        default: return "晚安"
        }
    }
}

// MARK: - 系統設定頁面
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("username") private var username = "使用者"
    @AppStorage("maintenanceInterval") private var maintenanceInterval = 1000.0
    @AppStorage("userBirthdayString") private var userBirthdayString = "01-01"
    
    @State private var birthdaySelection = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("個人基本資料") {
                    TextField("使用者名稱", text: $username)
                    
                    DatePicker("出生日期", selection: $birthdaySelection, displayedComponents: .date)
                        .onChange(of: birthdaySelection) { _, newValue in
                            let formatter = DateFormatter()
                            formatter.dateFormat = "MM-dd"
                            userBirthdayString = formatter.string(from: newValue)
                        }
                }
                
                Section(header: Text("車輛保養設定"), footer: Text("設定您的車輛每隔多少公里需要進行大保養（例如機油更換）。")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("保養里程區間")
                            Spacer()
                            Text("\(Int(maintenanceInterval)) km")
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.primary)
                        }
                        
                        Slider(value: $maintenanceInterval, in: 1000...10000, step: 500)
                            .tint(AppTheme.primary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("系統設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("完成") { dismiss() }
            }
            .onAppear {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM-dd"
                if let date = formatter.date(from: userBirthdayString) {
                    let year = Calendar.current.component(.year, from: Date())
                    var components = Calendar.current.dateComponents([.month, .day], from: date)
                    components.year = year
                    if let finalDate = Calendar.current.date(from: components) {
                        birthdaySelection = finalDate
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
