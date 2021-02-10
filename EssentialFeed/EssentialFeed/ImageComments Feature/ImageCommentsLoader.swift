//
//  ImageCommentsLoader.swift
//  EssentialFeed
//
//  Created by Marko Engelman on 10/02/2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public protocol ImageCommentsLoader {
	typealias Result = Swift.Result<[ImageComment], Error>
	
	func load(completion: @escaping (Result) -> Void)
}
