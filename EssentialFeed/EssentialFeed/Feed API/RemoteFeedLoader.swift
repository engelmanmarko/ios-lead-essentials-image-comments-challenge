//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient
	private let mapper: FeedMapper
	
	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}
	
	public typealias FeedMapper = (_ data: Data, _ response: HTTPURLResponse) throws -> [FeedImage]
	public typealias Result = FeedLoader.Result
	
	public init(url: URL, client: HTTPClient, mapper: @escaping FeedMapper) {
		self.url = url
		self.client = client
		self.mapper = mapper
	}
	
	public func load(completion: @escaping (Result) -> Void) {
		client.get(from: url) { [weak self] result in
			guard let self = self else { return }
			
			switch result {
			case let .success((data, response)):
				completion(self.map(data, from: response))
				
			case .failure:
				completion(.failure(Error.connectivity))
			}
		}
	}
}

// MARK: - Private
private extension RemoteFeedLoader {
	func map(_ data: Data, from response: HTTPURLResponse) -> Result {
		do {
			let items = try mapper(data, response)
			return .success(items)
		} catch {
			return .failure(Error.invalidData)
		}
	}
}
