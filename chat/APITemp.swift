import Foundation
import Combine

// Modèle des données reçues de l'API
struct TemperatureData: Decodable {
    let id: Int
    let temperature: Double
    let humidity: Int
    let timestamp: String
}

// Classe pour gérer l'API
class APITemp: ObservableObject {
    @Published var dataPoints: [TemperatureData] = []
    
    private let url = URL(string: "https://vabre.ch/crios/api.php")!
    private var cancellable: AnyCancellable?
    
    func fetchData() {
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [TemperatureData].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Erreur lors du chargement des données : \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] data in
                self?.dataPoints = data
            })
    }
}
