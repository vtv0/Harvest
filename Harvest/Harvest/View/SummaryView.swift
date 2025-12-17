//
//  SummaryView.swift
//  Harvest
//
//  Created by vu the vuong on 13-09-2025.
//

import SwiftUI
import RealmSwift
import UIKit

struct FishSummary {
    let name: String
    let gross: Double
    let tare: Double
    let net: Double
    let price: Double
    let total: Double
    let finalTotal: Double
}

struct SummaryView: View {
    @ObservedResults(FishModel.self) var fishes

    @FocusState private var feeFieldFocused: Bool
    @State private var pdfURL: URL?
//    @State private var isSharing: Bool = false

    var body: some View {
        // --- Tính toán ---
        let summaries: [FishSummary] = fishes.indices.map { idx in
            let fish = fishes[idx]

            guard !fish.weighs.isEmpty else {
                return FishSummary(name: fish.nameFish,
                                   gross: 0,
                                   tare: 0,
                                   net: 0,
                                   price: fish.priceFish,
                                   total: 0,
                                   finalTotal: 0)
            }

            let firstWeigh = fish.weighs.first!
            let propNames = firstWeigh.objectSchema.properties.map { $0.name }

            func findProp(containing substrings: [String]) -> String? {
                for name in propNames {
                    let l = name.lowercased()
                    for sub in substrings {
                        if l.contains(sub) { return name }
                    }
                }
                return nil
            }

            let grossKey = findProp(containing: ["gross", "weight", "kg"])
            let tareKey  = findProp(containing: ["tare", "bi", "bì"])
            let netKey   = findProp(containing: ["net", "tinh", "tịnh"])

            func valueToDouble(_ val: Any?) -> Double? {
                if let d = val as? Double { return d }
                if let n = val as? NSNumber { return n.doubleValue }
                if let s = val as? String {
                    let cleaned = s.replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: ",", with: ".")
                        .replacingOccurrences(of: "₫", with: "")
                    return Double(cleaned)
                }
                return nil
            }

            func sumProp(_ propName: String?) -> Double {
                guard let key = propName else { return 0 }
                return fish.weighs.reduce(0.0) { acc, w in
                    if let d = valueToDouble(w.value(forKey: key)) {
                        return acc + d
                    }
                    return acc
                }
            }

            let gross = sumProp(grossKey)
            let tare  = sumProp(tareKey)
            var net   = sumProp(netKey)
            if net == 0 && (gross != 0 || tare != 0) {
                net = max(0, gross - tare)
            }

            let total = net * fish.priceFish
            let finalTotal = total

            return FishSummary(name: fish.nameFish,
                               gross: gross,
                               tare: tare,
                               net: net,
                               price: fish.priceFish,
                               total: total,
                               finalTotal: finalTotal)
        }

        let totalSum = summaries.reduce(0) { $0 + $1.finalTotal }

        return VStack(spacing: 16) {
            List {
                ForEach(fishes.indices, id: \.self) { idx in
                    let s = summaries[idx]

                    Section(header: Text(s.name).font(.headline)) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Tổng cân:")
                                Spacer()
                                Text(String(format: "%.2f kg", s.gross))
                            }
                            HStack {
                                Text("Tổng bì:")
                                Spacer()
                                Text(String(format: "%.2f kg", s.tare))
                            }
                            HStack {
                                Text("Tịnh:")
                                Spacer()
                                Text(String(format: "%.2f kg", s.net))
                            }
                            HStack {
                                Text("Giá / kg:")
                                Spacer()
                                Text(currencyVND(s.price))
                            }
                            Divider()
                            HStack {
                                Text("Tổng tiền:")
                                Spacer()
                                Text(currencyVND(s.total))
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Tổng cộng").font(.headline)) {
                    HStack {
                        Text("Tổng thu:")
                        Spacer()
                        Text(currencyVND(totalSum))
                            .fontWeight(.bold)
                    }
                }
            }

            Button(action: {
                shareSummaryAsPDF(summaries: summaries, grandTotal: totalSum)
            }) {
                Text("Chia sẻ file PDF")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
            .disabled(fishes.isEmpty)

            
        }
        .navigationTitle("Tổng kết thu hoạch")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Xong") { feeFieldFocused = false }
            }
        }
        
        
        .sheet(isPresented: Binding<Bool>(
            get: { pdfURL != nil },
            set: { if !$0 { pdfURL = nil } }
        )) {
            if let url = pdfURL {
                ActivityView(activityItems: [url])
            }
        }

    }

   
    func shareSummaryAsPDF(summaries: [FishSummary], grandTotal: Double) {
        guard !summaries.isEmpty else { return }

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            context.beginPage()
            var yPos: CGFloat = 36

            // --- Tiêu đề ---
            let title = "TỔNG KẾT THU HOẠCH"
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.black
            ]
            let titleSize = title.size(withAttributes: titleAttrs)
            title.draw(
                in: CGRect(x: (pageRect.width - titleSize.width) / 2,
                           y: yPos,
                           width: titleSize.width,
                           height: titleSize.height),
                withAttributes: titleAttrs
            )
            yPos += titleSize.height + 16

            // --- Nội dung ---
            let textAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]

            for s in summaries {
                // Tên cá
                let nameAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14)
                ]
                s.name.draw(in: CGRect(x: 40, y: yPos, width: 400, height: 18), withAttributes: nameAttrs)
                yPos += 20

                // Dòng chi tiết
                let lines = [
                    String(format: "Tổng cân: %.2f kg", s.gross),
                    String(format: "Tổng bì: %.2f kg", s.tare),
                    String(format: "Tịnh: %.2f kg", s.net),
                    "Giá / kg: \(currencyVND(s.price))",
                    "Tổng tiền: \(currencyVND(s.total))"
                ]

                for line in lines {
                    line.draw(in: CGRect(x: 50, y: yPos, width: 400, height: 16), withAttributes: textAttrs)
                    yPos += 18
                }

                yPos += 10
                if yPos > pageRect.height - 100 {
                    context.beginPage()
                    yPos = 36
                }
            }

            // --- Tổng cộng ---
            let totalAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16)
            ]
            let totalText = "Tổng thu: \(currencyVND(grandTotal))"
            totalText.draw(in: CGRect(x: 40, y: yPos + 10, width: 400, height: 22), withAttributes: totalAttrs)
        }

        // --- Ghi file và mở sheet ---
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("TongKetThuHoach.pdf")

        do {
            try data.write(to: tempURL, options: .atomic)
            DispatchQueue.main.async {
                self.pdfURL = tempURL // hiển thị sheet khi URL được set
            }
        } catch {
            print("❌ Lỗi ghi file PDF: \(error)")
        }
    }

    // --- Helper định dạng tiền ---
    func currencyVND(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}

// --- ActivityView giữ nguyên ---
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

