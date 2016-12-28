 //
//  ViewController.swift
//  MyApp
//
//  Created by Hung Vuong on 11/21/16.
//  Copyright © 2016 Hung Vuong. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import Alamofire
import ASCollectionView
import ExpandingMenu
 
class ViewController: UIViewController, ASCollectionViewDataSource, ASCollectionViewDelegate, UICollectionViewDelegate , CLLocationManagerDelegate, UIScrollViewDelegate, AddEventViewControllerDelegate {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var leftImgView: UIImageView!
    @IBOutlet weak var rightImgView: UIImageView!
    @IBOutlet weak var centerImgView: UIImageView!
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var collectionView: ASCollectionView!

//    private var scrollView: UIScrollView!
    private var headerLbl: UILabel!
    private var mask: UIView!
//    private var content: UIView!
    
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
    
    var previewContents = Array<PreviewContent>()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationController?.isNavigationBarHidden = true
        
        addData()
        
        
        //Setup screen size
        let screenSize:CGRect = UIScreen.main.bounds
        
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        numberOfItems = 35
        
        initMainUI()
        configHeaderContentView()
        configureExpandingMenuButton()
        
        
        //Setup Location
        // Ask for Authorisation from the User.
//        self.locationManager.requestAlwaysAuthorization()
//        
//        // For use in foreground
//        self.locationManager.requestWhenInUseAuthorization()
//        
//        if CLLocationManager.locationServicesEnabled() {
//            locationManager.delegate = self
//            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
//            locationManager.startUpdatingLocation()
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
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

