//
//  JYHttpClient.swift
//  iRich
//
//  Created by apple on 2017/2/2.
//  Copyright © 2017年 叶金永. All rights reserved.
//

import UIKit

enum RequestType {
    case GET
    case POST
}

enum ParamType {
	case JSON
	case FORM
}

struct Demo {
	var a:String
	var b:String
}

var timeoutInterval:Double = 30

class HttpClient: NSObject,URLSessionDelegate {
	
	
	fileprivate var contentTypeKey: String {
		return "Content-Type"
	}
	
    deinit {
        session.invalidateAndCancel()
        print("JYHttpClient deinit")
    }
    
    fileprivate var session: URLSession!

	public static let shareClient:HttpClient = {
       let data = HttpClient()
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        data.session = URLSession(configuration: configuration, delegate: data, delegateQueue: nil)
        return data
    }()
	
	public func composedURL(with path: String) throws -> URL {
		let encodedPath = path.encodeUTF8() ?? path
		guard let url = URL(string: encodedPath) else {
			throw NSError(domain: "com.Keyon.networking", code: 0, userInfo: [NSLocalizedDescriptionKey: "Couldn't create a url encodedPath: \(encodedPath)"])
		}
		return url
	}
	
	func postImages(toServer strUrl: String, dicPostParams params: NSMutableDictionary?, imageArray: [Any]?, file fileArray: [Any]?, imageName imageNameArray: [Any]?,completion:@escaping (Data?,Error?) -> Void) {
		
		DispatchQueue.global(qos: .default).async{ [weak self] in
			//分界线的标识符
			let TWITTERFON_FORM_BOUNDARY = "******"
			let url = URL(string: strUrl)
			var request: URLRequest!
			if let url = url {
				request = URLRequest(url: url)
			}
			//分界线 --AaB03x
			let MPboundary = "--\(TWITTERFON_FORM_BOUNDARY)"
			//结束符 AaB03x--
			let endMPboundary = "\(MPboundary)--"
			//要上传的图片
			var image: UIImage?
			
			//将要上传的图片压缩 并赋值与上传的Data数组
			var imageDataArray: [Data] = []
			for i in 0..<(imageArray?.count ?? 0) {
				//要上传的图片
				image = imageArray?[i] as? UIImage
				//*************  将图片压缩成我们需要的数据包大小 ******************
				var data: Data? = nil
				if let image = image {
					data = image.jpegData(compressionQuality: 1.0)
				}
				var dataKBytes: CGFloat = CGFloat(Double((data?.count ?? 0)) / 1000.0)
				var maxQuality: CGFloat = 0.9
				var lastData: CGFloat = dataKBytes
				while dataKBytes > 1024 && maxQuality > 0.01 {
					//将图片压缩成1M
					maxQuality = maxQuality - 0.01
					if let image = image {
						data = image.jpegData(compressionQuality: maxQuality)
					}
					dataKBytes = CGFloat(Double((data?.count ?? 0)) / 1000.0)
					if lastData == dataKBytes {
						break
					} else {
						lastData = dataKBytes
					}
				}
				//*************  将图片压缩成我们需要的数据包大小 ******************
				if let data = data {
					imageDataArray.append(data)
				}
			}
			
			//http body的字符串
			var body = ""
			//参数的集合的所有key的集合
			guard let params = params else {
				return
			}
			var keys = params.allKeys
			
			//遍历keys
			for i in 0..<keys.count{
				//得到当前key
				let key = keys[i] as? String
				
				//添加分界线，换行
				body += "\(MPboundary)\r\n"
				//添加字段名称，换2行
				body += "Content-Disposition: form-data; name=\"\(key ?? "")\"\r\n\r\n"
				
				//添加字段的值
				if let object = params[key ?? ""] {
					body += "\(object)\r\n"
				}
			}
			
			//声明myRequestData，用来放入http body
			var myRequestData = Data()
			//将body字符串转化为UTF8格式的二进制
			if let data = body.data(using: .utf8) {
				myRequestData.append(data)
			}
			
			guard let fileArray = fileArray,let imageNameArray = imageNameArray else {
				return
			}
			
			//循环加入上传图片
			for i in 0..<imageDataArray.count {
				//要上传的图片
				//得到图片的data
				let data = imageDataArray[i]
				var imgbody = ""
				//此处循环添加图片文件
				//添加图片信息字段
				////添加分界线，换行
				imgbody += "\(MPboundary)\r\n"
				imgbody += "Content-Disposition: form-data; name=\"\(fileArray[i])\"; filename=\"\(imageNameArray[i]).jpg\"\r\n"
				//声明上传文件的格式
				imgbody += "Content-Type: application/octet-stream; charset=utf-8\r\n\r\n"
				
				//将body字符串转化为UTF8格式的二进制
				if let data = imgbody.data(using: .utf8) {
					myRequestData.append(data)
				}
				//将image的data加入
				myRequestData.append(data)
				if let data = "\r\n".data(using: .utf8) {
					myRequestData.append(data)
				}
			}
			//声明结束符：--AaB03x--
			let end = "\(endMPboundary)\r\n"
			//加入结束符--AaB03x--
			if let data = end.data(using: .utf8) {
				myRequestData.append(data)
			}
			
			//设置HTTPHeader中Content-Type的值
			let content = "multipart/form-data; boundary=\(TWITTERFON_FORM_BOUNDARY)"
			//设置HTTPHeader
			request.setValue(content, forHTTPHeaderField: "Content-Type")
			//设置Content-Length
			request.setValue(String(format: "%lu", UInt(myRequestData.count)), forHTTPHeaderField: "Content-Length")
			request.timeoutInterval = timeoutInterval
			request.httpBody = myRequestData
			request.httpMethod = "POST"
			guard let strongSelf = self else {
				return
			}
			strongSelf.session.dataTask(with: request, completionHandler: { (data, response, error) in
				guard let _ = self else { return } //弱引用
				if let data = data {
					if error == nil {
						completion(data,nil)
					}else {
						completion(nil,error)
					}
				}else {
					completion(nil,error)
				}
			})
		}
	}
	
