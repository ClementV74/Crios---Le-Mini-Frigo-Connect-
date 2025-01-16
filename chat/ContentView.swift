import SwiftUI
import Foundation

struct ContentView: View {
    @State private var userInput = ""
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var selectedImage: UIImage? = nil
    @State private var showingImagePicker = false
    
    let apiURL = "http://pc.local:11434/api/chat"
    
    var body: some View {
        VStack {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .padding(.horizontal)
                                .padding(.top)
                        }
                    }
                    .onChange(of: messages) { oldMessages, newMessages in
                        if let lastMessage = newMessages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .background(Color(UIColor.systemGroupedBackground).opacity(0.9).ignoresSafeArea())
            }
            
            // Input Section
            VStack {
                if let image = selectedImage {
                    HStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Button(action: {
                            selectedImage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.bottom, 5)
                }
                
                HStack {
                    TextField("Posez vos questions ...", text: $userInput)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(25)
                        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 2)
                        .disabled(isLoading)
                        .padding(.leading)
                    
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .padding(12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    .padding(.trailing, 5)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .padding(12)
                            .background(isLoading || userInput.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    .disabled(isLoading || userInput.isEmpty)
                    .padding(.trailing)
                }
                .padding(.vertical, 10)
                .background(Color(UIColor.systemGroupedBackground).opacity(0.9))
            }
        }
        .background(Color(UIColor.systemGroupedBackground).opacity(0.9).ignoresSafeArea())
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func sendMessage() {
        guard !userInput.isEmpty || selectedImage != nil else { return }
        
        // Ajouter le message utilisateur avec texte et/ou image
        let userMessage = Message(id: UUID(), role: .user, content: userInput, image: selectedImage)
        messages.append(userMessage)
        userInput = ""
        selectedImage = nil
        
        // Préparer les données pour l'API
        isLoading = true
        var messageToSend: [String: Any] = [
            "model": "llama3.1:latest",  // Modèle de base sans image
            "messages": [["role": "user", "content": userMessage.content]],
            "stream": false
        ]
        
        // Vérification si une image a été sélectionnée
        if let image = userMessage.image {
            if let imageData = image.pngData() {
                let base64Image = imageData.base64EncodedString()
                
                // Structurer correctement les images dans la requête
                var messages = messageToSend["messages"] as? [[String: Any]] ?? []
                var userMessageData = messages.first ?? [:]
                
                userMessageData["images"] = [base64Image]  // Image encodée en base64
                
                // Mettre à jour le modèle pour vision
                messageToSend["model"] = "llama3.2-vision"  // On passe au modèle vision
                
                messages[0] = userMessageData  // Mettre à jour le message
                messageToSend["messages"] = messages  // Ajouter les messages modifiés à la requête
            }
        }
        
        guard let url = URL(string: apiURL) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            // Sérialiser les données en JSON
            request.httpBody = try JSONSerialization.data(withJSONObject: messageToSend, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        // Appel à l'API
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Error fetching response: \(error)")
                return
            }
            guard let data = data else { return }
            
            do {
                // Décoder la réponse
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                let assistantMessage = Message(id: UUID(), role: .assistant, content: response.message.content, image: nil)
                
                DispatchQueue.main.async {
                    messages.append(assistantMessage)
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
