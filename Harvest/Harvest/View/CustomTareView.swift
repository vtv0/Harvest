//
//  CustomTareView.swift
//  Harvest
//
//  Created by vu the vuong on 12-09-2025.
//

import SwiftUI
import RealmSwift

struct CustomTareView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tareValue: [String: Double] = [:]
    
    // Lấy danh sách cá từ Realm
    @ObservedResults(FishModel.self, sortDescriptor: SortDescriptor(keyPath: "priceFish", ascending: false))
    var fishes

    var body: some View {
        NavigationView {
            Form {
                if fishes.isEmpty {
                    Text("Chưa có loại cá nào trong danh sách.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(fishes, id: \.idFish) { fish in
                        HStack {
                            Text(fish.nameFish)
                            Spacer()
                            TextField(
                                "Nhập bì (kg)",
                                value: Binding(
                                    get: { tareValue[fish.nameFish] ?? 0 },
                                    set: { tareValue[fish.nameFish] = $0 }
                                ),
                                format: .number
                            )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 150)
                        }
                    }
                }
            }
            .navigationTitle("Chỉnh bì từng loại cá")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") {
                        TareSettings.save(tareValue)
                        dismiss()
                        UIApplication.shared.hideKeyBoard()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
            }
            .onAppear {
                let saved = TareSettings.load()
                for fish in fishes {
                    if let tare = saved[fish.nameFish] {
                        tareValue[fish.nameFish] = tare
                    } else {
                        tareValue[fish.nameFish] = 0
                    }
                }
            }
        }
    }
}

#Preview {
    CustomTareView()
}

