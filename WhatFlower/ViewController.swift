//
//  ViewController.swift
//  WhatFlower
//
//  Created by Adam Nogradi on 11/04/2019.
//  Copyright © 2019 Adam Nogradi. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert image to CIImage")
            }
            detect(image: ciimage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading FlowerClassifier model failed")
        }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image")
            }
            if let firstResult = results.first {
                self.navigationItem.title = firstResult.identifier.capitalized
                self.getWikipediaDetails(flowerName: firstResult.identifier)
            }
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }


    //MARK: - Networking
    func getWikipediaDetails(flowerName: String) {
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize": "500"
        ]
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                let resJSON : JSON = JSON(response.result.value!)
                self.parseJson(json: resJSON)
                
            } else {
                fatalError("Error reading response JSON")
            }
        }
    }
    
    //MARK: - JSON parsing&displaying
    func parseJson(json: JSON) {
        let pageId = json["query"]["pageids"][0].stringValue
        let flowerImageURL = json["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
        textView.text = json["query"]["pages"][pageId]["extract"].stringValue
        imageView.sd_setImage(with: URL(string: flowerImageURL), completed: nil)
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
}

