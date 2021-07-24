//
//  LoginResponse.swift
//  PlatziTweets
//
//  Created by Diego on 30/06/21.
//

import Foundation

struct LoginResponse:  Codable {
    let user : User
    let token : String 
}
