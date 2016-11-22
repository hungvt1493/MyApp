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

class ViewController: UIViewController, UIScrollViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var leftImgView: UIImageView!
    @IBOutlet weak var rightImgView: UIImageView!
    @IBOutlet weak var centerImgView: UIImageView!
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!

    private var scrollView: UIScrollView!
    private var headerLbl: UILabel!
    private var mask: UIView!
    private var content: UIView!
    
    private var screenWidth:CGFloat = 320.0
    private var screenHeight:CGFloat = 568.0
    private var footerHeight:CGFloat = 5.0
    private var maskStartingY:CGFloat = 270.0 // Distance between top of scrolling content and top of screen
    private var maskMaxTravellingDistance:CGFloat = 160.0 // Distance the mask can move upwards before its content starts scrolling and gets clipped
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Setup screen size
        let screenSize:CGRect = UIScreen.main.bounds
        
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        //Setup header, which will change size when scrollview scrolls
        let headerFrame:CGRect = CGRect(x: 0, y: 100, width: self.headerView.frame.size.width, height: self.headerView.frame.size.height)
        self.headerView.frame = headerFrame
        view.addSubview(self.headerView)
        
        
        //Scrollview
        scrollView = UIScrollView(frame: self.view.frame)
        scrollView!.showsVerticalScrollIndicator = false
        scrollView!.showsHorizontalScrollIndicator = false
        scrollView!.delegate = self
        view.addSubview(scrollView!)
        
        //Mask
        mask = UIView(frame: CGRect(x: 0, y: maskStartingY, width: screenWidth, height: screenHeight - maskStartingY - footerHeight))
        mask!.clipsToBounds = true
        scrollView!.addSubview(mask!)
        
        //Scrollable content
        content = UIView(frame: CGRect(x: 0,y: 0, width: screenWidth, height: screenHeight * 1.5))
        content!.backgroundColor = UIColor.lightGray
        
        // Create some dummy content. 14 red bars that vertically fill the content container
        for i in 0..<14 {
            let bar = UILabel(frame: CGRect(x: 20, y: 0 + 52*i, width: Int(screenWidth - 40), height: 45))
            bar.text = "bar no. " + String(i+1)
            content!.addSubview(bar);
        }
        
        mask!.addSubview(content!)
        
        // Set scrollview size to 1.5x the screen height for this example
        scrollView!.contentSize = CGSize(width: screenWidth, height: (screenHeight * 1.5) + footerHeight)
        
        
        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            newHeaderY = 100 - (offsetY * 0.5) //Move at half speed of scroll
            newHeaderFrame = CGRect(x: self.headerView.frame.origin.x, y: newHeaderY, width: self.headerView.frame.size.width, height: self.headerView.frame.size.height)
            self.headerView.frame = newHeaderFrame
        } else {
            newHeaderY = 100 - (maskMaxTravellingDistance * 0.5)
            newHeaderFrame = CGRect(x: self.headerView.frame.origin.x, y: newHeaderY, width: self.headerView.frame.size.width, height: self.headerView.frame.size.height)
            self.headerView.frame = newHeaderFrame;
        }
    }

    
    // MARK: Location Manager Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        
        getWeather(location: locValue)
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
                print("JSON: \(JSON)")
            }
        }
    }
}

