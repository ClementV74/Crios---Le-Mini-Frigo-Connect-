import SwiftUI

struct HomeView: View {
    @State private var fridgeTemperature = "Chargement..." // Température initiale
    @State private var availableItems = ["🍎 Pomme", "🥚 Oeuf", "🍌 Banane", "🥕 Carotte", "🌽 Maïs", "🍗 Poulet", "🥩 Steak"] // Aliments simulés
    @State private var showDetails = false // Animation pour les détails
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Fridge Temperature with animation and NavigationLink
                VStack {
                    NavigationLink(destination: AnalyseView(temperature: fridgeTemperature)) {
                        ZStack {
                            // Flocons au-dessus du texte
                            SnowfallView()
                                .frame(maxHeight: 150) // Limite la hauteur des flocons
                                .padding([.leading, .trailing]) // Ajoute du padding aux côtés

                            VStack {
                                Text("Température du Frigo")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text(fridgeTemperature)
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.blue)
                                    .padding(.top, 5)
                                    .scaleEffect(showDetails ? 1.1 : 1.0) // Animation
                                    .animation(.easeInOut(duration: 0.5), value: showDetails)
                                    .onAppear {
                                        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                                            showDetails.toggle()
                                        }
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity) // Prend toute la largeur disponible
                        .padding()
                        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.white]), startPoint: .top, endPoint: .bottom))
                        .cornerRadius(15)
                        .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                }
                .onAppear {
                    fetchTemperature()
                }
                
                // Available Items
                NavigationLink(destination: AlimentsView(availableItems: $availableItems)) {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Aliments Disponibles")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // Afficher seulement les 3 premiers aliments
                        ForEach(availableItems.prefix(3), id: \.self) { item in
                            HStack {
                                Text(item)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 3)
                        }
                        
                        // Indicateur "..."
                        if availableItems.count > 3 {
                            Text("...")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 3)
                        }
                    }
                    .frame(maxWidth: .infinity) // Prend toute la largeur disponible
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.2), Color.white]), startPoint: .top, endPoint: .bottom))
                    .cornerRadius(15)
                    .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                
                // Recipe Creation Section
                NavigationLink(destination: RecipeView(availableItems: availableItems)) {
                    VStack {
                        Text("Créer une Recette")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                ZStack {
                                    // Flamme animée
                                    FlameAnimation()
                                        .opacity(0.8)
                                    Capsule().fill(Color.red)
                                }
                            )
                            .padding(.top, 5)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.2), Color.white]), startPoint: .top, endPoint: .bottom))
                .cornerRadius(15)
                .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Centre de Contrôle")
            .background(Color(UIColor.systemGroupedBackground)) // Fond de groupe
            .edgesIgnoringSafeArea(.bottom) // Pour s'assurer que l'interface utilise tout l'espace
        }
        .accentColor(.blue) // Couleur principale des boutons et liens
    }
    
    func fetchTemperature() {
        guard let url = URL(string: "https://vabre.ch/crios/getTemp.php") else {
            self.fridgeTemperature = "Erreur URL"
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.fridgeTemperature = "Erreur réseau"
                }
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(TemperatureResponse.self, from: data)
                DispatchQueue.main.async {
                    self.fridgeTemperature = "\(decodedResponse.data.temperature)°C"
                }
            } catch {
                DispatchQueue.main.async {
                    self.fridgeTemperature = "Erreur données"
                }
            }
        }.resume()
    }
}

// Struct to decode the API response
struct TemperatureResponse: Decodable {
    struct Data: Decodable {
        let temperature: Int
    }
    let status: String
    let data: Data
}

// SnowfallView, Snowflake, FlameAnimation, and previews remain unchanged.
struct SnowfallView: View {
    let numberOfFlakes = 20 // Nombre de flocons réduit pour l'optimisation
    
    var body: some View {
        ZStack {
            ForEach(0..<numberOfFlakes, id: \.self) { _ in
                Snowflake()
                    .frame(width: CGFloat.random(in: 10...25), height: CGFloat.random(in: 10...25)) // Taille des flocons
                    .transition(.opacity) // Transition pour un effet fluide
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Permet aux flocons de sortir de la zone
    }
}

struct Snowflake: View {
    @State private var offset = CGSize(width: 0, height: -100)
    @State private var opacity = Double.random(in: 0.5...1.0)
    
    var body: some View {
        Image(systemName: "snowflake")
            .resizable()
            .scaledToFit()
            .foregroundColor(.white)
            .opacity(opacity)
            .offset(offset)
            .onAppear {
                let randomX = CGFloat.random(in: -250...250)
                let randomDuration = Double.random(in: 7...12)

                withAnimation(
                    Animation.linear(duration: randomDuration)
                        .repeatForever(autoreverses: false)
                ) {
                    offset = CGSize(width: randomX, height: 600)
                }
            }
    }
}

// Flame Animation
struct FlameAnimation: View {
    @State private var scale = 1.0
    @State private var opacity = 1.0
    
    var body: some View {
        Circle()
            .fill(LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange, Color.yellow]), startPoint: .top, endPoint: .bottom))
            .scaleEffect(scale)
            .opacity(opacity)
            .frame(width: 200, height: 200)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    scale = 1.2
                    opacity = 0.6
                }
            }
    }
}

// Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .preferredColorScheme(.light) // Tester avec mode clair
    }
}
