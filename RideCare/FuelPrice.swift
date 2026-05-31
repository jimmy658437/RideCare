//
//  FuelPrice.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/31.
//


import Foundation
import Observation

struct FuelPrice: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let price: Double
}

@Observable
class FuelPriceService: NSObject, XMLParserDelegate {
    var prices: [FuelPrice] = []
    var isLoading = false
    var errorMessage: String? = nil
    
    // XML 解析用暫存變數
    private var currentElement = ""
    private var currentName = ""
    private var currentPrice = ""
    private var tempPrices: [FuelPrice] = []
    
    func fetchPrices() async {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://vipmbr.cpc.com.tw/CPCSTN/ListPriceWebService.asmx/getCPCMainProdListPrice_XML") else {
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let parser = XMLParser(data: data)
            parser.delegate = self
            
            tempPrices = []
            if parser.parse() {
                // 過濾出我們需要的 92, 95, 98 汽油，並依照 92, 95, 98 排序
                DispatchQueue.main.async {
                    self.prices = self.tempPrices.filter {
                        $0.name.contains("92") ||
                        $0.name.contains("95") ||
                        $0.name.contains("98")
                    }.sorted { $0.name < $1.name }
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "資料解析失敗"
                    self.isLoading = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "網路連線錯誤"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - XMLParserDelegate
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "Table" {
            currentName = ""
            currentPrice = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if currentElement == "產品名稱" {
            currentName += trimmed
        } else if currentElement == "參考牌價_金額" {
            currentPrice += trimmed
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Table" {
            if let price = Double(currentPrice) {
                tempPrices.append(FuelPrice(name: currentName, price: price))
            }
        }
    }
}