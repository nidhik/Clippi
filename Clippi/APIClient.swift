//
//  APIClient.swift
//  Clippi
//
//  Created by Nidhi Kulkarni on 4/22/21.
//

import Foundation

// From: https://stackoverflow.com/questions/44001806/perform-polling-request-for-async-task


typealias Cancel = () -> Void

class APIClient {
    func pollForClip(
        assetId: String,
        duration: TimeInterval,
        onSuccess successHandler: @escaping ((_: APIGetClipSuccessResponse) -> Void),
        onFailure failureHandler: @escaping ((_: APIRequest.ErrorResponse?, _: Error) -> Void)) -> Cancel{
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(Int(duration * 1000)), leeway: .milliseconds(10))
        timer.setEventHandler(handler: {
            self.getClip(assetId: assetId, cancel: {
                timer.cancel()
            }, onSuccess: successHandler, onFailure: failureHandler)
        })
        timer.resume()
        return {
            timer.cancel()
        }
    }

    func getClip(
        assetId: String,
        cancel: @escaping Cancel,
        onSuccess successHandler: @escaping ((_: APIGetClipSuccessResponse) -> Void),
        onFailure failureHandler: @escaping ((_: APIRequest.ErrorResponse?, _: Error) -> Void)){
        return APIGetClipRequest(assetId: assetId)
            .dispatch(
                onSuccess: { (successResponse) in
                    cancel()
                    successHandler(successResponse)
            },
                onFailure: { (errorResponse, error) in
                 NSLog("Error getting clip \(error)")
                failureHandler(errorResponse, error)
            })
    }
    
    func clip(
        assetId: String,
        startTime: Float?,
        endTime: Float?,
        onPreview previewHandler: @escaping ((_: String) -> Void),
        onSuccess successHandler: @escaping ((_: APIGetClipSuccessResponse) -> Void),
        onFailure failureHandler: @escaping ((_: APIRequest.ErrorResponse?, _: Error) -> Void)) {
        _ = self.pollForClip(assetId: assetId, duration: 2.0, onSuccess: successHandler, onFailure: failureHandler)
        
//        APIClipRequest(assetId: assetId, startTime: startTime, endTime: endTime)
//            .dispatch(
//                onSuccess: { (successResponse) in
//                    NSLog("\(successResponse.id)")
//                    previewHandler("https://image.mux.com/\(successResponse.playbackId)/thumbnail.png")
//                    _ = self.pollForClip(assetId: successResponse.id, duration: 2.0, onSuccess: successHandler, onFailure: failureHandler)
//
//            },
//            onFailure: failureHandler)
    }
    
}


// Note: pattern from https://medium.com/swift2go/minimal-swift-api-client-9ea1c9c7946
 
//MARK: POST /api/clips

struct APIClipRequest: Codable {
    let assetId: String
    let startTime: Float?
    let endTime: Float?
}

struct APIClipSuccessResponse: Codable {
    let id: String
    let playbackId: String
}

extension APIClipRequest: APIEndpoint {
    func endpoint() -> String {
        return "/api/clips"
    }

    func dispatch(
        onSuccess successHandler: @escaping ((_: APIClipSuccessResponse) -> Void),
        onFailure failureHandler: @escaping ((_: APIRequest.ErrorResponse?, _: Error) -> Void)) {

        APIRequest.post(
            request: self,
            onSuccess: successHandler,
            onError: failureHandler)
    }
}

//MARK: GET /api/clips/<id>

struct APIGetClipRequest: Codable {
    let assetId: String
}

struct APIGetClipSuccessResponse: Codable {
    let data: APIData
}

struct APIData: Codable {
    let playbackId: String
    let assetId: String
}

extension APIGetClipRequest: APIEndpoint {
    func endpoint() -> String {
        return "/api/clips/\(assetId)"
    }

    func dispatch(
        onSuccess successHandler: @escaping ((_: APIGetClipSuccessResponse) -> Void),
        onFailure failureHandler: @escaping ((_: APIRequest.ErrorResponse?, _: Error) -> Void)) {

        APIRequest.get(
            request: self,
            onSuccess: successHandler,
            onError: failureHandler)
    }
}


extension APIRequest {
    public static func post<R: Codable & APIEndpoint, T: Codable, E: Codable>(
        request: R,
        onSuccess: @escaping ((_: T) -> Void),
        onError: @escaping ((_: E?, _: Error) -> Void)) {

        guard var endpointRequest = self.urlRequest(from: request) else {
            onError(nil, APIError.invalidEndpoint)
            return
        }
        endpointRequest.httpMethod = "POST"
        endpointRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            endpointRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            onError(nil, error)
            return
        }

        URLSession.shared.dataTask(
            with: endpointRequest,
            completionHandler: { (data, urlResponse, error) in
                DispatchQueue.main.async {
                    self.processResponse(data, urlResponse, error, onSuccess: onSuccess, onError: onError)
                }
        }).resume()
    }
    public static func get<R: Codable & APIEndpoint, T: Codable, E: Codable>(
        request: R,
        onSuccess: @escaping ((_: T) -> Void),
        onError: @escaping ((_: E?, _: Error) -> Void)) {

        guard var endpointRequest = self.urlRequest(from: request) else {
            onError(nil, APIError.invalidEndpoint)
            return
        }
        endpointRequest.httpMethod = "GET"
        endpointRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(
            with: endpointRequest,
            completionHandler: { (data, urlResponse, error) in
                DispatchQueue.main.async {
                    self.processResponse(data, urlResponse, error, onSuccess: onSuccess, onError: onError)
                }
        }).resume()
    }
}

extension APIRequest {
    public static func urlRequest(from request: APIEndpoint) -> URLRequest? {
        let endpoint = request.endpoint()
        guard let endpointUrl = URL(string: "https://clipping-nidhik.vercel.app\(endpoint)") else {
            return nil
        }

        var endpointRequest = URLRequest(url: endpointUrl)
        endpointRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        return endpointRequest
    }
}


extension APIRequest {
    public static func processResponse<T: Codable, E: Codable>(
        _ dataOrNil: Data?,
        _ urlResponseOrNil: URLResponse?,
        _ errorOrNil: Error?,
        onSuccess: ((_: T) -> Void),
        onError: ((_: E?, _: Error) -> Void)) {

        if let data = dataOrNil {
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                onSuccess(decodedResponse)
            } catch {
                let originalError = error

                do {
                    let errorResponse = try JSONDecoder().decode(E.self, from: data)
                    onError(errorResponse, APIError.errorResponseDetected)
                } catch {
                    onError(nil, originalError)
                }
            }
        } else {
            onError(nil, errorOrNil ?? APIError.noData)
        }
    }
}
