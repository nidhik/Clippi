//
//  APIRequest.swift
//  Clippi
//
//  Created by Nidhi Kulkarni on 4/22/21.
//

import Foundation
// from: https://medium.com/swift2go/minimal-swift-api-client-9ea1c9c7946
protocol APIEndpoint {
    func endpoint() -> String
}

class APIRequest {
    struct ErrorResponse: Codable {
        let status: String
        let code: Int
        let message: String
    }

    enum APIError: Error {
        case invalidEndpoint
        case errorResponseDetected
        case noData
    }
}
