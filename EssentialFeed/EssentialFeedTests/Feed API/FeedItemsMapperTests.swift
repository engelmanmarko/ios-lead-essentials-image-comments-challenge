//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

class FeedItemsMapperTests: XCTestCase {
	func test_throwsErrorOnNon200HTTPResponse() {
		let samples = [199, 201, 300, 400, 500].compactMap {
			HTTPURLResponse(url: anyURL(), statusCode: $0, httpVersion: nil, headerFields: nil)
		}
		
		try? samples.forEach { response in
			XCTAssertThrowsError(try FeedItemsMapper.map(anyData(), from: response))
		}
	}
	
	func test_throwsErrorOn200HTTPResponseWithInvalidJSON() {
		let validResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
		let invalidJSON = Data("invalid json".utf8)
		XCTAssertThrowsError(try FeedItemsMapper.map(invalidJSON, from: validResponse))
	}
	
	func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
		let validResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
		let emptyListJSON = makeItemsJSON([])
		XCTAssertEqual(try FeedItemsMapper.map(emptyListJSON, from: validResponse), [])
	}
	
	func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
		let validResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
		let item1 = makeItem(
			id: UUID(),
			imageURL: URL(string: "http://a-url.com")!)
		
		let item2 = makeItem(
			id: UUID(),
			description: "a description",
			location: "a location",
			imageURL: URL(string: "http://another-url.com")!)
		
		let items = [item1.model, item2.model]
		let itemsJSON = makeItemsJSON([item1.json, item2.json])
		XCTAssertEqual(try FeedItemsMapper.map(itemsJSON, from: validResponse),items)
	}
	
	private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedImage, json: [String: Any]) {
		let item = FeedImage(id: id, description: description, location: location, url: imageURL)
		
		let json = [
			"id": id.uuidString,
			"description": description,
			"location": location,
			"image": imageURL.absoluteString
		].compactMapValues { $0 }
		
		return (item, json)
	}
	
	private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
		let json = ["items": items]
		return try! JSONSerialization.data(withJSONObject: json)
	}
}
