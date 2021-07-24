//
//  RegisterRequest.swift
//  PlatziTweets
//
//  Created by Diego on 30/06/21.
//

import Foundation

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let names: String
}
