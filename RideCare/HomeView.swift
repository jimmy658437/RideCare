//
//  HomeView.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/23.
//

import PhotosUI  // 引入相簿圖片選擇套件
import Pow  // 引入 Pow 動畫套件
import SwiftData
import SwiftUI

// MARK: - 主題選項結構
struct ThemeOption: Hashable {
    let name: String
    let hex: String
    let color: Color
}

struct HomeView: View {
    @Environment(\.modelContext) private var context
    // 撈取全部裝備以便即時連動

    @Query private var allEquipments: [EquipmentItem]

    //openWeatherAPIKey 輸入
    @State private var showWeatherSheet = false
    @AppStorage("openWeatherAPIKey") private var openWeatherAPIKey: String = ""

    @State private var showSettings = false
    @State private var showUpdateMileage = false
    @State private var showAIAdvisor = false  // 控制 AI 健檢頁面彈出
    @State private var newMileageInput = ""
    @StateObject private var weatherVM = WeatherViewModel()

    // 控制呼吸光暈的狀態
    @State private var isCriticalGlow = false

    // AppStorage 全域快取設定
    @AppStorage("username") private var username = "使用者"
    @AppStorage("profileImageData") private var profileImageData: Data?  // 儲存頭像

    // 🌟 修正 1：確保預設值與設定頁的 "Default" 一致
    @AppStorage("themeColorHex") private var themeColorHex = "Default"  // 全局主題色

    @AppStorage("currentMileage") private var currentMileage = 13500.0
    @AppStorage("maintenanceInterval") private var maintenanceInterval = 1000.0
    @AppStorage("selectedWeatherTab") private var isRainyDaySelection = false  // 晴雨天狀態保存
    @AppStorage("userBirthdayString") private var userBirthdayString = "01-01"
    @AppStorage("homeCity") private var homeCity = "Taipei"

    // 篩選當前天氣選中的裝備
    var currentGearList: [EquipmentItem] {
        allEquipments.filter { $0.isRainyDay == isRainyDaySelection }
    }

    // 🌟 修正 2：將 Hex 字串轉為 SwiftUI Color 以套用主題色
    var primaryThemeColor: Color {
        if themeColorHex == "Default" {
            return AppTheme.primary  // 👈 將這裡改為你的深藍色
        } else {
            return Color(hex: themeColorHex)
        }
    }

