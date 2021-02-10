//
//  ImageComment.swift
//  EssentialFeed
//
//  Created by Marko Engelman on 10/02/2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public struct ImageComment {
	public let id: UUID
	public let message: String
	public let createtAt: Date
	public let author: String
}
