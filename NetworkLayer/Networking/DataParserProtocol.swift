import Foundation

protocol DataParserProtocol {
    func parse<T: Decodable>(data: Data, dateFormat: String?) throws -> T
}

final class DataParser: DataParserProtocol {
    private var jsonDecoder: JSONDecoder
    
    init(jsonDecoder: JSONDecoder = JSONDecoder()) {
        self.jsonDecoder = jsonDecoder
        self.jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func parse<T: Decodable>(data: Data, dateFormat: String? = "yyyy-MM-dd'T'HH:mm:ss.SSSZ") throws -> T {
        do {
            if let dateFormat = dateFormat {
                let dateFormatter = ThreadDateFormatter.formatter
                dateFormatter.dateFormat = dateFormat
                jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
            }
            
            return try jsonDecoder.decode(T.self, from: data)
        } catch let error {
            if let decodingEroor = error as? DecodingError {
                print("\(T.self) is failed to parse with error:")
                switch decodingEroor {
                case .typeMismatch(let key, let value):
                    print(".typeMismatch, error key \(key), value \(value) and ERROR: \(error.localizedDescription)")
                case .valueNotFound(let key, let value):
                    print(".valueNotFound, error key \(key), value \(value) and ERROR: \(error.localizedDescription)")
                case .keyNotFound(let key, let value):
                    print(".keyNotFound, error key \(key), value \(value) and ERROR: \(error.localizedDescription)")
                case .dataCorrupted(let key):
                    print(".dataCorrupted, error key \(key), and ERROR: \(error.localizedDescription)")
                default:
                    print(".default, ERROR: \(error.localizedDescription)")
                }
            }
            throw error
        }
    }
}

struct ThreadDateFormatter {
    
    static var formatter: DateFormatter {
        let temp = Thread.current.threadDictionary["dateformat"] as? DateFormatter
        let dateFormatter = temp ?? DateFormatter()
        
        if temp == nil {
            Thread.current.threadDictionary["dateformat"] = dateFormatter
        }
        
        return dateFormatter
    }
}
