import Foundation

enum EnvironmentDomain: Codable, Hashable {
    case prod
    case dev
    case custom(String)
}

enum RequestContentType {
    case json
    case textPlain
    case multipart(boundary: UUID)
    case none
}

extension EnvironmentDomain {
    var path: String {
        switch self {
        case .prod:
            return LocalConstants.prodDomain
        case .dev:
            return LocalConstants.devDomain
        case let .custom(branchName):
            return "\(branchName)"
        }
    }
}

private enum LocalConstants {
    static let prodDomain = "prod.api.com"
    static let devDomain = "dev.api.com"
}

enum RequestType: String {
    case GET
    case POST
}

protocol RequestProtocol {
    
    var environmentDomain: EnvironmentDomain { get }
    
    var path: String { get }
    
    var scheme: String { get }
     
    var headers: [String: String] { get }
    
    var params: Data? { get }
    
    var urlParams: [[String: String?]]? { get }
    
    var addAuthorizationToken: Bool { get }
    
    var requestType: RequestType { get }
    
    var contentType: RequestContentType { get }
}

extension RequestProtocol {

    var environmentDomain: EnvironmentDomain {
        .dev
    }
    
    var contentType: RequestContentType {
        .none
    }
        
    var host: String {
        environmentDomain.path
    }
    
    var scheme: String {
        "https"
    }
    
    var addAuthorizationToken: Bool {
        true
    }
    
    var params: Data? {
        nil
    }
    
    var urlParams: [[String: String?]]? {
        nil
    }
    
    var headers: [String: String] {
        var headers = ["User-Agent": userAgent]
        
        switch contentType {
        case .json:
            headers["Content-Type"] = "application/json"
        case .textPlain:
            headers["Content-Type"] = "application/octet-stream"
        case .multipart(let boundary):
            headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        default:
            break
        }
        return headers
    }
    
    private var userAgent: String {
        if let infoDictionary = Bundle.main.infoDictionary,
            let version = infoDictionary["CFBundleShortVersionString"] as? String {
            return "App/\(version) (iOS)"
        } else {
            return "App (iOS)"
        }
    }
}

extension RequestProtocol {
    func createURLRequest() throws -> URLRequest {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        
        if let urlParams,
           !urlParams.isEmpty {
            var urlQueryItems: [URLQueryItem] = []
            
            for dict in urlParams {
                for (key, value) in dict {
                    let urlQueryItem = URLQueryItem(name: key, value: value)
                    urlQueryItems.append(urlQueryItem)
                }
            }
            
            components.queryItems = urlQueryItems
        }
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = requestType.rawValue
        
        
        if !headers.isEmpty {
            urlRequest.allHTTPHeaderFields = headers
        }
        
        if let params {
            urlRequest.httpBody = params
        }
        
        return urlRequest
    }
}
