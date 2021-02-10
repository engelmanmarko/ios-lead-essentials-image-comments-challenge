//
//  ResourceLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Marko Engelman on 10/02/2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

class ResourceLoaderTests: XCTestCase {
	func test_init_doesNotRequestDataFromURL() {
		let (_, client) = makeSUT()
		
		XCTAssertTrue(client.requestedURLs.isEmpty)
	}
	
	func test_load_requestsDataFromURL() {
		let url = URL(string: "https://a-given-url.com")!
		let (sut, client) = makeSUT(url: url)
		
		sut.load { _ in }
		
		XCTAssertEqual(client.requestedURLs, [url])
	}
	
	func test_loadTwice_requestsDataFromURLTwice() {
		let url = URL(string: "https://a-given-url.com")!
		let (sut, client) = makeSUT(url: url)
		
		sut.load { _ in }
		sut.load { _ in }
		
		XCTAssertEqual(client.requestedURLs, [url, url])
	}
	
	func test_load_deliversErrorOnClientError() {
		let (sut, client) = makeSUT()
		
		expect(sut, toCompleteWith: failure(.connectivity), when: {
			let clientError = NSError(domain: "Test", code: 0)
			client.complete(with: clientError)
		})
	}
	
	func test_load_deliversErrorOnMapperError() {
		let (sut, client) = makeSUT(mapper: { _, _ in throw anyNSError() })
		
		expect(sut, toCompleteWith: failure(.invalidData), when: {
			client.complete(withStatusCode: 200, data: anyData())
		})
	}
	
	func test_load_deliversMappedResourceOn200HTTPResponse() {
		let resource = Self.anyResource()
		let (sut, client) = makeSUT(mapper: { _,_ in resource })
		expect(sut, toCompleteWith: .success(resource), when: {
			client.complete(withStatusCode: 200, data: anyData())
		})
	}
	
	func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
		let url = URL(string: "http://any-url.com")!
		let client = HTTPClientSpy()
		var sut: ResourceLoader? = AnyResourceLoader(url: url, client: client, mapper: { _,_ in ResourceLoaderTests.anyResource() })
		
		var capturedResults = [AnyResourceLoader.Result]()
		sut?.load { capturedResults.append($0) }
		
		sut = nil
		client.complete(withStatusCode: 200, data: anyData())
		
		XCTAssertTrue(capturedResults.isEmpty)
	}
}

// MARK: - Private
private extension ResourceLoaderTests {
	private func makeSUT(
		url: URL = URL(string: "https://a-url.com")!,
		file: StaticString = #filePath, line: UInt = #line,
		mapper: @escaping AnyResourceMapper = { _,_ in anyResource() }
	) -> (sut: AnyResourceLoader, client: HTTPClientSpy) {
		let client = HTTPClientSpy()
		let sut = ResourceLoader(url: url, client: client, mapper: mapper)
		trackForMemoryLeaks(sut, file: file, line: line)
		trackForMemoryLeaks(client, file: file, line: line)
		return (sut, client)
	}
	
	private func failure(_ error: AnyResourceLoader.Error) -> AnyResourceLoader.Result {
		return .failure(error)
	}
	
	private func expect(_ sut: AnyResourceLoader, toCompleteWith expectedResult: AnyResourceLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
		let exp = expectation(description: "Wait for load completion")
		
		sut.load { receivedResult in
			switch (receivedResult, expectedResult) {
			case let (.success(receivedItems), .success(expectedItems)):
				XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
				
			case let (.failure(receivedError as AnyResourceLoader.Error), .failure(expectedError as AnyResourceLoader.Error)):
				XCTAssertEqual(receivedError, expectedError, file: file, line: line)
				
			default:
				XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
			}
			
			exp.fulfill()
		}
		
		action()
		
		wait(for: [exp], timeout: 1.0)
	}
}

private extension XCTestCase {
	typealias AnyResource = String
	typealias AnyResourceLoader = ResourceLoader<AnyResource>
	typealias AnyResourceMapper = (Data, HTTPURLResponse) throws -> AnyResource
	
	static func anyResource() -> AnyResource {
		return "AnyResource"
	}
	
	func anyInvalidJSON() -> Data {
		return Data("invalid json".utf8)
	}
}
