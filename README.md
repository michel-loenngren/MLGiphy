# MLGiphy
Micro framework for searching and displaying animated gifs from giphy.com. This was a weekend project for me as I keep reading and hearing that animated gif support in iOS is leaky and crashes a lot. The approach to this micro framework is to build animated gif support entirely using iOS core libraries and thus relying on apples quality assurance.
MLGihpy is writting in swift 1.2. I only spent a few hours on this so feel free to send me pull requests with additional improvements and please tell me if it works for you.

## About
MLGiphy does not use any outside frameworks or libraries to function. It queries api.giphy.com using NSURLSession and parses the animated gif using standard ImageIO and MobileCoreServices to parse the result. The methods return a UIImage that can be directly added into a UIImageView which will automatically animate the image according to the timing found in the meta data of the returned gif (defaults to 0.1 second per frame if metadata cannot be found).

## Installation
Add MLGiphy.swift to your project

## Usage
### Search
```
MLGiphy.search("golden retriever") {
  // Do something with the returned [MLGiphy] array`
}
```

### Get by ids
```
MLGiphy.getByIds(["feqkVgjJpYtjy","7rzbxdu0ZEXLy"]) { (results) -> Void in
  // Do something with the returned [MLGiphy] array`
}
```

### Load animated gif from result
```
let mlGiphy = results[0]
mlGiphy.originalImage?.animatedGif() { (image) -> Void in
  myImageView.image = image
}
```

In this example I used mlGiphy.originalImage but all the other results are available by key. I.e.
`let mlGiphyImage: MLGiphyImage = mlGiphy.images?["fixed_height_small"]`
Which will return an MLGiphyImage object containing all the metadata (such as width, height, size and detailed urls for various purposes)

## Integrated example
This example searches giphy.com for "golden retriever" and displays the results in a grid view. This is not a complete example and should not be copied straight off. For production use further checking and caching is needed.
```
import UIKit

class MLGiphyCollectionViewController: UICollectionViewController {
    
    private var giphys = [MLGiphy]()
    private var loadedImages = [Int: UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.registerNib(UINib(nibName: "GifView", bundle: NSBundle.mainBundle()), forCellWithReuseIdentifier: "gifView")
        
        MLGiphy.search("golden retriever") { (results) -> Void in
            self.giphys = results
            dispatch_async(dispatch_get_main_queue()) {
                self.collectionView?.reloadData()
            }
        }
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return count(giphys)
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("gifView", forIndexPath: indexPath) as! GifView
        let giphy = giphys[indexPath.item]
        giphy.originalImage?.animatedGif() { (image) -> Void in
            cell.gifImageView.image = image
        }
        return cell
    }
}
```
