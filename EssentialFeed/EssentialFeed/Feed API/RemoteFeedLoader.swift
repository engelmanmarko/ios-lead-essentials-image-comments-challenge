//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader<T> {
	private let url: URL
	private let client: HTTPClient
	private let mapper: Mapper
	
	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}
	
	public typealias Mapper = (_ data: Data, _ response: HTTPURLResponse) throws -> T
	public typealias Result = Swift.Result<T, Swift.Error>
	
	public init(url: URL, client: HTTPClient, mapper: @escaping Mapper) {
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
			return .success(try mapper(data, response))
		} catch {
			return .failure(Error.invalidData)
		}
	}
}
