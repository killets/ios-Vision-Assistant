// Copyright 2016 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        NSLog("...........................")
        let pasteboard = UIPasteboard.general
        if pasteboard.hasImages {
            // text was found and placed in the "string" constant
            NSLog("..........Yo Yo.................")
//            let vc = (self.window?.rootViewController)! as UIViewController
//            vc.calledByURL = true
            
            
            if let rootViewController = window?.rootViewController as? UINavigationController {
                if let vc = rootViewController.viewControllers.first as? ViewController {
                    vc.calledByURL = true
                        if(vc.viewIsLoaded == true) {
                        vc.spinner.startAnimating()
                        let pasteboard = UIPasteboard.general
                        let pickedImage = pasteboard.image
                        vc.imageView.image = pickedImage
                        // Base64 encode the image and create the request
                        let binaryImageData = vc.base64EncodeImage(pickedImage!)
                        vc.createRequest(with: binaryImageData)
                    }
                }
            }
            
            
//            // vc.buttonObj.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
//            //var tmpButton = vc.view.viewWithTag("loadPic") as? UIButton
//            for case let button as UIButton in vc.view.subviews {
//                button.sendActions(for: UIControlEvents.touchUpInside)                
//            }
//            //vc.tmpButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
//            
////            let pasteboard = UIPasteboard.general
////            let pickedImage = pasteboard.image
////            // Base64 encode the image and create the request
////            let binaryImageData = vc.base64EncodeImage(pickedImage!)
//            vc.createRequest(with: binaryImageData)
            
        }
        
        
        
        return true
    }

}

