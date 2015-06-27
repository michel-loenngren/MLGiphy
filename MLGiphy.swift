//
//  MLGiffy.swift
//  MLAnimatedGif
//
//  Created by Michel Loenngren on 6/20/15.
//  Copyright (c) 2015 Michel Loenngren. All rights reserved.
//
//  Micro framework for searching and displaying animated gifs
//  from giphy.com

import UIKit
import ImageIO
import MobileCoreServices

class MLGiphy {
    
    let type: String
    let id: String
    let bitlyGifUrl: NSURL?
    let bitlyUrl: NSURL?
    let embedUrl: NSURL?
    let userName: String?
    let source: NSURL?
    let rating: String?
    let caption: String?
    let contentUrl: NSURL?
    let importDateTime: NSDate?
    let trendingDateTime: NSDate?
    let images: [String: MLGiphyImage]?
    
    var originalImage: MLGiphyImage? {
        get {
            return images?["original"]
        }
    }
    
    var fixedHeightSmall: MLGiphyImage? {
        get {
            return images?["fixed_height_small"]
        }
    }
    
    private init(json: [String: AnyObject]) {
        type = json["type"] as! String
        id = json["id"] as! String
        if let urlString = json["bitly_gif_url"] as? String {
            bitlyGifUrl = NSURL(string: urlString)
        } else {
            bitlyGifUrl = nil
        }
        if let urlString = json["bitly_url"] as? String {
            bitlyUrl = NSURL(string: urlString)
        } else {
            bitlyUrl = nil
        }
        if let urlString = json["embed_url"] as? String {
            embedUrl = NSURL(string: urlString)
        } else {
            embedUrl = nil
        }
        userName = json["username"] as? String
        if let urlString = json["source"] as? String {
            source = NSURL(string: urlString)
        } else {
            source = nil
        }
        rating = json["rating"] as? String
        caption = json["caption"] as? String
        if let urlString = json["content_url"] as? String {
            contentUrl = NSURL(string: urlString)
        } else {
            contentUrl = nil
        }
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let dateString = json["import_datetime"] as? String {
            importDateTime = dateFormatter.dateFromString(dateString)
        } else {
            importDateTime = nil
        }
        if let dateString = json["trending_datetime"] as? String {
            trendingDateTime = dateFormatter.dateFromString(dateString)
        } else {
            trendingDateTime = nil
        }
        var allImages = [String: MLGiphyImage]()
        for image in json["images"] as! [String: [String: AnyObject]] {
            allImages[image.0] = MLGiphyImage(json: image.1)
        }
        images = allImages
    }
    
    class func search(searchTerm: String, searchComplete: ([MLGiphy])->Void) {
        var results = [MLGiphy]()
        var encodedSearchTerm = searchTerm.stringByReplacingOccurrencesOfString(" ", withString: "+", options: .LiteralSearch, range: nil)
        if let giphySearchTerm = encodedSearchTerm.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet()) {
            let session = NSURLSession.sharedSession()
            let url = NSURL(string: "http://api.giphy.com/v1/gifs/search?q=\(giphySearchTerm)&api_key=dc6zaTOxFJmzC") as NSURL!
            let dataTask = session.dataTaskWithURL(url) {(data, response, error) -> Void in
                if let unwrappedData = data {
                    var jsonError: NSError?
                    if let json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &jsonError) as? [String: AnyObject] {
                        if error == nil {
                            for giphyImage in json["data"] as! [[String: AnyObject]] {
                                let giphy = MLGiphy(json: giphyImage)
                                results+=[giphy]
                            }
                        }
                    }
                }
                searchComplete(results)
            }
            dataTask.resume()
        } else {
            searchComplete([MLGiphy]())
        }
    }
    
    class func getByIds(ids: [String], complete: ([MLGiphy])->Void) {
        var results = [MLGiphy]()
        let session = NSURLSession.sharedSession()
        let idsAsString = ",".join(ids)
        let url = NSURL(string: "http://api.giphy.com/v1/gifs?api_key=dc6zaTOxFJmzC&ids=\(idsAsString)") as NSURL!
        let dataTask = session.dataTaskWithURL(url) {(data, response, error) -> Void in
            if let unwrappedData = data {
                var jsonError: NSError?
                if let json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &jsonError) as? [String: AnyObject] {
                    if error == nil {
                        for giphyImage in json["data"] as! [[String: AnyObject]] {
                            let giphy = MLGiphy(json: giphyImage)
                            results+=[giphy]
                        }
                    }
                }
            }
            complete(results)
        }
        dataTask.resume()
    }
}

class MLGiphyImage {
    
    let url: NSURL
    let width: Int
    let height: Int
    let size: Float?
    let mp4: NSURL?
    let mp4Size: Float?
    let webp: NSURL?
    let webpSize: Float?
    let frames: Int?
    
    private init(json: [String: AnyObject]) {
        let urlString = json["url"] as! String
        url = NSURL(string: urlString)!
        width = (json["width"] as! String).toInt()!
        height = (json["height"] as! String).toInt()!
        size = (json["size"] as? NSString)?.floatValue
        if let urlString = json["mp4"] as? String {
            mp4 = NSURL(string: urlString)
        } else {
            mp4 = nil
        }
        mp4Size = (json["mp4_size"] as? NSString)?.floatValue
        if let urlString = json["webp"] as? String {
            webp = NSURL(string: urlString)
        } else {
            webp = nil
        }
        webpSize = (json["webp_size"] as? NSString)?.floatValue
        frames = (json["frames"] as? String)?.toInt()
    }
    
    func animatedGif(complete: (image: UIImage?)->Void) {
        let session = NSURLSession.sharedSession()
        let dataTask = session.dataTaskWithURL(url) { (data, response, error) -> Void in
            let sequence = data.animatedPNGSequence()
            dispatch_async(dispatch_get_main_queue()) {
                complete(image: sequence)
            }
        }
        dataTask.resume()
    }
}

extension NSData {
    
    private func animatedPNGSequence() -> UIImage? {
        var images = [UIImage]()
        var animationDuration = 0.0
        
        if let source = CGImageSourceCreateWithData(self, nil) where UTTypeConformsTo(CGImageSourceGetType(source), kUTTypePNG) == 0 {
            for frame in 0..<CGImageSourceGetCount(source) {
                if let currentFrameRef = CGImageSourceCreateImageAtIndex(source, frame, nil), currentImage = UIImage(CGImage: currentFrameRef) {
                    images+=[currentImage]
                    animationDuration+=frameTiming(CGImageSourceCopyPropertiesAtIndex(source, frame, nil) as? [String: AnyObject])
                }
            }
        }
        if count(images) > 0 && animationDuration > 0 {
            return UIImage.animatedImageWithImages(images, duration: NSTimeInterval(animationDuration))
        } else {
            return nil
        }
    }
    
    private func frameTiming(properties: [String: AnyObject]?) -> Double {
        if let unwrappedProperties = properties, gifProperties: [String: AnyObject] = unwrappedProperties[String(kCGImagePropertyGIFDictionary)] as? [String: AnyObject] {
            if let delayTime = gifProperties[String(kCGImagePropertyGIFUnclampedDelayTime)] as? Float {
                return Double(delayTime)
            } else if let delayTime = gifProperties[String(kCGImagePropertyGIFUnclampedDelayTime)] as? Float {
                return Double(delayTime)
            }
        }
        return 0.1
    }

}
