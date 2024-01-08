//  /*
//
//  Project: Searchable
//  File: Searchable.swift
//  Created by: Elaidzha Shchukin
//  Date: 08.01.2024
//
//  */

import SwiftUI
import Combine

struct Restaurant: Identifiable, Hashable {
    let id: String
    let title: String
    let cuisine: CuisineOption
}

enum CuisineOption: String {
    case russian, georgian, italian, french, japanese
}

final class RestaurantManager {
    
    func getAllRestaurants() async throws -> [Restaurant] {
        [
            Restaurant(id: "1", title: "Khinkali", cuisine: .georgian),
            Restaurant(id: "2", title: "Syrniki", cuisine: .russian),
            Restaurant(id: "3", title: "Lasania", cuisine: .italian),
            Restaurant(id: "4", title: "Ratatouille", cuisine: .french),
            Restaurant(id: "5", title: "Ramen", cuisine: .japanese),
        ]
    }
}

@MainActor
final class SearchableViewModel: ObservableObject {
    @Published private(set) var allRestaurants: [Restaurant] = []
    @Published private(set) var filteredRestaurants: [Restaurant] = []
    @Published var searchText: String = ""
    let manager = RestaurantManager()
    private var cancellabales = Set<AnyCancellable>()
    
    var isSearching: Bool {
        !searchText.isEmpty
    }
    
    init() {
        addSubscribers()
    }
    
    private func addSubscribers() {
        $searchText.debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                self?.filterRestaurants(searchText: searchText)
            }
            .store(in: &cancellabales)
    }
    
    private func filterRestaurants(searchText: String) {
        guard !searchText.isEmpty else {
            filteredRestaurants = []
            return
        }
        let search = searchText.lowercased()
        filteredRestaurants = allRestaurants.filter({ restaurant in
            let titleContainsSearch = restaurant.title.lowercased().contains(search)
            let cuisineContainsSearch = restaurant.cuisine.rawValue.lowercased().contains(search)
            return titleContainsSearch || cuisineContainsSearch
        })
    }
    
    func loadRestaurants() async {
        do {
            allRestaurants = try await manager.getAllRestaurants()
        } catch {
            print(error)
        }
    }
}

struct Searchable: View {
    @StateObject private var viewModel = SearchableViewModel()
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(viewModel.isSearching ? viewModel.filteredRestaurants : viewModel.allRestaurants) { restaurant in
                    restaurantRow(restaurant: restaurant)
                }
            }
            .padding()
        }
        .searchable(text: $viewModel.searchText, placement: .automatic, prompt: "Search restaurants...")
        .navigationTitle("Restaurants")
        .task {
            await viewModel.loadRestaurants()
        }
    }
    
    private func restaurantRow(restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(restaurant.title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(restaurant.cuisine.rawValue.capitalized)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mint.opacity(0.6))
        .cornerRadius(15)
    }
}

#Preview {
    NavigationStack {
        Searchable()
    }
}