	func httpRequest(with path:String,requestType type:RequestType,paramOfType paramType:ParamType,parameter param:Any?,completion:@escaping (Data?,Error?) -> Void) -> URLSessionDataTask {
		var request = URLRequest(url: URL(string: path)!)
		request.timeoutInterval = timeoutInterval
		request.cachePolicy = .reloadIgnoringLocalCacheData
		if paramType == .JSON {
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			if let param = param {
				do {
					let data = try JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
					request.httpBody = data
				} catch {
					print(error)
				}
			}
		} else {
			request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
			var parametersDictionary:[String:Any]
			if let param = param as? [String: Any] {
				parametersDictionary = param
			} else {
				parametersDictionary = [String:Any]()
				fatalError("init(coder:) has not been implemented")
			}
			do {
				let formattedParameters = try parametersDictionary.urlEncodedString()
				switch type {
				case .GET:
					let urlEncodedPath: String
					if path.contains("?") {
						if let lastCharacter = path.last, lastCharacter == "?" {
							urlEncodedPath = path + formattedParameters
						} else {
							urlEncodedPath = path + "&" + formattedParameters
						}
					} else {
						urlEncodedPath = path + "?" + formattedParameters
					}
					request.url = try! composedURL(with: urlEncodedPath)
				case .POST:
					request.httpBody = formattedParameters.data(using: .utf8)
				}
			} catch let error as NSError {
				print(error)
			}
		}
        switch type {
        case .GET:
            request.httpMethod = "GET"
        case .POST:
            request.httpMethod = "POST"
		}
		let task = session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
			guard let _ = self else { return } //弱引用
			if let data = data {
				if error == nil {
					completion(data,nil)
				}else {
					completion(nil,error)
				}
			}else {
				completion(nil,error)
			}
		})
		task.resume()
		return task
    }
	
	//handle authenication
	func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		//认证服务器证书
		if challenge.protectionSpace.authenticationMethod
			== NSURLAuthenticationMethodServerTrust {
			debugPrint("服务端证书认证！")
			
			let serverTrust:SecTrust = challenge.protectionSpace.serverTrust!
			let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0)!
			let remoteCertificateData
				= CFBridgingRetain(SecCertificateCopyData(certificate))!
			guard let cerPath = Bundle.main.path(forResource: "release_api", ofType: "cer") else {
				debugPrint("证书路径错误")
				return
			}
			let cerUrl = URL(fileURLWithPath:cerPath)
			let localCertificateData = try! Data(contentsOf: cerUrl)
			
			if (remoteCertificateData.isEqual(localCertificateData) == true) {
				let credential = URLCredential(trust: serverTrust)
				challenge.sender?.use(credential, for: challenge)
				debugPrint("认证通过")
				return completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
			} else {
				debugPrint("认证失败的容错处理")
				return completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
			}
		}
			//认证客户端证书
		else if challenge.protectionSpace.authenticationMethod
			== NSURLAuthenticationMethodClientCertificate
		{
			debugPrint("客户端证书认证！")
			//获取客户端证书相关信息
			guard let identityAndTrust = self.extractIdentity() else {
				return
			}
			
			let urlCredential:URLCredential = URLCredential(
				identity: identityAndTrust.identityRef,
				certificates: identityAndTrust.certArray as? [AnyObject],
				persistence: URLCredential.Persistence.forSession)
			
			return completionHandler(.useCredential, urlCredential)
		}
			// 其它情况（不接受认证）
		else {
			debugPrint("其它情况（不接受认证）")
			return
		}
	}
	
	func extractIdentity() -> IdentityAndTrust? {
		var identityAndTrust:IdentityAndTrust!
		var securityError:OSStatus = errSecSuccess
		
		guard let path: String = Bundle.main.path(forResource: "mykey", ofType: "p12"),let PKCS12Data = NSData(contentsOfFile:path) else {
			debugPrint("证书路径错误")
			return nil
		}
		let key : NSString = kSecImportExportPassphrase as NSString
		let options : NSDictionary = [key : "123456"] //客户端证书密码
		//create variable for holding security information
		//var privateKeyRef: SecKeyRef? = nil
		
		var items : CFArray?
		
		securityError = SecPKCS12Import(PKCS12Data, options, &items)
		
		if securityError == errSecSuccess {
			let certItems:CFArray = items!;
			let certItemsArray:Array = certItems as Array
			let dict:AnyObject? = certItemsArray.first;
			if let certEntry:Dictionary = dict as? Dictionary<String, AnyObject> {
				// grab the identity
				let identityPointer:AnyObject? = certEntry["identity"]
				let secIdentityRef:SecIdentity = identityPointer as! SecIdentity
				// grab the trust
				let trustPointer:AnyObject? = certEntry["trust"]
				let trustRef:SecTrust = trustPointer as! SecTrust
				// grab the cert
				let chainPointer:AnyObject? = certEntry["chain"]
				identityAndTrust = IdentityAndTrust(identityRef: secIdentityRef,
													trust: trustRef, certArray:  chainPointer!)
			}
		}
		return identityAndTrust;
	}
}

//定义一个结构体，存储认证相关信息
struct IdentityAndTrust {
	var identityRef:SecIdentity
	var trust:SecTrust
	var certArray:AnyObject
}
