import Foundation

typealias AuthToken = String

enum AuthError: Error {
    case missingToken
    case invalidToken
}

// TODO: make interface when know
actor AuthManager {
    private init() {}
    static let shared: AuthManager = AuthManager()
    
    private var refreshTokenTask: Task<AuthToken, Error>?

    // TODO: use keychain
    private var currentToken: AuthToken?
    
    func save(_ token: AuthToken?) {
        self.currentToken = token
    }
    
    func validToken() async throws -> AuthToken {
        if let handleRefreshTask = refreshTokenTask {
            return try await handleRefreshTask.value
        }
        
        guard let token = currentToken else {
            return try await refreshToken()
        }
        
        return token
    }
    
    func refreshToken() async throws -> AuthToken {
        if let refreshTask = refreshTokenTask {
            return try await refreshTask.value
        }
        
        let task = Task { () throws -> AuthToken in
            defer { refreshTokenTask = nil }
            
            let newToken = try await refreshAuthToken()
            currentToken = newToken
            
            return newToken
        }
        
        self.refreshTokenTask = task
        
        return try await task.value
    }

    private func refreshAuthToken() async throws -> AuthToken {
        return "RefreshedToken"
        // TODO: refresh AuthToken here
    }
}