        // Set scrollview size to 1.5x the screen height for this example
        collectionView!.contentSize = CGSize(width: screenWidth, height: (screenHeight * 2) + footerHeight)
        collectionView.backgroundColor = UIColor.black
    }
    
    func configHeaderContentView() {
        self.leftImgView.layer.borderColor = UIColor.white.cgColor
        self.leftImgView.layer.borderWidth = 2
        
        self.rightImgView.layer.borderColor = UIColor.white.cgColor
        self.rightImgView.layer.borderWidth = 2
    }
    
    fileprivate func configureExpandingMenuButton() {
        let menuButtonSize: CGSize = CGSize(width: 64.0, height: 64.0)
        let menuButton = ExpandingMenuButton(frame: CGRect(origin: CGPoint.zero, size: menuButtonSize), centerImage: UIImage(named: "chooser-button-tab")!, centerHighlightedImage: UIImage(named: "chooser-button-tab-highlighted")!)
        menuButton.center = CGPoint(x: self.view.bounds.width - 32.0, y: self.view.bounds.height - 72.0)
        self.view.addSubview(menuButton)
        
        func showAlert(_ title: String) {
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        let item1 = ExpandingMenuItem(size: menuButtonSize, title: "Music", image: UIImage(named: "chooser-moment-icon-music")!, highlightedImage: UIImage(named: "chooser-moment-icon-place-highlighted")!, backgroundImage: UIImage(named: "chooser-moment-button"), backgroundHighlightedImage: UIImage(named: "chooser-moment-button-highlighted")) { () -> Void in
//            showAlert("Music")
            self.addEvent()
        }
        
        let item2 = ExpandingMenuItem(size: menuButtonSize, title: "Place", image: UIImage(named: "chooser-moment-icon-place")!, highlightedImage: UIImage(named: "chooser-moment-icon-place-highlighted")!, backgroundImage: UIImage(named: "chooser-moment-button"), backgroundHighlightedImage: UIImage(named: "chooser-moment-button-highlighted")) { () -> Void in
            showAlert("Place")
        }
        
        let item3 = ExpandingMenuItem(size: menuButtonSize, title: "Camera", image: UIImage(named: "chooser-moment-icon-camera")!, highlightedImage: UIImage(named: "chooser-moment-icon-camera-highlighted")!, backgroundImage: UIImage(named: "chooser-moment-button"), backgroundHighlightedImage: UIImage(named: "chooser-moment-button-highlighted")) { () -> Void in
            showAlert("Camera")
        }
        
        let item4 = ExpandingMenuItem(size: menuButtonSize, title: "Thought", image: UIImage(named: "chooser-moment-icon-thought")!, highlightedImage: UIImage(named: "chooser-moment-icon-thought-highlighted")!, backgroundImage: UIImage(named: "chooser-moment-button"), backgroundHighlightedImage: UIImage(named: "chooser-moment-button-highlighted")) { () -> Void in
            showAlert("Thought")
        }
        
        let item5 = ExpandingMenuItem(size: menuButtonSize, title: "Sleep", image: UIImage(named: "chooser-moment-icon-sleep")!, highlightedImage: UIImage(named: "chooser-moment-icon-sleep-highlighted")!, backgroundImage: UIImage(named: "chooser-moment-button"), backgroundHighlightedImage: UIImage(named: "chooser-moment-button-highlighted")) { () -> Void in
            showAlert("Sleep")
        }
        
        menuButton.addMenuItems([item1, item2, item3, item4, item5])
        
        menuButton.willPresentMenuItems = { (menu) -> Void in
            print("MenuItems will present.")
        }
        
        menuButton.didDismissMenuItems = { (menu) -> Void in
            print("MenuItems dismissed.")
        }
    }
    
    // MARK: Add new event
    func addEvent() {
        print("Do add new event...")
        
        let addNewEventVC = self.storyboard?.instantiateViewController(withIdentifier: "AddEventViewController") as? AddEventViewController
        addNewEventVC?.addNew = true
        addNewEventVC?.delegate = self
        addNewEventVC?.index = -1
        let nav = UINavigationController(rootViewController:addNewEventVC!)
        present(nav, animated: true, completion: nil)
    }
    
    func didAddNewEvent(content: PreviewContent, addNew: Bool, index: NSInteger) {
        if addNew {
            previewContents.append(content)
        } else {
            previewContents[index] = content
        }
        
        savePreviewContent()
        collectionView.reloadData()
    }
    
    // MARK: Init data
    func addData() {
        if let savedPreview = loadPreviewContent() {
            previewContents += savedPreview
        } /*else {
            for i in 0..<30 {
                let title = NSString(format: "Item %ld ", i) as String
                let item = PreviewContent(image: UIImage(named: NSString(format: "image-%ld", i % 10) as String), date: "", title: title as NSString?, folder: "")
                previewContents.append(item)
            }
        }*/
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
        return previewContents.count//events.count//
    }
    
    func collectionView(_ asCollectionView: ASCollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let gridCell = asCollectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GridCell
        let preview = previewContents[indexPath.row]
        //let event = events[indexPath.row]
        gridCell.label.text = preview.title as String?//event.value(forKey: "title") as? String
        gridCell.imageView.image = preview.image//UIImage(named: (event.value(forKey: "image") as? String)!)
        return gridCell
    }
    
    func collectionView(_ asCollectionView: ASCollectionView, parallaxCellForItemAtIndexPath indexPath: IndexPath) -> ASCollectionViewParallaxCell {
        let parallaxCell = asCollectionView.dequeueReusableCell(withReuseIdentifier: "parallaxCell", for: indexPath) as! ParallaxCell
        let preview = previewContents[indexPath.row]
        //let event = events[indexPath.row]
        parallaxCell.label.text = preview.title as String?//event.value(forKey: "title") as? String
        parallaxCell.updateParallaxImage(preview.image!)
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
    
    // MARK: CollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Did tap at index \(indexPath.row)")
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        if (collectionView.indexPathsForSelectedItems?.count)! > 0 {
            let indexPath = collectionView.indexPathsForSelectedItems?.first!
            
            let preview = previewContents[(indexPath?.row)!]
            let imagePreviewCollectionVC = segue.destination as! ImagePreviewCollectionViewController
            imagePreviewCollectionVC.previewContent = preview
        }
    }
    
    // MARK: Action
    private func savePreviewContent() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(previewContents, toFile: PreviewContent.ArchiveURL.path)
        if isSuccessfulSave {
            print("Saved")
            //os_log("PreviewContent successfully saved.", log: OSLog.default, type: .debug)
        } else {
            print("Failed to save")
            //os_log("PreviewContent to save meals...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadPreviewContent() -> [PreviewContent]? {
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: PreviewContent.ArchiveURL.path) as? [PreviewContent]
    }
    
 }
 
 
 

 class GridCell: UICollectionViewCell {
    
    @IBOutlet var label: UILabel!
    @IBOutlet var imageView: UIImageView!
    
 }
 
 class ParallaxCell: ASCollectionViewParallaxCell {
    
    @IBOutlet var label: UILabel!
    
 }
