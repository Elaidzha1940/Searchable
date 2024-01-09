How to use Searchable, Search Suggestions, Search Scopes in SwiftUI.
====================================================================

https://github.com/Elaidzha1940/Searchable/assets/64445918/98e05231-807d-4862-ad88-d738ff296db4

Filter on search text:
----------------------
````````````ruby
        let search = searchText.lowercased()
        filteredRestaurants = restaurantsInScope.filter({ restaurant in
            let titleContainsSearch = restaurant.title.lowercased().contains(search)
            let cuisineContainsSearch = restaurant.cuisine.rawValue.lowercased().contains(search)
            return titleContainsSearch || cuisineContainsSearch
        })
    }
````````````

``````````ruby

import SwiftUI
import Combine

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

``````````

https://github.com/Elaidzha1940/Searchable/assets/64445918/4ea802b9-85d4-40c6-bcad-ff9dc2a1fa1b


Filter on search scope:
-----------------------
`````````ruby
        var restaurantsInScope = allRestaurants
        switch currentsearchScope {
        case .all:
            break
        case .cuisine(let option):
            restaurantsInScope = allRestaurants.filter({ $0.cuisine == option })
        }
`````````

`````````ruby
 .searchScopes($viewModel.searchScope, scopes: {
            ForEach(viewModel.allSearchScopes, id: \.self) { scope in
                Text(scope.title)
                    .tag(scope)
            }
        })
`````````

https://github.com/Elaidzha1940/Searchable/assets/64445918/5028f91c-367c-4c67-b7dd-93788c0f8a48

`````````ruby

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

`````````

`````````ruby
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
`````````

