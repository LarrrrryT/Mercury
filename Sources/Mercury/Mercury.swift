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
            let data = self.shell("\(nodeURL.path) \(mercuryCLIURL.path) \(resource.absoluteString) --format=\(format.rawValue)", verbose: verbose)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Article.self, from: data)
        } catch {
            throw ServiceError.error(error)
        }
    }
    
    class func shell(_ command: String, verbose: Bool) -> Data {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = ["-c", command]
        process.launchPath = "/bin/zsh"
        process.launch()
        
        if verbose {
            process.terminationHandler = { _ in
                print("did end, status: \(process.terminationStatus)")
            }
        }
        
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
