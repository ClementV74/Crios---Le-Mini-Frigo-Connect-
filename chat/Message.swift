import Foundation
import UIKit // Pour UIImage

enum Role {
    case user
    case assistant
}

struct Message: Identifiable {
    var id: UUID
    var role: Role
    var content: String
    var image: UIImage? // Ajout pour gérer les images
}

// Conformité au protocole Equatable
extension Message: Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id && lhs.role == rhs.role && lhs.content == rhs.content
    }
}
