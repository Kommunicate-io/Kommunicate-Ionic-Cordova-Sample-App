//
//  ALKAPIRequest.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

// import Foundation
// import Alamofire
// import ObjectMapper

// enum ALKAPIRequestType {
//    case get
//    case post
//    case delete
//    case put
//
//    func methodOfAlamofire() -> Alamofire.HTTPMethod {
//        switch self {
//            case .get: return Alamofire.HTTPMethod.get
//            case .post: return Alamofire.HTTPMethod.post
//            case .delete: return Alamofire.HTTPMethod.delete
//            case .put: return Alamofire.HTTPMethod.put
//        }
//    }
// }
//
// enum ALKAPIParameterType {
//    case url
//    case urlEncodedInURL
//    case json
// }
//
// class ALKAPIRequest {
//    // MARK: - Variables and Types
//    // MARK: Protected
//
//    var methodType: ALKAPIRequestType = .get
//
//    var type: ALKAPIRequestType {
//        return self.methodType
//    }
//
//    var paramsType: ALKAPIParameterType {
//        switch self.type {
//        case .post, .put, .delete:
//            return .json
//
//        case .get:
//            return .url
//        }
//    }
//
//    var url: String {
//        return ""
//    }
//
//    var params: [String: Any]? {
//        return nil
//    }
//
//    var headers: [String: String]? {
//        return nil
//    }
//
//    var responseKeyPath: String {
//        return ""
//    }
// }
