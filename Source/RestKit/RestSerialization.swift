//
//  RestSerialization.swift
//  WatsonDeveloperCloud
//
//  Created by Glenn Fisher on 4/6/16.
//  Copyright © 2016 Watson Developer Cloud. All rights reserved.
//

import Foundation
import Alamofire
import Freddy

extension Request {

    /**
     Creates a response serializer that returns an object of the given type initialized from
     JSON response data.
 
     - returns: An object response serializer.
     */
    internal static func ObjectSerializer<T: JSONDecodable>(
        path: [JSONPathType]? = nil)
        -> ResponseSerializer<T, NSError>
    {
        return ResponseSerializer { request, response, data, error in

            // fail if an error was already produced
            guard error == nil else {
                return .Failure(error!)
            }

            // fail if the data is nil
            guard let data = data else {
                let failureReason = "Data could not be serialized. Input data was nil."
                let error = Error.errorWithCode(.DataSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }

            // serialize a `T` from the json data
            do {
                let json = try JSON(data: data)
                var object: T
                if let path = path {
                    switch path.count {
                    case 0: object = try json.decode()
                    case 1: object = try json.decode(path[0])
                    case 2: object = try json.decode(path[0], path[1])
                    case 3: object = try json.decode(path[0], path[1], path[2])
                    case 4: object = try json.decode(path[0], path[1], path[2], path[3])
                    case 5: object = try json.decode(path[0], path[1], path[2], path[3], path[4])
                    default: throw JSON.Error.KeyNotFound(key: "ExhaustedVariadicParameterEncoding")
                    }
                } else {
                    object = try json.decode()
                }
                return .Success(object)
            } catch {
                let failureReason = "Data could not be serialized. Failed to parse JSON response."
                let error = Error.errorWithCode(.DataSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }
        }
    }

    /**
     Adds a handler to be called once the request has finished.
 
     - parameter queue: The queue to use.
     - parameter completionHandler: The code to be executed once the request has finished.
     */
    internal func responseObject<T: JSONDecodable>(
        queue queue: dispatch_queue_t? = nil,
        path: [JSONPathType]? = nil,
        completionHandler: Response<T, NSError> -> Void)
        -> Self
    {
        return response(
            queue: queue,
            responseSerializer: Request.ObjectSerializer(path),
            completionHandler: completionHandler
        )
    }
}