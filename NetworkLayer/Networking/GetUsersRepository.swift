import Foundation

protocol UserRepositoryProtocol {
    func getUser() async throws -> UserResponseModel
}

final class UserRepository: UserRepositoryProtocol {
    let networking: Networking
    
    init(networking: Networking = Networking()) {
        self.networking = networking
    }
    
    func getUser() async throws -> UserResponseModel {
        let request = GetUserRequest()
        let (data, _) = try await networking.perform(request, allowRetry: true)
        let responseModel: UserResponseModel = try networking.dataParser.parse(data: data, dateFormat: "")
        return responseModel
    }
}

struct GetUserRequest: RequestProtocol {
    var contentType: RequestContentType {
        .none
    }
    
    var path: String {
        "/api/v1/user-profiles/current"
    }
    
    var requestType: RequestType {
        .GET
    }
    
    var addAuthorizationToken: Bool {
        true
    }
    
    var body: Data? {
        nil
    }
}


struct UserResponseModel: Codable {
    let userID: String?
    let name: String?
}
