//
//  WeatherCardView.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/6/4.
//

import SwiftUI

struct WeatherCardView: View {
    // 透過 Binding 或 ObservedObject 從 HomeView 接收這些狀態
    @Binding var openWeatherAPIKey: String
    @Binding var homeCity: String
    @ObservedObject var weatherVM: WeatherViewModel  // ⚠️ 替換成你實際的 ViewModel 類別名稱
    @State private var tempAPIKey = ""  // 🌟 用來暫存使用者輸入的 API Key，避免打一個字畫面就跳轉

    // 控制天氣詳細表單的狀態，現在變成元件內部的私有狀態
    @State private var showWeatherSheet = false

    // 🌟 新增：用來快取最後一次載入成功的天氣圖示
    @State private var cachedWeatherImage: Image?

    var body: some View {
        VStack {
            if openWeatherAPIKey.isEmpty {
                ContentUnavailableView(
                    "尚未設定 API Key",
                    systemImage: "key.fill",
                    description: Text("點擊此處開啟設定")
                )
            } else {
                HStack(alignment: .center, spacing: 16) {
                    // 左側：Icon 與 溫度
                    VStack(alignment: .leading, spacing: 4) {
                        if let icon = weatherVM.weatherIcon {
                            AsyncImage(
                                url: URL(
                                    string:
                                        "https://openweathermap.org/img/wn/\(icon)@4x.png"
                                )
                            ) { phase in
                                // 根據圖片載入的狀態 (phase) 來決定畫面
                                if let image = phase.image {
                                    // 1. 成功載入新圖片
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .onAppear {
                                            // 🌟 將成功載入的圖儲存起來，下次更新時當作過渡圖
                                            cachedWeatherImage = image
                                        }
                                } else if phase.error != nil {
                                    // 2. 載入失敗時：如果有舊圖就頂著用，沒有就顯示警告圖示
                                    if let cachedWeatherImage {
                                        cachedWeatherImage
                                            .resizable()
                                            .scaledToFit()
                                    } else {
                                        Image(
                                            systemName:
                                                "exclamationmark.triangle"
                                        )
                                        .foregroundStyle(.white)
                                    }
                                } else {
                                    // 3. 正在載入中：如果有舊圖就繼續顯示舊圖，沒有就保持透明空白（不轉圈圈）
                                    if let cachedWeatherImage {
                                        cachedWeatherImage
                                            .resizable()
                                            .scaledToFit()
                                    } else {
                                        Image(systemName: "cloud").resizable()
                                            .scaledToFit().frame(width: 65, height: 65).foregroundStyle(
                                                .white.opacity(0.3)
                                            )
                                    }
                                }
                            }
                            .frame(width: 85, height: 85)
                        }

                        if let temp = weatherVM.temperature {
                            Text("\(String(format: "%.1f", temp))°C")
                                .font(
                                    .system(
                                        size: 36,
                                        weight: .bold,
                                        design: .rounded
                                    )
                                )
                                .foregroundStyle(.white)
                                .shadow(
                                    color: .black.opacity(0.3),
                                    radius: 2,
                                    x: 0,
                                    y: 1
                                )
                        }

                        if let desc = weatherVM.weatherDescription {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                                .shadow(
                                    color: .black.opacity(0.3),
                                    radius: 2,
                                    x: 0,
                                    y: 1
                                )
                        }
                    }

                    Spacer()

                    // 右側：地區、重新整理與簡要資訊
                    VStack(alignment: .trailing, spacing: 12) {
                        HStack(spacing: 12) {
                            Text(getCityNameInChinese(homeCity))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .shadow(
                                    color: .black.opacity(0.3),
                                    radius: 2,
                                    x: 0,
                                    y: 1
                                )

                            Button(action: {
                                Task { await weatherVM.fetchWeather() }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .environment(\.colorScheme, .dark)
                                    .clipShape(Circle())
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "thermometer")
                                    .frame(width: 18, alignment: .center)
                                Text(
                                    "體感：\(String(format: "%.1f", weatherVM.feelsLikeTemperature ?? 0))°C"
                                )
                            }
                            HStack(spacing: 8) {
                                Image(systemName: "humidity")
                                    .frame(width: 18, alignment: .center)
                                Text("濕度：\(weatherVM.humidity ?? 0)%")
                            }
                            HStack(spacing: 8) {
                                Image(systemName: "wind")
                                    .frame(width: 18, alignment: .center)
                                Text(
                                    "風速：\(String(format: "%.1f", weatherVM.windSpeed ?? 0)) m/s"
                                )
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.95))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
        .padding(20)
        .background(getWeatherGradient(icon: weatherVM.weatherIcon ?? ""))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showWeatherSheet = true
        }
        .sheet(isPresented: $showWeatherSheet) {
            weatherSheetContent
        }
    }

    // MARK: - Subviews & Helpers

    private var weatherSheetContent: some View {
        NavigationStack {
            Group {
                if openWeatherAPIKey.isEmpty {
                    // 🌟 補回：API 填寫表單與官網導向功能
                    VStack(spacing: 28) {
                        Spacer()

                        // 頂部圖示與標題
                        VStack(spacing: 12) {
                            Image(systemName: "cloud.sun.bolt.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [.blue, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("啟用天氣服務")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("請輸入您的 OpenWeather API Key\n即可在首頁查看即時天氣與保養建議。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal)

                        // API Key 輸入框
                        VStack(alignment: .leading, spacing: 8) {
                            Text("OpenWeather API Key")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            TextField("請貼上您的 API Key", text: $tempAPIKey)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.none)
                                .submitLabel(.done)
                        }
                        .padding(.horizontal, 24)

                        // 🌟 轉跳 OpenWeather 官網功能
                        Link(
                            destination: URL(
                                string:
                                    "https://home.openweathermap.org/api_keys"
                            )!
                        ) {
                            HStack(spacing: 6) {
                                Text("還沒有金鑰？前往 OpenWeather 官網申請")
                                Image(systemName: "arrow.up.forward.app")
                            }
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                        }

                        // 儲存按鈕
                        Button {
                            let cleanedKey = tempAPIKey.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            if !cleanedKey.isEmpty {
                                withAnimation(.spring()) {
                                    openWeatherAPIKey = cleanedKey
                                }
                                // 儲存後立即抓取最新天氣資料
                                Task {
                                    await weatherVM.fetchWeather()
                                }
                            }
                        } label: {
                            Text("儲存並啟用")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    tempAPIKey.trimmingCharacters(
                                        in: .whitespacesAndNewlines
                                    ).isEmpty
                                        ? Color.gray.opacity(0.5)
                                        : Color.blue
                                )
                                .cornerRadius(12)
                        }
                        .disabled(
                            tempAPIKey.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ).isEmpty
                        )
                        .padding(.horizontal, 24)

                        Spacer()
                    }
                    .padding(.vertical)
                    .navigationTitle("設定天氣 API")
                    .navigationBarTitleDisplayMode(.inline)

                } else {
                    // 天氣資訊顯示介面 (維持不變)
                    ZStack {
                        getWeatherGradient(icon: weatherVM.weatherIcon ?? "")
                            .ignoresSafeArea()

                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 24) {
                                VStack(spacing: 4) {
                                    Menu {
                                        Picker("選擇城市", selection: $homeCity) {
                                            Text("台北").tag("Taipei")
                                            Text("新北").tag("New Taipei")
                                            Text("桃園").tag("Taoyuan")
                                            Text("新竹").tag("Hsinchu")
                                            Text("台中").tag("Taichung")
                                            Text("台南").tag("Tainan")
                                            Text("高雄").tag("Kaohsiung")
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(getCityNameInChinese(homeCity))
                                                .font(
                                                    .system(
                                                        size: 34,
                                                        weight: .bold,
                                                        design: .rounded
                                                    )
                                                )
                                            Image(
                                                systemName:
                                                    "chevron.up.chevron.down"
                                            )
                                            .font(
                                                .system(
                                                    size: 20,
                                                    weight: .bold,
                                                    design: .rounded
                                                )
                                            )
                                            .foregroundStyle(
                                                .white.opacity(0.7)
                                            )
                                        }
                                        .foregroundStyle(.white)
                                        .shadow(
                                            color: .black.opacity(0.25),
                                            radius: 2,
                                            x: 0,
                                            y: 1
                                        )
                                    }
                                    .onChange(of: homeCity) { _, _ in
                                        Task { await weatherVM.fetchWeather() }
                                    }

                                    Text(
                                        "\(String(format: "%.0f", weatherVM.temperature ?? 0))°C"
                                    )
                                    .font(
                                        .system(
                                            size: 80,
                                            weight: .bold,
                                            design: .rounded
                                        )
                                    )
                                    .foregroundStyle(.white)
                                    .shadow(
                                        color: .black.opacity(0.25),
                                        radius: 4,
                                        x: 0,
                                        y: 2
                                    )

                                    Text(weatherVM.weatherDescription ?? "")
                                        .font(
                                            .system(.title3, design: .rounded)
                                        )
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white.opacity(0.9))
                                        .shadow(
                                            color: .black.opacity(0.25),
                                            radius: 2,
                                            x: 0,
                                            y: 1
                                        )
                                }
                                .padding(.top, 40)
                                .padding(.vertical, 20)

                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                    ],
                                    spacing: 16
                                ) {
                                    if let feelsLike = weatherVM
                                        .feelsLikeTemperature
                                    {
                                        WeatherInfoBox(
                                            title: "體感溫度",
                                            value:
                                                "\(String(format: "%.1f", feelsLike))°C",
                                            icon: "thermometer"
                                        )
                                    }
                                    if let humidity = weatherVM.humidity {
                                        WeatherInfoBox(
                                            title: "濕度",
                                            value: "\(humidity)%",
                                            icon: "humidity"
                                        )
                                    }
                                    if let windSpeed = weatherVM.windSpeed {
                                        WeatherInfoBox(
                                            title: "風速",
                                            value:
                                                "\(String(format: "%.1f", windSpeed)) m/s",
                                            icon: "wind"
                                        )
                                    }
                                    if let pressure = weatherVM.pressure {
                                        WeatherInfoBox(
                                            title: "氣壓",
                                            value: "\(pressure) hPa",
                                            icon:
                                                "gauge.with.dots.needle.bottom.100percent"
                                        )
                                    }
                                    if let visibility = weatherVM.visibility {
                                        WeatherInfoBox(
                                            title: "能見度",
                                            value:
                                                "\(String(format: "%.1f", Double(visibility) / 1000.0)) km",
                                            icon: "eye"
                                        )
                                    }
                                    if let cloudiness = weatherVM.cloudiness {
                                        WeatherInfoBox(
                                            title: "雲量",
                                            value: "\(cloudiness)%",
                                            icon: "cloud"
                                        )
                                    }
                                }
                                .padding(.horizontal)

                                HStack(spacing: 16) {
                                    if let sunrise = weatherVM.sunrise {
                                        WeatherInfoBox(
                                            title: "日出時間",
                                            value: sunrise.formatted(
                                                date: .omitted,
                                                time: .shortened
                                            ),
                                            icon: "sunrise.fill"
                                        )
                                    }
                                    if let sunset = weatherVM.sunset {
                                        WeatherInfoBox(
                                            title: "日落時間",
                                            value: sunset.formatted(
                                                date: .omitted,
                                                time: .shortened
                                            ),
                                            icon: "sunset.fill"
                                        )
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 30)
                            }
                        }
                    }
                    .navigationBarHidden(true)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showWeatherSheet = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(
                                openWeatherAPIKey.isEmpty
                                    ? Color.primary.opacity(0.6) : .white
                            )
                            .font(.title2)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            // 🌟 當 Sheet 顯示時，如果本來就有 Key 就帶入暫存（雖然在 isEmpty 為 false 時用不到，但方便未來擴充）
            tempAPIKey = openWeatherAPIKey
        }
    }

    private func getWeatherGradient(icon: String) -> LinearGradient {
        let isDay = icon.contains("d")
        let isRain =
            icon.contains("09") || icon.contains("10") || icon.contains("11")
        let isCloudy =
            icon.contains("02") || icon.contains("03") || icon.contains("04")

        if isRain {
            return LinearGradient(
                colors: [.gray, .blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isCloudy {
            return LinearGradient(
                colors: [.blue.opacity(0.6), .gray.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isDay {
            return LinearGradient(
                colors: [.orange, .blue.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.gray.opacity(0.2), .black.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func getCityNameInChinese(_ city: String) -> String {
        switch city {
        case "Taipei": return "台北"
        case "New Taipei": return "新北"
        case "Taoyuan": return "桃園"
        case "Hsinchu": return "新竹"
        case "Taichung": return "台中"
        case "Tainan": return "台南"
        case "Kaohsiung": return "高雄"
        default: return city
        }
    }
}

// 放在同一個檔案的最下方即可
struct WeatherInfoBox: View {
    var title: String
    var value: String
    var icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(.white.opacity(0.7))

            Text(value)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 110)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
