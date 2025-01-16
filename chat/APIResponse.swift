import Foundation

struct APIResponse: Decodable {
    struct MessageContent: Decodable {
        var content: String
    }
    
    var message: MessageContent
    var error: String? 
}
