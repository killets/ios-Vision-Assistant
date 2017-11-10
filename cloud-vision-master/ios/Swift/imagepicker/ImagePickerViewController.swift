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


// origin name : imagepicker

import UIKit
import SwiftyJSON
import MessageUI // Import MessageUI


// Add the delegate protocol
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMessageComposeViewControllerDelegate {
    let imagePicker = UIImagePickerController()
    let session = URLSession.shared
    var calledByURL = false
    var viewIsLoaded = false
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var labelResults: UITextView!
    //@IBOutlet weak var faceResults: UITextView!
    
    var googleAPIKey = "XXXXX"  // TODO, use your key
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    
    @IBAction func loadImageButtonTapped(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        NSLog("...1....")
        present(imagePicker, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imagePicker.delegate = self
        labelResults.isHidden = true
        //faceResults.isHidden = true
        spinner.hidesWhenStopped = true
         NSLog("...2....")
        viewIsLoaded = true
        if(calledByURL) {
            self.spinner.startAnimating()
            let pasteboard = UIPasteboard.general
            let pickedImage = pasteboard.image
            self.imageView.image = pickedImage
             // Base64 encode the image and create the request
            let binaryImageData = self.base64EncodeImage(pickedImage!)
            self.createRequest(with: binaryImageData)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     SMS app
     */
    // Conform to the protocol
    // MARK: - Message Delegate method
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    // Send a message by pressing button
    func sendMessageButton(_ msg : String) {
        if(MFMessageComposeViewController.canSendText()){
            let messageVC = MFMessageComposeViewController()
            messageVC.body = msg
            messageVC.recipients = ["69287"] // Optionally add some tel numbers
            messageVC.messageComposeDelegate = self
            
            self.present(messageVC, animated: true, completion: nil)
        }
        else {
            print("Cannot SMS...!!")
        }
    }
    
    
}


/// Image processing

extension ViewController {
    
    // gj ref: http://stackoverflow.com/questions/27880650/swift-extract-regex-matches
    func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return [String]()
        }
    }
    
    
    func analyzeResults(_ dataToParse: Data) {
        // Update UI on the main thread
        DispatchQueue.main.async(execute: {
            
            
            // Use SwiftyJSON to parse results
            let json = JSON(data: dataToParse)
            let errorObj: JSON = json["error"]
            // gj add if
            if (self.spinner != nil && self.spinner.isAnimating){
                self.spinner.stopAnimating()
            }
            if self.imageView != nil {
                self.imageView.isHidden = false
            }
            self.labelResults.isHidden = false
            //self.faceResults.isHidden = false
            //self.faceResults.text = ""
            
            // Check for errors
            if (errorObj.dictionaryValue != [:]) {
                self.labelResults.text = "Error code \(errorObj["code"]): \(errorObj["message"])"
            } else {
                // Parse the response
                print(json)
                let responses: JSON = json["responses"][0]
                
                // Get face annotations
                
        
                // Get label annotations
                let labelAnnotations: JSON = responses["textAnnotations"]
                let numLabels: Int = labelAnnotations.count
                var labels: Array<String> = []
                print("numLabels" + String(numLabels))
                if numLabels > 0 {
                    var labelResultsText:String = ""
                    for index in 0..<numLabels {
                        let label = labelAnnotations[index]["description"].stringValue
                        //labels.append(label)
                        labelResultsText += "\(label)"
                        break; // its strange that there are duplicates lables returned, 
                                //the 1st is the whole txt with format of newline
                    }
//                    for label in labels {
//                        // if it's not the last item add a comma
//                        if labels[labels.count - 1] != label {
//                            labelResultsText += "\(label), "
//                        } else {
//                            labelResultsText += "\(label)"
//                        }
//                    }
                
                    // alternative: not case sensitive
//                    if labelResultsText.lowercased().range(of:"This stop") != nil {
//                        print("---- exists ---- this stop")
   
//                    }
                    
                    // http://stackoverflow.com/questions/24200888/any-way-to-replace-characters-on-swift-string
                    //"(?\\d{3})?\\s\\d{3}-\\d{4}"
                    let alabelResultsText = labelResultsText.replacingOccurrences(of: "\n", with: " ")
                    let bus = self.matches(for: "This\\sstop\\s?\\d{5}" , in: alabelResultsText)
                    if(!bus.isEmpty) {
                        print(bus)
                        
                        let stop = (bus[0].characters.split{$0 == " "}.map(String.init))
                        if(stop.count == 3) {
                            let stopNum = stop[2]
                            print( stopNum )
                            self.sendMessageButton(stopNum)
                        }
                        
                        
                        
                    }
                    
                    self.labelResults.text = labelResultsText
                    
                    
                } else {
                    self.labelResults.text = "No labels found"
                }
            }
        })
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // gj TODO
        if calledByURL {
            imageView.contentMode = .scaleAspectFit
            imageView.isHidden = true // You could optionally display the image here by setting
            let pasteboard = UIPasteboard.general
            let pickedImage = pasteboard.image
            // Base64 encode the image and create the request
            let binaryImageData = base64EncodeImage(pickedImage!)
            createRequest(with: binaryImageData)
        }
        else if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            // gj true to false
            imageView.isHidden = false // You could optionally display the image here by setting imageView.image = pickedImage
            imageView.image = pickedImage
            spinner.startAnimating()
            // faceResults.isHidden = true
            labelResults.isHidden = true
            
            // Base64 encode the image and create the request
            let binaryImageData = base64EncodeImage(pickedImage)
            createRequest(with: binaryImageData)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func resizeImage(_ imageSize: CGSize, image: UIImage) -> Data {
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = UIImagePNGRepresentation(newImage!)
        UIGraphicsEndImageContext()
        return resizedImage!
    }
}


/// Networking

extension ViewController {
    func base64EncodeImage(_ image: UIImage) -> String {
        var imagedata = UIImagePNGRepresentation(image)
        
        // Resize the image if it exceeds the 2MB API limit
        if (imagedata?.count > 2097152) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
            imagedata = resizeImage(newSize, image: image)
        }
        
        return imagedata!.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    func createRequest(with imageBase64: String) {
        // Create our request URL
        
        var request = URLRequest(url: googleURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        // Build our API request
        let jsonRequest = [
            "requests": [
                "image": [
                    "content": imageBase64
                ],
                "features": [
                    [
                        "type": "TEXT_DETECTION",
                        "maxResults": 15
                    ]
                ]
            ]
        ]
        let jsonObject = JSON(jsonDictionary: jsonRequest)
        
        // Serialize the JSON
        guard let data = try? jsonObject.rawData() else {
            return
        }
        
        request.httpBody = data
        
        // Run the request on a background thread
        DispatchQueue.global().async { self.runRequestOnBackgroundThread(request) }
    }
    
    func runRequestOnBackgroundThread(_ request: URLRequest) {
        // run the request
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            
            self.analyzeResults(data)
        }
        
        task.resume()
    }
}


// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}
