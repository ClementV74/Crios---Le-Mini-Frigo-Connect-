import SwiftUI

struct ManageItemsView: View {
    @Binding var availableItems: [String] // Lien avec les aliments de `HomeView`
    @State private var newItem = "" // Stocker le nouvel aliment à ajouter
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Gérer les Aliments")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            // Liste des aliments avec options pour supprimer
            List {
                ForEach(availableItems, id: \.self) { item in
                    HStack {
                        Text(item)
                        Spacer()
                        Button(action: {
                            removeItem(item)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            // Ajouter un nouvel aliment
            HStack {
                TextField("Nouvel aliment", text: $newItem)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)
                
                Button(action: addItem) {
                    Text("Ajouter")
                        .padding()
                        .background(Capsule().fill(Color.blue))
                        .foregroundColor(.white)
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
    
    // Fonction pour ajouter un aliment
    private func addItem() {
        guard !newItem.isEmpty else { return }
        availableItems.append(newItem)
        newItem = ""
    }
    
    // Fonction pour supprimer un aliment
    private func removeItem(_ item: String) {
        availableItems.removeAll { $0 == item }
    }
}

struct ManageItemsView_Previews: PreviewProvider {
    static var previews: some View {
        ManageItemsView(availableItems: .constant(["🍎 Pomme", "🥚 Oeuf", "🍌 Banane"]))
    }
}
