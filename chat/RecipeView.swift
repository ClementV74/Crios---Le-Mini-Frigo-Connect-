import SwiftUI
import Foundation

struct RecipeView: View {
    @State private var selectedItems: [String] = []
    @State private var recipeText: String = ""
    @State private var isLoading: Bool = false
    var availableItems: [String]
    
    let apiURL = "http://pc.local:11434/api/chat" // Remplacez par l'URL de votre API
    
    // Ajouter l'Environment pour gérer la navigation
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                // Animation de chargement
                VStack {
                    ProgressView("Génération de la recette...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .padding()
                    Text("Veuillez patienter")
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
            } else if !recipeText.isEmpty {
                // Afficher la recette générée
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        formatText(recipeText)
                            .font(.title2)
                            .fontWeight(.medium)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1)))
                            .foregroundColor(.blue)
                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
                        
                        Button(action: {
                            // Réinitialiser la vue
                            selectedItems.removeAll()
                            recipeText = ""
                            
                            // Revenir à la vue précédente
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Retour à la sélection")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .padding(.top)
                    }
                }
                .padding()
            } else {
                // Liste des éléments disponibles
                List(availableItems, id: \.self) { item in
                    HStack {
                        Text(item)
                            .foregroundColor(selectedItems.contains(item) ? .blue : .primary)
                            .font(.title3)
                            .padding(.vertical, 10)
                        
                        Spacer()
                        
                        if selectedItems.contains(item) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal)
                    .background(selectedItems.contains(item) ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(10)
                    .onTapGesture {
                        if selectedItems.contains(item) {
                            selectedItems.removeAll { $0 == item }
                        } else {
                            selectedItems.append(item)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .padding(.horizontal)
                
                Button(action: fetchRecipe) {
                    Text("Générer Recette")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedItems.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(8)
                }
                .padding(.top)
                .disabled(selectedItems.isEmpty)
            }
            
            Spacer()
        }
        .navigationTitle("Sélection de Recette")
        .navigationBarBackButtonHidden(true)  // Masque le bouton de retour par défaut
        .navigationBarItems(leading: Button(action: {
            // Action pour revenir à la vue précédente
            presentationMode.wrappedValue.dismiss() // Revenir à la vue précédente
        }) {
            Text("Retour")
                .foregroundColor(.blue)  // Changer la couleur du texte ici
                .font(.headline)
        })
        .padding()
    }
    
    private func fetchRecipe() {
        guard !selectedItems.isEmpty else { return }
        
        isLoading = true
        let prompt = "Je veux une idée de recette très courte avec les éléments suivants : \(selectedItems.joined(separator: ", "))"
        
        let messageToSend = [
            "model": "llama3.1:latest",
            "messages": [["role": "user", "content": prompt]],
            "stream": false
        ] as [String: Any]
        
        guard let url = URL(string: apiURL) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: messageToSend, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Error fetching response: \(error)")
                isLoading = false
                return
            }
            guard let data = data else {
                isLoading = false
                return
            }
            
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                DispatchQueue.main.async {
                    recipeText = response.message.content
                    isLoading = false
                }
            } catch {
                print("Error decoding response: \(error)")
                isLoading = false
            }
        }
        .resume()
    }
    
    private func formatText(_ text: String) -> Text {
        // Formater le texte pour mettre en gras tout ce qui est entre **
        let parts = text.split(separator: "**")
        var formattedText = Text("")
        
        for (index, part) in parts.enumerated() {
            if index % 2 == 1 { // Si c'est un texte entre **
                formattedText = formattedText + Text(part).bold()
            } else {
                formattedText = formattedText + Text(part)
            }
        }
        
        return formattedText
    }
}

struct RecipeView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeView(availableItems: [
            "🍎 Pomme",
            "🥚 Oeuf",
            "🍌 Banane",
            "🥕 Carotte",
            "🌽 Maïs",
            "🍗 Poulet",
            "🥩 Steak"
        ])
    }
}

struct APIMessage: Codable {
    let content: String
}
