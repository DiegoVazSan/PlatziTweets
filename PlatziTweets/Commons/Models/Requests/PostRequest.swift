//
//  PostRequest.swift
//  PlatziTweets
//
//  Created by Diego on 30/06/21.
//

import Foundation

struct PostRequest: Codable {
    let text: String
    let imageUrl: String?
    let videoUrl: String?
    let location: PostRequestLocation?
}
