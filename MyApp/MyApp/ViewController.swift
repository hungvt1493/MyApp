 //
//  ViewController.swift
//  MyApp
//
//  Created by Hung Vuong on 11/21/16.
//  Copyright © 2016 Hung Vuong. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import ASCollectionView
 
class ViewController: UIViewController, ASCollectionViewDataSource, ASCollectionViewDelegate, UICollectionViewDelegate , CLLocationManagerDelegate {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var leftImgView: UIImageView!
    @IBOutlet weak var rightImgView: UIImageView!
    @IBOutlet weak var centerImgView: UIImageView!
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var collectionView: ASCollectionView!

    private var scrollView: UIScrollView!
    private var headerLbl: UILabel!
    private var mask: UIView!
    private var content: UIView!
    
    private var screenWidth:CGFloat = 0.0
    private var screenHeight:CGFloat = 0.0
    private var footerHeight:CGFloat = 5.0
    private var maskStartingY:CGFloat = 270.0 // Distance between top of scrolling content and top of screen 270
    private var maskMaxTravellingDistance:CGFloat = 160.0 // Distance the mask can move upwards before its content starts scrolling and gets clipped 160
    private var headerY:CGFloat = 80.0
    
    private var countLocation:Int = 0;
    private var oldLocation: CLLocationCoordinate2D?
    
    let locationManager = CLLocationManager()
    
    var numberOfItems:Int = 35
    let collectionElementKindHeader = "Header";
    let collectionElementKindMoreLoader = "MoreLoader";
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationController?.isNavigationBarHidden = true
        
        //Setup screen size
        let screenSize:CGRect = UIScreen.main.bounds
        
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        numberOfItems = 35
        
        initMainUI()
        configHeaderContentView()
        
        //Setup Location
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Setup View
    func initMainUI() {
        self.view.backgroundColor = UIColor.black
        
        //Setup header, which will change size when scrollview scrolls
        let headerFrame:CGRect = CGRect(x: 0, y: headerY, width: screenWidth, height: self.headerView.frame.size.height-20)
        self.headerView.frame = headerFrame
        view.addSubview(self.headerView)
        self.headerView.backgroundColor = UIColor.white
        
        
        //Scrollview
//        scrollView = UIScrollView(frame: self.view.frame)
//        scrollView!.showsVerticalScrollIndicator = false
//        scrollView!.showsHorizontalScrollIndicator = false
//        scrollView!.delegate = self
//        view.addSubview(scrollView!)
        collectionView.register(UINib(nibName: collectionElementKindHeader, bundle: nil), forSupplementaryViewOfKind: collectionElementKindHeader, withReuseIdentifier: "header")
        collectionView.delegate = self
        collectionView.asDataSource = self
        collectionView!.showsVerticalScrollIndicator = false
        collectionView!.showsHorizontalScrollIndicator = false
        collectionView.frame = self.view.frame;
        
        //Mask
        mask = UIView(frame: CGRect(x: 0, y: maskStartingY, width: screenWidth, height: screenHeight - maskStartingY - footerHeight))
        mask!.clipsToBounds = true
        collectionView!.addSubview(mask!)
        mask.backgroundColor = UIColor.blue
        mask.isHidden = true
        
        //Scrollable content
        content = UIView(frame: CGRect(x: 0,y: 0, width: screenWidth, height: screenHeight * 2))
        content!.backgroundColor = UIColor.lightGray
        content.backgroundColor = UIColor.red
        // Create some dummy content. 14 red bars that vertically fill the content container
//        for i in 0..<14 {
//            let bar = UILabel(frame: CGRect(x: 20, y: 0 + 52*i, width: Int(screenWidth - 40), height: 45))
//            bar.text = "bar no. " + String(i+1)
//            content!.addSubview(bar);
//        }
        
//        mask!.addSubview(content!)
        
        // Set scrollview size to 1.5x the screen height for this example
        collectionView!.contentSize = CGSize(width: screenWidth, height: (screenHeight * 2) + footerHeight)
        collectionView.backgroundColor = UIColor.black
    }
    
    func configHeaderContentView() {
//        self.leftImgView.layer.cornerRadius = self.leftImgView.frame.size.width/2;
        self.leftImgView.layer.borderColor = UIColor.white.cgColor
        self.leftImgView.layer.borderWidth = 2
        
//        self.rightImgView.layer.cornerRadius = self.leftImgView.frame.size.width/2;
        self.rightImgView.layer.borderColor = UIColor.white.cgColor
        self.rightImgView.layer.borderWidth = 2
    }

    // MARK: Scroll Delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //Moving the mask
        let offsetY:CGFloat = scrollView.contentOffset.y
        
        var newMaskHeight:CGFloat
        var newMaskY:CGFloat
        var newMaskFrame:CGRect
        
        if offsetY < maskMaxTravellingDistance {
            //Motion phase 1
            newMaskHeight = screenHeight - maskStartingY - footerHeight + offsetY;
            newMaskY = maskStartingY
            newMaskFrame = CGRect(x: 0, y: newMaskY, width: screenHeight, height: newMaskHeight)
        } else {
            //Motion phase 2
            newMaskHeight = screenHeight - maskStartingY - footerHeight + maskMaxTravellingDistance
            newMaskY = maskStartingY - maskMaxTravellingDistance + offsetY
            newMaskFrame = CGRect(x: 0, y: newMaskY, width: screenWidth, height: newMaskHeight)
        }
        