    var body: some View {
        ZStack {
            // 🌟 修正：在背景加上微光漸層效果
            AppTheme.background.ignoresSafeArea()
                .overlay(alignment: .topTrailing) {  // 預設放在右上角，若要左上角可改為 .topLeading
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    primaryThemeColor.opacity(0.5), .clear,
                                ],  // 調整 0.5 改變光暈強度
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
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    headerView

                    WeatherCardView(
                        openWeatherAPIKey: $openWeatherAPIKey,
                        homeCity: $homeCity,
                        weatherVM: weatherVM
                    )

                    mergedMileageCard  // 整合里程數與保養進度

                    aiAdvisorButton

                    gearChecklistCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .task {
            weatherVM.city = homeCity
            await weatherVM.fetchWeather()
        }
        // 🌟 新增：監聽天氣描述改變，自動切換晴雨天裝備
        .onChange(of: weatherVM.weatherDescription) { _, newDescription in
            if let desc = newDescription?.lowercased() {
                // 判斷描述中是否包含下雨相關關鍵字
                if desc.contains("雨") || desc.contains("rain")
                    || desc.contains("drizzle") || desc.contains("thunderstorm")
                {
                    withAnimation {
                        isRainyDaySelection = true  // 自動切換雨天裝備
                    }
                } else {
                    withAnimation {
                        isRainyDaySelection = false  // 自動切換晴天裝備
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet().modelContext(context)
        }
        .sheet(isPresented: $showAIAdvisor) {
            AIAdvisorSheet().modelContext(context)  // 彈出 AI 分析視窗
        }
    }

    // MARK: - 畫面組件
    private var headerView: some View {
        HStack {
            // 讀取自訂頭像，若無則顯示預設圖示
            if let imageData = profileImageData,
                let uiImage = UIImage(data: imageData)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable().frame(width: 36, height: 36)
                    .foregroundStyle(AppTheme.onSurfaceVariant)
            }

            Spacer()
            Text("R i d e C a r e").font(.title2).fontWeight(.bold)
                .foregroundStyle(
                    primaryThemeColor
                )
            Spacer()
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill").font(.title2)
                    .foregroundStyle(primaryThemeColor)
            }
        }
        .padding(.top, 10)
    }

    // 里程與保養二合一卡片
    private var mergedMileageCard: some View {
        let currentIntervalProgress = currentMileage.truncatingRemainder(
            dividingBy: maintenanceInterval
        )
        let remainingKm = maintenanceInterval - currentIntervalProgress

        // 狀態判斷
        let isCritical = remainingKm <= 100  // 狀態不佳
        let isWarning = remainingKm <= 300 && remainingKm > 100  // 需注意

        let statusText = isCritical ? "狀態不佳" : (isWarning ? "需注意" : "狀態良好")
        let statusColor: Color =
            isCritical ? .red : (isWarning ? .yellow : .green)
        let backgroundColor: Color =
            isCritical
            ? Color.red.opacity(0.15)
            : (isWarning
                ? Color.yellow.opacity(0.15) : AppTheme.secondaryContainer)

        return VStack(alignment: .leading, spacing: 16) {
            // 頂部：問候語與狀態標籤
            HStack {
                Text("\(greetingTitle)，\(username)").font(.subheadline)
                    .foregroundStyle(AppTheme.onSurfaceVariant)
                Spacer()
                HStack(spacing: 6) {
                    Circle().frame(width: 8, height: 8).foregroundStyle(
                        statusColor
                    )
                    Text(statusText).font(.caption).fontWeight(.medium)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.white.opacity(0.5)).clipShape(Capsule())
            }

            // 總里程與更新按鈕
            HStack(alignment: .center, spacing: 4) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(Int(currentMileage))")
                        .font(
                            .system(size: 48, weight: .bold, design: .rounded)
                        )
                        .foregroundStyle(primaryThemeColor)

                    Text("km").font(.title3).foregroundStyle(
                        AppTheme.onSurfaceVariant
                    ).padding(.bottom, 8)
                }

                Spacer()

                Button(action: { showUpdateMileage = true }) {
                    Text("更新里程")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(primaryThemeColor)
                        .clipShape(Capsule())
                }
            }

            Divider()

            // 保養進度條
            HStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver").foregroundStyle(
                    statusColor
                )
                Text("距下次保養剩餘 \(Int(remainingKm)) km")
                    .font(.subheadline)
                    .foregroundStyle(isCritical ? .red : AppTheme.onSurface)
            }
            ProgressView(
                value: currentIntervalProgress,
                total: maintenanceInterval
            )
            .tint(statusColor)
        }
        .padding(24)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        // Pow 呼吸光暈與動畫特效 (僅在狀態不佳時觸發)
        .shadow(
            color: isCritical
                ? .red.opacity(isCriticalGlow ? 0.8 : 0.0)
                : Color.black.opacity(0.02),
            radius: isCritical ? (isCriticalGlow ? 15 : 5) : 8,
            x: 0,
            y: isCritical ? 0 : 4
        )
        .onAppear {
            if isCritical {
                withAnimation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                ) {
                    isCriticalGlow = true
                }
            }
        }
        .onChange(of: isCritical) { _, newValue in
            if newValue {
                withAnimation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                ) {
                    isCriticalGlow = true
                }
            } else {
                withAnimation { isCriticalGlow = false }
            }
        }
        .changeEffect(.shine, value: isCritical)  // Pow 科技反光動畫
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
                    Image(systemName: "checklist").foregroundStyle(
                        primaryThemeColor
                    )
                    Text("裝備提醒").font(.title3).foregroundStyle(
                        AppTheme.onSurface
                    )
                    Spacer()

                    // 晴雨天切換按鈕
                    HStack(spacing: 0) {
                        Button(action: { isRainyDaySelection = false }) {
                            Image(systemName: "sun.max.fill")
                                .padding(8)
                                .background(
                                    !isRainyDaySelection
                                        ? AppTheme.surfaceContainerLowest
                                        : Color.clear
                                )
                                .foregroundStyle(
                                    !isRainyDaySelection
                                        ? .orange : AppTheme.onSurfaceVariant
                                )
                                .clipShape(Circle())
                        }
                        Button(action: { isRainyDaySelection = true }) {
                            Image(systemName: "cloud.rain.fill")
                                .padding(8)
                                .background(
                                    isRainyDaySelection
                                        ? AppTheme.surfaceContainerLowest
                                        : Color.clear
                                )
                                .foregroundStyle(
                                    isRainyDaySelection
                                        ? .blue : AppTheme.onSurfaceVariant
                                )
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
                            Image(
                                systemName: gear.isChecked
                                    ? "checkmark.circle.fill" : "circle"
                            )
                            .foregroundStyle(
                                gear.isChecked
                                    ? .green : AppTheme.outlineVariant
                            )
                            Text(gear.name)
                                .strikethrough(gear.isChecked)
                                .foregroundStyle(
                                    gear.isChecked
                                        ? AppTheme.onSurfaceVariant
                                        : AppTheme.onSurface
                                )
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
    @AppStorage("profileImageData") private var profileImageData: Data?

    // 🌟 保持與 HomeView 一致的預設值 "Default"
    @AppStorage("themeColorHex") private var themeColorHex = "Default"

    @AppStorage("maintenanceInterval") private var maintenanceInterval = 1000.0
    @AppStorage("userBirthdayString") private var userBirthdayString = "01-01"
    @AppStorage("homeCity") private var homeCity = "Taipei"

    // 機車偏好設定參數
    @AppStorage("gasType") private var gasType = "95 無鉛汽油"
    @AppStorage("gearoilInterval") private var gearoilInterval = 2000.0
    @AppStorage("tireInterval") private var tireInterval = 10000.0
    @AppStorage("airFilterInterval") private var airFilterInterval = 5000.0

    // 🌟 新增：OpenWeather API Key 的儲存狀態
    @AppStorage("openWeatherAPIKey") private var openWeatherAPIKey = ""

    @State private var birthdaySelection = Date()
    @State private var photoItem: PhotosPickerItem?

    let gasOptions = ["92 無鉛汽油", "95 無鉛汽油", "98 無鉛汽油"]

    let themeOptions: [ThemeOption] = [
        ThemeOption(name: "預設", hex: "Default", color: AppTheme.primary),
        ThemeOption(name: "莓果紅", hex: "#D8626E", color: Color(hex: "#D8626E")),
        ThemeOption(name: "湖水綠", hex: "#32A89C", color: Color(hex: "#32A89C")),
        ThemeOption(name: "丁香紫", hex: "#8A6FD1", color: Color(hex: "#8A6FD1")),
        ThemeOption(name: "暖陽橘", hex: "#E88E4A", color: Color(hex: "#E88E4A")),
        ThemeOption(name: "丹寧藍", hex: "#5281B9", color: Color(hex: "#5281B9")),
        ThemeOption(name: "焦糖棕", hex: "#B3805B", color: Color(hex: "#B3805B")),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("個人基本資料") {
                    // 頭像選擇器
                    HStack {
                        Text("大頭貼")
                        Spacer()
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            if let data = profileImageData,
                                let image = UIImage(data: data)
                            {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .onChange(of: photoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?
                                    .loadTransferable(type: Data.self)
                                {
                                    profileImageData = data
                                }
                            }
                        }
                    }

                    TextField("使用者名稱", text: $username)

                    DatePicker(
                        "出生日期",
                        selection: $birthdaySelection,
                        displayedComponents: .date
                    )
                    .onChange(of: birthdaySelection) { _, newValue in
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MM-dd"
                        userBirthdayString = formatter.string(from: newValue)
                    }
                }

                Section("全域主題色") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(themeOptions, id: \.hex) { theme in
                                VStack(spacing: 8) {
                                    Circle()
                                        .fill(theme.color)
                                        .frame(width: 44, height: 44)
                                        .shadow(
                                            color: AppTheme.outlineVariant
                                                .opacity(0.3),
                                            radius: 2,
                                            y: 1
                                        )
                                        .overlay(
                                            Circle()
                                                .strokeBorder(
                                                    themeColorHex == theme.hex
                                                        ? AppTheme
                                                            .outlineVariant
                                                        : Color.clear,
                                                    lineWidth: 2
                                                )
                                                .padding(-4)
                                        )
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .font(
                                                    .system(
                                                        size: 18,
                                                        weight: .bold
                                                    )
                                                )
                                                .foregroundColor(.white)
                                                .shadow(
                                                    color: .black.opacity(0.2),
                                                    radius: 1,
                                                    x: 0,
                                                    y: 1
                                                )
                                                .opacity(
                                                    themeColorHex == theme.hex
                                                        ? 1 : 0
                                                )
                                        )
                                        .onTapGesture {
                                            withAnimation(
                                                .spring(
                                                    response: 0.3,
                                                    dampingFraction: 0.7
                                                )
                                            ) {
                                                themeColorHex = theme.hex
                                            }
                                        }

                                    Text(theme.name)
                                        .font(.caption)
                                        .fontWeight(
                                            themeColorHex == theme.hex
                                                ? .bold : .regular
                                        )
                                        .foregroundStyle(
                                            themeColorHex == theme.hex
                                                ? AppTheme.onSurface
                                                : AppTheme.onSurfaceVariant
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                    }
                }

                Section(
                    header: Text("機車偏好與耗材建議"),
                    footer: Text("設定您的機車偏好，以及各項常見耗材的更換里程，以便提供個人化建議。")
                ) {
                    Picker("偏好汽油種類", selection: $gasType) {
                        ForEach(gasOptions, id: \.self) { gas in
                            Text(gas).tag(gas)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("機油保養區間")
                            Spacer()
                            Text("\(Int(maintenanceInterval)) km").fontWeight(
                                .bold
                            )
                        }
                        Slider(
                            value: $maintenanceInterval,
                            in: 800...3000,
                            step: 100
                        )
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("齒輪油更換區間")
                            Spacer()
                            Text("\(Int(gearoilInterval)) km").fontWeight(.bold)
                        }
                        Slider(
                            value: $gearoilInterval,
                            in: 500...10000,
                            step: 500
                        )
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("輪胎更換區間")
                            Spacer()
                            Text("\(Int(tireInterval)) km").fontWeight(.bold)
                        }
                        Slider(
                            value: $tireInterval,
                            in: 5000...20000,
                            step: 1000
                        )
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("空濾更換區間")
                            Spacer()
                            Text("\(Int(airFilterInterval)) km").fontWeight(
                                .bold
                            )
                        }
                        Slider(
                            value: $airFilterInterval,
                            in: 3000...10000,
                            step: 1000
                        )
                    }
                    .padding(.vertical, 4)
                }

                // 🌟 新增：天氣 API 設定區塊
                Section(
                    header: Text("天氣服務"),
                    footer: Text("刪除 API Key 後，首頁天氣模組將恢復為「尚未設定」的狀態。")
                ) {
                    HStack {
                        Text("OpenWeather API")
                        Spacer()

                        if openWeatherAPIKey.isEmpty {
                            Text("未設定")
                                .foregroundStyle(.secondary)
                        } else {
                            Button(role: .destructive) {
                                // 🌟 點擊後清空 API Key
                                withAnimation {
                                    openWeatherAPIKey = ""
                                }
                            } label: {
                                Text("刪除 API Key")
                            }
                        }
                    }
                }
            }
            .navigationTitle("系統設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM-dd"
                if let date = formatter.date(from: userBirthdayString) {
                    let year = Calendar.current.component(.year, from: Date())
                    var components = Calendar.current.dateComponents(
                        [.month, .day],
                        from: date
                    )
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
