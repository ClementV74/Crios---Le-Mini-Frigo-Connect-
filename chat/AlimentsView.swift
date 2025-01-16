import SwiftUI
import UIKit

struct AlimentsView: View {
    @Binding var availableItems: [String]
    
    @State private var newItem: String = ""
    @State private var isShowingCamera = false
    @State private var capturedImage: UIImage? = nil
    @State private var detectedText: String? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false  // Indicateur de chargement
    
    let apiURL = "http://pc.local:11434/api/chat"  // URL de l'API pour la détection

    var body: some View {
        ZStack {
            // Fond gris couvrant toute la page
            Color.gray.opacity(0.1)
                .edgesIgnoringSafeArea(.all) // Cela assure que le gris couvre toute la zone de la page
            
            // Contenu principal
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Liste Complète des Aliments")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.bottom)
                    
                    // Section pour ajouter un aliment
                    HStack {
                        TextField("Ajouter un aliment", text: $newItem)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(10)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                        
                        Button(action: addItem) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                        }
                        .padding(.trailing, 5)
                        .disabled(newItem.isEmpty)
                    }
                    .padding(.horizontal)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 3)
                    
                    // Scanner les aliments
                    Button(action: {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            isShowingCamera = true
                        } else {
                            alertMessage = "L'appareil photo n'est pas disponible sur cet appareil."
                            showAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("Scanner les aliments")
                                .fontWeight(.medium)
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding(.top, 10)
                    .sheet(isPresented: $isShowingCamera) {
                        CameraView(capturedImage: $capturedImage) { base64String in
                            detectFood(from: base64String)
                        }
                    }
                    
                    // Image capturée
                    if let capturedImage = capturedImage {
                        Image(uiImage: capturedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                            .padding(.top, 10)
                    }
                    
                    // Aliment détecté
                    if let detectedText = detectedText {
                        Text("Aliment détecté : \(detectedText)")
                            .foregroundColor(.green)
                            .font(.body)
                            .padding(.top, 10)
                    }
                    
                    // Liste des aliments sous forme de tableau
                    VStack {
                        ForEach(availableItems, id: \.self) { item in
                            HStack {
                                Text(item)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: {
                                    deleteItem(item: item)
                                }) {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                        .font(.title3)
                                        .padding(.leading, 10)
                                }
                            }
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 3)
                        }
                    }
                    .padding(.top)
                }
                .padding()
                .navigationTitle("Aliments")
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Erreur"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
            
            // Affichage du chargement en overlay
            if isLoading {
                LoadingView()
            }
        }
    }
    
    private func deleteItem(item: String) {
        if let index = availableItems.firstIndex(of: item) {
            availableItems.remove(at: index)
        }
    }
    
    private func addItem() {
        let trimmedItem = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedItem.isEmpty && !availableItems.contains(trimmedItem) {
            availableItems.append(trimmedItem)
        }
        newItem = ""
    }
    
    private func detectFood(from base64String: String) {
        isLoading = true
        
        var messageToSend: [String: Any] = [
            "model": "llama3.2-vision",
            "messages": [["role": "user", "content": "Quel aliment est-ce ? Tu dois juste dire son nom en un seul mot sans rien d'autre et sans point a la fin"]],
            "stream": false
        ]
        
        var messages = messageToSend["messages"] as? [[String: Any]] ?? []
        var userMessageData = messages.first ?? [:]
        userMessageData["images"] = [base64String]
        messages[0] = userMessageData
        messageToSend["messages"] = messages
        
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
                    detectedText = response.message.content
                    if let detectedText = detectedText, !availableItems.contains(detectedText) {
                        availableItems.append(detectedText)
                    }
                    isLoading = false
                }
            } catch {
                print("Error decoding response: \(error)")
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
        .resume()
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            ProgressView("Chargement...")
                .progressViewStyle(CircularProgressViewStyle())
                .padding(20)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 10)
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    var onImageCaptured: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
                if let imageData = image.jpegData(compressionQuality: 0.5) {
                    let base64String = imageData.base64EncodedString()
                    parent.onImageCaptured(base64String)
                }
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}


