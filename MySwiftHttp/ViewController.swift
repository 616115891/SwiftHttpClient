//
//  ViewController.swift
//  MySwiftHttp
//
//  Created by 叶金永 on 2018/8/24.
//  Copyright © 2018年 Keyon. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		var param = [String:Any]()
		param["platform"] = "iOS"
		param["position"] = "首页"
		param["pageSize"] = "5"
		_ = HttpClient.shareClient.httpRequest(with: "https://dev.niumowang-inc.com:9445/" + "api/banner/homebanner", requestType: .POST, paramOfType: .FORM, parameter: param) { (data, error) in
			debugPrint(JSON(data))
		}
		
		_ = HttpClient.shareClient.httpRequest(with: "http://127.0.0.1:9000/api/testJson", requestType: .GET, paramOfType: .JSON, parameter: nil, completion: { (data, error) in
//			let praseData = JSON(data!)
//			
//
//			debugPrint(praseData["a"])
		})
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

