import Foundation

open class Mercury {

    public struct Article: Codable {
        public let title: String
        public let author: String?
        public let datePublished: String?
        public let leadImageUrl: String?
        public let excerpt: String?
        public let content: String?
        public let url: String?
        public let wordCount: Int?
        public let domain: String?
    }

    static public func parse(_ resource: URL, withFormat format: ContentType = .html) async throws -> Article {
        let currentFile = URL(fileURLWithPath: #file)
        let pwd = currentFile.deletingLastPathComponent()
        let nodeURL = pwd.appendingPathComponent("node")
        let mercuryCLIURL = pwd.appendingPathComponent("cli.js")

        do {
            let prototypeString = try self.shell("\(nodeURL.path) \(mercuryCLIURL.path) \(resource.absoluteString) --format=\(format.rawValue)")
            let data = Data(prototypeString.utf8)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Article.self, from: data)
        } catch {
            throw ServiceError.error(error)
        }
    }

    static public func parse(_ resource: URL, withFormat format: ContentType = .html, completion: @escaping (_ result: [String: Any]) -> Void) {
        let currentFile = URL(fileURLWithPath: #file)
        let pwd = currentFile.deletingLastPathComponent()
        let nodeURL = pwd.appendingPathComponent("node")
        let mercuryCLIURL = pwd.appendingPathComponent("cli.js")
        DispatchQueue.global(qos: .userInitiated).async {
            var output = [String: Any]()
            do {
                let prototypeString = try self.shell("\(nodeURL.path) \(mercuryCLIURL.path) \(resource.absoluteString) --format=\(format.rawValue)")
                let data = Data(prototypeString.utf8)
                
                // To make sure this JSON is in the format we expect.
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    output = json
                }
                DispatchQueue.main.async {
                    completion(output)
                }
            } catch let error as NSError {
                print("Mercury failed to load: \(error.localizedDescription)\nThe following string could not be converted to a dictionary")
                DispatchQueue.main.async {
                    completion([:])
                }
            }
        }
    }
    
    class func shell(_ command: String) throws -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            throw ServiceError.outputError
        }
        return output
    }
    
    public enum ContentType: String {
        case html = "html"
        case markdown = "markdown"
        case text = "text"
    }

    enum ServiceError: Error {
        case error(Error)
        case outputError
    }
}
