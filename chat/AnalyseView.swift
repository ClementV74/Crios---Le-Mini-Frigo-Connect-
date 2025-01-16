import SwiftUI

struct AnalyseView: View {
    @StateObject private var api = APITemp() // Instance de la classe qui gère l'API
    let temperature: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Analyse de la Température")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if api.dataPoints.isEmpty {
                Text("Chargement des données...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else {
                TemperatureChart(dataPoints: api.dataPoints)
                    .frame(height: 250) // Ajuste la taille du graphique
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            api.fetchData() // Charger les données de l'API au démarrage
        }
    }
}

// Sous-vue pour le graphique
struct TemperatureChart: View {
    let dataPoints: [TemperatureData]
    
    var body: some View {
        GeometryReader { geometry in
            let maxTemp = dataPoints.map { $0.temperature }.max() ?? 1
            let minTemp = dataPoints.map { $0.temperature }.min() ?? 0
            let tempRange = maxTemp - minTemp
            let adjustedMaxTemp = maxTemp + 1 // Ajouter 1 au-dessus du max
            let adjustedMinTemp = minTemp - 1 // Ajouter 1 en dessous du min
            let width = geometry.size.width
            let height = geometry.size.height
            let stepX = width / CGFloat(dataPoints.count - 1)
            let adjustedTempRange = adjustedMaxTemp - adjustedMinTemp
            
            // Ajout d'un ScrollView horizontal
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack {
                    // Tracer la ligne du graphique
                    Path { path in
                        for (index, data) in dataPoints.enumerated() {
                            let x = CGFloat(index) * stepX + 20 // Décalage de la courbe vers la droite
                            let y = height - ((CGFloat(data.temperature) - CGFloat(adjustedMinTemp)) / CGFloat(adjustedTempRange)) * height
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]), startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 2, lineJoin: .round)
                    )
                    
                    // Ajouter les points sur le graphique
                    ForEach(0..<dataPoints.count, id: \.self) { index in
                        let x = CGFloat(index) * stepX + 20 // Décalage de chaque point
                        let y = height - ((CGFloat(dataPoints[index].temperature) - CGFloat(adjustedMinTemp)) / CGFloat(adjustedTempRange)) * height
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                    
                    // Axe des X (Heures)
                    VStack {
                        Spacer()
                        HStack {
                            ForEach(0..<dataPoints.count, id: \.self) { index in
                                Text(formatTimestampToHour(dataPoints[index].timestamp))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: stepX, alignment: .center)
                            }
                        }
                        .padding(.top, 10)
                    }
                }
            }
            
            // Axe des Y (Température)
            VStack {
                ForEach(0..<6) { i in // Affichage de 6 graduations pour l'axe Y
                    Text("\(Int(adjustedMaxTemp - (adjustedTempRange / 5 * CGFloat(i))))°")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(height: height / 5, alignment: .top)
                }
            }
            .frame(width: 30) // Décale l'axe Y à gauche
        }
    }
    
    // Fonction pour formater le timestamp en heure
    private func formatTimestampToHour(_ timestamp: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = formatter.date(from: timestamp) {
            formatter.dateFormat = "HH:mm" // Format de l'heure
            return formatter.string(from: date)
        } else {
            return ""
        }
    }
}
