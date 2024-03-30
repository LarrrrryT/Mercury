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
            let command = "\(nodeURL.path) \(mercuryCLIURL.path) \(resource.absoluteString) --format=\(format.rawValue)"
            guard let data = await Self.shell(command, verbose: verbose) else {
                throw ServiceError.noData
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Article.self, from: data)
        } catch {
            throw ServiceError.error(error)
        }
    }
    
    static func shell(_ command: String, verbose: Bool) async -> Data? {
        await withCheckedContinuation { continuation in
            let process = Process()
            let pipe = Pipe()
            
            process.standardOutput = pipe
            process.standardError = pipe
            process.arguments = ["-c", command]
            process.launchPath = "/bin/zsh"
            process.launch()
            process.terminationHandler = { _ in
                if verbose {
                    print("did end, status: \(process.terminationStatus)")
                    print("did end, reason: \(process.terminationReason)")
                }
                continuation.resume(returning: nil)
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            continuation.resume(returning: data)
        }
    }
    
    public enum ContentType: String {
        case html = "html"
        case markdown = "markdown"
        case text = "text"
    }

    enum ServiceError: Error {
        case error(Error)
        case outputError
        case noData
    }
}
