import Foundation

protocol NetworkingProtocol {
    func perform(_ requestProtocol: RequestProtocol, allowRetry: Bool) async throws -> (Data, URLResponse)
}

final class Networking: NetworkingProtocol {
    
    let authManager: AuthManager
    let dataParser: DataParserProtocol
    
    init(
        authManager: AuthManager = AuthManager.shared,
        dataParser: DataParserProtocol = DataParser()
    ) {
        self.authManager = authManager
        self.dataParser = dataParser
    }
    
    public func perform(_ requestProtocol: RequestProtocol, allowRetry: Bool = true) async throws -> (Data, URLResponse) {
        var urlRequest: URLRequest = try requestProtocol.createURLRequest()
        
        if requestProtocol.addAuthorizationToken {
            urlRequest = try await authorizedRequest(from: urlRequest)
        }
        
        // TODO: pass URLSession as dependency
        let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
        
        if let httpResponse = urlResponse as? HTTPURLResponse,
           httpResponse.statusCode == 401 {
            if allowRetry {
                _ = try await authManager.refreshToken()
                return try await perform(requestProtocol, allowRetry: false)
            }
            
            throw AuthError.invalidToken
        }
        
        return (data, urlResponse)
    }
    
    private func authorizedRequest(from request: URLRequest) async throws -> URLRequest {
        var newRequest = request
        let token = try await authManager.validToken()
        
        newRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
         
            
        return newRequest
    }
}