        mask.frame = newMaskFrame
        
        var newContentY:CGFloat
        var newContentFrame:CGRect
        
        if offsetY < maskMaxTravellingDistance {
            //Motion phase 1
            newContentFrame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight * 1.5)
            content!.frame = newContentFrame
        } else {
            //Motion phase 2
            newContentY = maskMaxTravellingDistance - offsetY
            newContentFrame = CGRect(x: 0, y: newContentY, width: screenWidth, height: screenHeight * 1.5)
            content!.frame = newContentFrame
        }
        
        
        //Moving the header
        var newHeaderFrame:CGRect
        var newHeaderY:CGFloat
        
        if offsetY <= maskMaxTravellingDistance {
            newHeaderY = headerY - (offsetY * 0.5) //Move at half speed of scroll
            newHeaderFrame = CGRect(x: self.headerView.frame.origin.x, y: newHeaderY, width: self.headerView.frame.size.width, height: self.headerView.frame.size.height)
            self.headerView.frame = newHeaderFrame
        } else {
            newHeaderY = headerY - (maskMaxTravellingDistance * 0.5)
            newHeaderFrame = CGRect(x: self.headerView.frame.origin.x, y: newHeaderY, width: self.headerView.frame.size.width, height: self.headerView.frame.size.height)
            self.headerView.frame = newHeaderFrame;
        }
    }

    
    // MARK: Location Manager Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        
   
        if locValue.latitude == oldLocation?.latitude && locValue.longitude == oldLocation?.longitude {
            return;
        } else {
            oldLocation = locValue
            
            if countLocation == 0 {
//                getWeather(location: locValue)
                countLocation += 1
            }
        }
    }
    
    // MARK: Get weather
    func getWeather(location: CLLocationCoordinate2D) {
        let kBaseWeatherAPI = "http://api.wunderground.com/api/e654e27496c72e1c/forecast/q/lat=\(location.latitude)&lon=\(location.longitude).json"
//        let parameters: Parameters = [
//            "lat": location.latitude.rounded(),
//            "lon": location.longitude.rounded(),
//            "APPID": weatherAPIAPPID]

        Alamofire.request(kBaseWeatherAPI).responseJSON { response in
            print(response.request)  // original URL request
            print(response.response) // HTTP URL response
            print(response.data)     // server data
            print(response.result)   // result of response serialization
            
            if let JSON = response.result.value {
//                print("JSON: \(JSON)")
                
                let highestToday = ((((((JSON as? NSDictionary)?.object(forKey: "forecast") as? NSDictionary)?
                                                                .object(forKey: "simpleforecast") as? NSDictionary)?
                                                                .object(forKey: "forecastday") as? NSArray)?
                                                                .firstObject as? NSDictionary)?
                                                                .object(forKey: "high") as? NSDictionary)?
                                                                .object(forKey: "celsius")
                
                let lowestToday = ((((((JSON as? NSDictionary)?.object(forKey: "forecast") as? NSDictionary)?
                                                                .object(forKey: "simpleforecast") as? NSDictionary)?
                                                                .object(forKey: "forecastday") as? NSArray)?
                                                                .firstObject as? NSDictionary)?
                                                                .object(forKey: "low") as? NSDictionary)?
                                                                .object(forKey: "celsius")
                
                print("JSON:\n high: \(highestToday!) \n low: \(lowestToday!)")
            }
        }
    }
    
    
    // MARK: ASCollectionViewDataSource
    
    func numberOfItemsInASCollectionView(_ asCollectionView: ASCollectionView) -> Int {
        return numberOfItems
    }
    
    func collectionView(_ asCollectionView: ASCollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let gridCell = asCollectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GridCell
        gridCell.label.text = NSString(format: "Item %ld ", indexPath.row) as String
        gridCell.imageView.image = UIImage(named: NSString(format: "image-%ld", indexPath.row % 10) as String)
        return gridCell
    }
    
    func collectionView(_ asCollectionView: ASCollectionView, parallaxCellForItemAtIndexPath indexPath: IndexPath) -> ASCollectionViewParallaxCell {
        let parallaxCell = asCollectionView.dequeueReusableCell(withReuseIdentifier: "parallaxCell", for: indexPath) as! ParallaxCell
        parallaxCell.label.text = NSString(format: "Item %ld ", indexPath.row) as String
        parallaxCell.updateParallaxImage(UIImage(named: NSString(format: "image-%ld", indexPath.row % 10) as String)!)
        return parallaxCell
    }
    
    func collectionView(_ asCollectionView: ASCollectionView, headerAtIndexPath indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: ASCollectionViewElement.Header, withReuseIdentifier: "header", for: indexPath)
        return header
     }
    
    
    func loadMoreInASCollectionView(_ asCollectionView: ASCollectionView) {
        if numberOfItems > 30 {
            collectionView.enableLoadMore = false
            return
        }
        numberOfItems += 10
        collectionView.loadingMore = false
        collectionView.reloadData()
    }
    
    func cellDidTap(cell: UITapGestureRecognizer) {
//        print("Did tap cell at index \(button.tag)")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            //let location = touch.locationInView(yourScrollView)
        }
    }
}



 class GridCell: UICollectionViewCell {
    
    @IBOutlet var label: UILabel!
    @IBOutlet var imageView: UIImageView!
    
 }
 
 class ParallaxCell: ASCollectionViewParallaxCell {
    
    @IBOutlet var label: UILabel!
    
 }
