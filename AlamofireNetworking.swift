//
//  AlamofireNetworking.swift
//  ems-Manager
//
//  Created by mac on 2019/4/23.
//  Copyright © 2019 mac. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import HandyJSON

typealias resultClosure<T> = (_ result: T?) -> Void

protocol ModelTransformDelegate{
    func didRecieveDataUpdate<T>(_ jsonData: JSON?, result:resultClosure<T>)
}

extension HandyJSON{
    func didRecieveDataUpdate<T: HandyJSON>(_ jsonData: JSON?, result:resultClosure<T>){
        let model = T.deserialize(from: jsonData?.dictionaryObject)
        result(model)
    }
}
class MessageModel: HandyJSON{
    
    var departMentId: String?
    var orgName: String?
    var sessionId: String?
    var loginTime: String?
    var orgId: String?
    var funType: String?
    var orgTypeId: String?
    var userCode: String?
    var funcList: [FuncList?]?
    
    struct FuncList:HandyJSON {
        var funccode: String?
        var functionEn: String?
        var funcTypeName: String?
        var parentcode: String?
        var funcname: String?
        var orderno: String?
    }
    
    required init() {}
}


extension Array: ModelTransformDelegate where Element: HandyJSON{
   
    func didRecieveDataUpdate<T>(_ jsonData: JSON?, result: (T?) -> Void){
        let resultArray = [Element].deserialize(from: jsonData?["funcList"].arrayObject)
        result(resultArray as? T)
    }
}

open class AlamofireNetworking{
    
    static let shared = AlamofireNetworking.init()
    var modelDelegate: ModelTransformDelegate?
    var handyJSONDelegate: HandyJSON?
    
    /// 不带数据处理的网络请求
    func requestData(_ urlString: String, parameter: [String: Any]?, method: HTTPMethod, success: @escaping (JSON) -> (Void),failure: @escaping (Any) -> (Void)){
        assert(urlString.count >= 0, "URL 不能为空")
        request(urlString, method: method, parameters: parameter, encoding: URLEncoding.default, headers: nil).validate().responseJSON { (response) in
            guard response.error != nil else{ failure(response.error as Any); return}
            
        }
    }
    
    /// 通用数据处理的网络请求
    func requestData<T>(_ urlString: String, parameter: Dictionary<String, Any>?, method: HTTPMethod, dataModel: T,success: @escaping resultClosure<T>,failure: @escaping (Any) -> (Void)){
        assert(urlString.count >= 0, "URL 不能为空")
        self.modelDelegate = (dataModel as? ModelTransformDelegate)
        request(urlString, method: method, parameters: parameter, encoding: URLEncoding.default, headers: nil).validate().responseJSON { (response) in
            guard response.result.isSuccess else{ failure(response.result.error as Any); return}
            let json = try? JSON(data:response.data!)
            self.modelDelegate?.didRecieveDataUpdate(json, result: success)
        }
    }
    
    /// 返回Model的网络请求
    func requestData<T>(_ urlString: String, parameter: Dictionary<String, Any>?, method: HTTPMethod, dataModel: T,success: @escaping resultClosure<T>,failure: @escaping (Any) -> (Void)) where T:HandyJSON{
        assert(urlString.count >= 0, "URL 不能为空")
        request(urlString, method: method, parameters: parameter, encoding: URLEncoding.default, headers: nil).validate().responseJSON { (response) in
            guard response.result.isSuccess else{ failure(response.result.error as Any); return}
            let json = try? JSON(data:response.data!)
            dataModel.didRecieveDataUpdate(json, result: success)
        }
    }
}
