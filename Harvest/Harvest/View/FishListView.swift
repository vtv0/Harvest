//
//  FishListView.swift
//  Harvest
//
//  Created by vu the vuong on 11-06-2025.
//

import SwiftUI
import RealmSwift

enum ActiveSheet: Identifiable {
    case add, edit(FishModel), weigh(FishModel)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let fish): return "edit-\(fish.idFish)"
        case .weigh(let fish): return "weigh-\(fish.idFish)"
        }
    }
}


struct FishListView: View {
    @ObservedResults(FishModel.self, sortDescriptor: SortDescriptor(keyPath: "priceFish", ascending: false))
    var fishes: Results<FishModel>

    @State private var activeSheet: ActiveSheet?
    @State private var fishToDelete: FishModel?
    @State private var showingDeleteAlert = false
    
    @State private var showTareSheet = false // tùy chỉnh kg bì
    @State private var showSummaryView = false
    var body: some View {
        NavigationView {
            List { // thay cho tableView
                ForEach(fishes) { fish in
                    rowView(for: fish)
                }
                
                .onDelete(perform: askDelete)
            }
            .navigationTitle("Biểu cá")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        activeSheet = .add
                    } label: {
                        Image(systemName: "plus")
                        Text("Thêm loại cá")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showTareSheet = true
                    } label: {
                        Image(systemName: "scalemass")
                        Text("Bì") // icon cân nặng
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSummaryView = true
                    } label: {
                        Image("ic_summary")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                }
                
            }
            // FishListView.swift
            .sheet(item: $activeSheet) { item in
                switch item {
                case .add:
                    FishEditView(viewModel: FishViewModel())
                case .edit(let fish):
                    FishEditView(fishID: fish.idFish)   // 👉 truyền id
                case .weigh(let fish):
                    FishWeighView(fish: fish)
                }
            }
            
            // sheet chỉnh bì
            .sheet(isPresented: $showTareSheet) {
                CustomTareView()
                    .presentationDetents([.fraction(0.5)])
            }
            
            
            // xóa cá
            .alert("Xóa cá?", isPresented: $showingDeleteAlert, presenting: fishToDelete) { fish in
                Button("Hủy", role: .cancel) {}
                Button("Xóa", role: .destructive) {
                    deleteFish(fish)
                }
            } message: { fish in
                Text("Bạn có chắc muốn xóa \(fish.nameFish) và tất cả dữ liệu cân liên quan?")
            }
            
            .sheet(isPresented: $showSummaryView) {
                SummaryView()
            }
            
        }
    }
    
    private func rowView(for fish: FishModel) -> some View {
        HStack {
            NavigationLink(destination: FishStatisticsView(fish: fish)) {
                HStack {
                    fishThumbnail(fish)
                    fishInfo(fish)
                }
            }
            Spacer(minLength: 10)
            editFish(for: fish)
            Spacer()
            plusButton(for: fish)
        }
        .buttonStyle(BorderlessButtonStyle()) // tách button với row khi click
    }

    
    private func fishThumbnail(_ fish: FishModel) -> some View {
        Group {
            if let data = fish.imageFish,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .frame(width: 60, height: 60)
        .cornerRadius(8)
    }
    
    private func fishInfo(_ fish: FishModel) -> some View {
        VStack(alignment: .leading) {
            Text(fish.nameFish)
                .font(.headline)
            Text(String(format: "%.2f VND", fish.priceFish))
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    func editFish(for fish: FishModel) -> some View {
        Button {
            activeSheet = .edit(fish)
        } label: {
            Image("ic_pen")
                .imageScale(.large)
        }
    }
    
    private func plusButton(for fish: FishModel) -> some View {
        Button {
            activeSheet = .weigh(fish)

        } label: {
            Image(systemName: "plus.circle")
                .imageScale(.large)
        }
    }
    
    private func askDelete(at offsets: IndexSet) {
        if let index = offsets.first {
            fishToDelete = fishes[index]
            showingDeleteAlert = true
        }
    }
    
    private func deleteFish(_ fish: FishModel) {
        guard let realm = try? Realm() else { return }
        if let liveFish = realm.object(ofType: FishModel.self, forPrimaryKey: fish.idFish) {
            try? realm.write {
                realm.delete(liveFish.weighs)
                realm.delete(liveFish)
            }
        }
        fishToDelete = nil
    }

}
