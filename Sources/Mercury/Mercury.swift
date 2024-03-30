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

    static public func parse(_ resource: URL, 
                             withFormat format: ContentType = .html,
                             verbose: Bool = false) async throws -> Article {
        let currentFile = URL(fileURLWithPath: #file)
        let pwd = currentFile.deletingLastPathComponent()
        let nodeURL = pwd.appendingPathComponent("node")
        let mercuryCLIURL = pwd.appendingPathComponent("cli.js")

        do {
            let data = self.shell("\(nodeURL.path) \(mercuryCLIURL.path) \(resource.absoluteString) --format=\(format.rawValue)")
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Article.self, from: data)
        } catch {
            throw ServiceError.error(error)
        }
    }
    
    class func shell(_ command: String) -> Data {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.launch()
        
        return pipe.fileHandleForReading.readDataToEndOfFile()
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
