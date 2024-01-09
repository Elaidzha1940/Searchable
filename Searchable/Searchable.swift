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
    @Published var searchScope: SearchScopeOption = .all
    @Published private(set) var allSearchScopes: [SearchScopeOption] = []
    
    let manager = RestaurantManager()
    private var cancellabales = Set<AnyCancellable>()
    
    var isSearching: Bool {
        !searchText.isEmpty
    }
    
    var showSearchSuggestions: Bool {
        searchText.count < 3
    }
    
    enum SearchScopeOption: Hashable {
        case all
        case cuisine(option: CuisineOption)
        
        var title: String{
            switch self {
            case .all:
                return "All"
            case .cuisine(option: let option):
                return option.rawValue.capitalized
            }
        }
    }
    
    init() {
        addSubscribers()
    }
    
    private func addSubscribers() {
        $searchText
            .combineLatest($searchScope)
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] (searchText, searchScope) in
                self?.filterRestaurants(searchText: searchText, currentsearchScope: searchScope)
            }
            .store(in: &cancellabales)
    }
    
    private func filterRestaurants(searchText: String, currentsearchScope: SearchScopeOption) {
        guard !searchText.isEmpty else {
            filteredRestaurants = []
            searchScope = .all
            return
        }
        
        // Filter on search scope
        var restaurantsInScope = allRestaurants
        switch currentsearchScope {
        case .all:
            break
        case .cuisine(let option):
            restaurantsInScope = allRestaurants.filter({ $0.cuisine == option })
            //            restaurantsInScope = allRestaurants.filter({ restaurant in
            //                return restaurant.cuisine == option
            //            })
        }
        
        // Filter on search text
        let search = searchText.lowercased()
        filteredRestaurants = restaurantsInScope.filter({ restaurant in
            let titleContainsSearch = restaurant.title.lowercased().contains(search)
            let cuisineContainsSearch = restaurant.cuisine.rawValue.lowercased().contains(search)
            return titleContainsSearch || cuisineContainsSearch
        })
    }
    
    func loadRestaurants() async {
        do {
            allRestaurants = try await manager.getAllRestaurants()
            
            let allCuisines = Set(allRestaurants.map { $0.cuisine })
            allSearchScopes = [.all] + allCuisines.map({ SearchScopeOption.cuisine(option: $0) })
            
            //            allSearchScopes = [.all] + allCuisines.map({ option in
            //                SearchScopeOption.cuisine(option: option)
            //            })
            
        } catch {
            print(error)
        }
    }
    
    func getSearchSuggestions() -> [String] {
        guard showSearchSuggestions else {
            return []
        }
        
        var suggestions: [String] = []
        
        let search = searchText.lowercased()
        if search.contains("ra") {
            suggestions.append("Ramen")
        }
        if search.contains("sy") {
            suggestions.append("Syrniki")
        }
        if search.contains("la") {
            suggestions.append("Lasania")
        }
        if search.contains("kh") {
            suggestions.append("Khinkali")
        }
        suggestions.append("Food")
        suggestions.append("Grocery")
        
        suggestions.append(CuisineOption.georgian.rawValue.capitalized)
        suggestions.append(CuisineOption.italian.rawValue.capitalized)
        suggestions.append(CuisineOption.japanese.rawValue.capitalized)
        suggestions.append(CuisineOption.russian.rawValue.capitalized)
        
        return suggestions
    }
    
    func getRestaurantSuggestions() -> [Restaurant] {
        guard showSearchSuggestions else {
            return []
        }
        
        var suggestions: [Restaurant] = []
        
        let search = searchText.lowercased()
        
        if search.contains("fre") {
            suggestions.append(contentsOf: allRestaurants.filter({ $0.cuisine == .french }))
        }
        if search.contains("jap") {
            suggestions.append(contentsOf: allRestaurants.filter({ $0.cuisine == .japanese }))
        }
        if search.contains("geo") {
            suggestions.append(contentsOf: allRestaurants.filter({ $0.cuisine == .georgian }))
        }
        
        return suggestions
    }
}

struct Searchable: View {
    @StateObject private var viewModel = SearchableViewModel()
    
    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(viewModel.isSearching ? viewModel.filteredRestaurants : viewModel.allRestaurants) { restaurant in
                    NavigationLink(value: restaurant) {
                        restaurantRow(restaurant: restaurant)
                    }
                }
            }
            .padding()
        }
        .searchable(text: $viewModel.searchText, placement: .automatic, prompt: "Search restaurants...")
        .searchScopes($viewModel.searchScope, scopes: {
            ForEach(viewModel.allSearchScopes, id: \.self) { scope in
                Text(scope.title)
                    .tag(scope)
            }
        })
        .searchSuggestions {
            ForEach(viewModel.getSearchSuggestions(), id: \.self) { suggestion in
                Text(suggestion)
                    .searchCompletion(suggestion)
            }
            
            ForEach(viewModel.getRestaurantSuggestions(), id: \.self) { suggestion in
                NavigationLink(value: suggestion) {
                    Text(suggestion.title)
                }
            }
        }
        .navigationTitle("Restaurants")
        .task {
            await viewModel.loadRestaurants()
        }
        .navigationDestination(for: Restaurant.self) { restaurant in
            Text(restaurant.title.uppercased())
        }
    }
    
    private func restaurantRow(restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(restaurant.title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
            Text(restaurant.cuisine.rawValue.capitalized)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.black)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mint.opacity(0.6))
        .cornerRadius(15)
        .tint(.black)
    }
}

#Preview {
    NavigationStack {
        Searchable()
    }
}
