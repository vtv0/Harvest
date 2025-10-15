//
//  FishEditView.swift
//  Harvest
//
//  Created by vu the vuong on 29-07-2025.
//

import SwiftUI
import RealmSwift
import PhotosUI

private enum Field: Hashable {
    case name
    case price
}

struct FishEditView: View {
    @Environment(\.dismiss) private var dismiss
    private var fishID: String?
    var viewModel: FishViewModel?
    
    @State private var name: String = ""
    @State private var price: String = ""
    @State private var imageData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @FocusState private var focusedField: Field?

    init(viewModel: FishViewModel? = nil) {
        self.fishID = nil
        self.viewModel = viewModel
    }
    
    init(fishID: String) {
        self.fishID = fishID
        self.viewModel = nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Thông tin cá") {
                    TextField("Tên cá", text: $name)
                        .focused($focusedField, equals: .name)
                    TextField("Giá", text: $price)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .price)
                }
                
                Section(header: Text("Hình ảnh")) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .cornerRadius(8)
                    } else {
                        // placeholder nếu muốn
                        Rectangle()
                            .frame(height: 150)
                            .foregroundStyle(.secondary)
                            .cornerRadius(8)
                    }
                    
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Chọn ảnh", systemImage: "photo")
                    }
                    .onChange(of: selectedItem) { oldItem, newItem in
                        Task {
                            guard let item = newItem else { return }
                            // load data từ item
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let uiImg = UIImage(data: data) {
                                await MainActor.run {
                                    self.selectedImage = uiImg
                                    self.imageData = data
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                // nếu đang sửa, load dữ liệu từ Realm và chuyển Data -> UIImage để hiển thị
                if let fishID = fishID,
                   let realm = try? Realm(),
                   let liveFish = realm.object(ofType: FishModel.self, forPrimaryKey: fishID) {
                    name = liveFish.nameFish
                    price = String(liveFish.priceFish)
                    if let data = liveFish.imageFish, let uiImg = UIImage(data: data) {
                        imageData = data
                        selectedImage = uiImg   // quan trọng — gán để hiển thị ảnh khi sửa
                    } else {
                        imageData = nil
                        selectedImage = nil
                    }
                }
            }
            .navigationTitle(fishID == nil ? "Thêm biểu cá" : "Sửa biểu cá")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        let priceVal = Double(price) ?? 0
                        if let vm = viewModel {
                            vm.addFish(name: name, price: priceVal, imageData: imageData)
                        } else if let fishID = fishID, let realm = try? Realm(),
                                  let liveFish = realm.object(ofType: FishModel.self, forPrimaryKey: fishID) {
                            try? realm.write {
                                liveFish.nameFish = name
                                liveFish.priceFish = priceVal
                                liveFish.imageFish = imageData
                            }
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
            }
        }
    }
}
