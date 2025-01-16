import SwiftUI

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    if let image = message.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.5)
                            .cornerRadius(15)
                            .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 2)
                    }
                    
                    Text(message.content)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 2)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if let image = message.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.5)
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.3), radius: 2, x: 0, y: 2)
                    }
                    
                    Text(message.content)
                        .padding(12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.black)
                        .cornerRadius(20)
                        .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 2)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                }
                Spacer()
            }
        }
        .padding(.horizontal)
        .transition(.opacity)
    }
}
