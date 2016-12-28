//
//  ImagePreviewCollectionViewController.swift
//  MyApp
//
//  Created by Hung Vuong on 12/1/16.
//  Copyright © 2016 Hung Vuong. All rights reserved.
//

import UIKit
import DKImagePickerController
import AVFoundation
import AVKit
import FlexiCollectionViewLayout

private let reuseIdentifier = "Cell"

class ImagePreviewCollectionViewController: UICollectionViewController, FlexiCollectionViewLayoutDelegate {

    // MARK: Properties
    var previewContent :PreviewContent?
    var assets: [DKAsset]?
    var imageArray: NSMutableArray?
    
    var imageFolder: String!
    
    fileprivate let interItemSpacing: CGFloat = 2
    fileprivate let edgeInsets = UIEdgeInsets.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        var documentsDirectoryURL = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let imageFolder = previewContent?.folder
        documentsDirectoryURL += "/" + (imageFolder as! String) + "/"
        self.imageFolder = documentsDirectoryURL
        
        self.preLoadImage()
        
        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        /*let viewFlow = UICollectionViewFlowLayout()
        viewFlow.minimumLineSpacing = 1
        viewFlow.minimumInteritemSpacing = 1
        viewFlow.itemSize = CGSize(width: CGFloat((self.collectionView!.frame.size.width / 3)-2), height: CGFloat((self.collectionView!.frame.size.width / 3)-2))
        self.collectionView!.collectionViewLayout = viewFlow*/
        
        let layout = FlexiCollectionViewLayout()
        collectionView?.collectionViewLayout = layout
        
        self.title = previewContent?.title as String?
        // Do any additional setup after loading the view.
        
        
        let addBarButton = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(addNewBarButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = addBarButton
    }
    
    func preLoadImage() {
        self.imageArray = NSMutableArray()
        
        let folderURL = URL(fileURLWithPath: self.imageFolder, isDirectory: true)
            
        let properties = [URLResourceKey.localizedNameKey,
                          URLResourceKey.creationDateKey, URLResourceKey.localizedTypeDescriptionKey]
        let fileManager = FileManager.default
        do {
            let imageURLs = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: properties, options:FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            
            print("image URLs: \(imageURLs)")
            // Create image from URL
            if imageURLs.count > 0 {
                for imageUrl in imageURLs {
                    let image =  UIImage(data: NSData(contentsOf: imageUrl)! as Data)
                    self.imageArray?.add(image!)
                }
            }
        } catch let error1 as NSError {
            print(error1.description)
        }
    }

    fileprivate func cellWidth() -> CGFloat {
        return (self.collectionView!.bounds.size.width - (interItemSpacing * 2) - edgeInsets.left - edgeInsets.right ) / 3
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: Bar button action
    func addNewBarButtonTapped(_ sender: UIBarButtonItem) {
        let pickerController = DKImagePickerController()
        pickerController.assetType = DKImagePickerControllerAssetType.allAssets
        pickerController.singleSelect = false
        
        pickerController.didSelectAssets = { (assets: [DKAsset]) in
            self.assets = assets
            
            for asset in self.assets! {
                
                asset.fetchOriginalImage(true, completeBlock: { image, info in
                    self.imageArray?.add(image)
                    
                    let currentTime = Date().timeIntervalSinceNow
                    //let processName = ProcessInfo.processInfo.globallyUniqueString
                    let fileURL = URL(fileURLWithPath: self.imageFolder).appendingPathComponent(NSString(format: "image-%d%ld.jpeg", (self.imageArray?.count)!,currentTime) as String)
                    
                    asset.fetchOriginalImageWithCompleteBlock({ image, info in
                        if !FileManager.default.fileExists(atPath: fileURL.path) {
                            do {
                                try UIImageJPEGRepresentation(image!, 0)!.write(to: fileURL)
                                print("Image Added Successfully")
                            } catch {
                                print(error)
                            }
                        } else {
                            print("Image Did Add")
                        }
                    })
                    
                })
            }
            
            self.collectionView?.reloadData()
        }
        
        self.present(pickerController, animated: true, completion: nil)
    }
    
    func playVideo(_ asset: AVAsset) {
        let avPlayerItem = AVPlayerItem(asset: asset)
        
        let avPlayer = AVPlayer(playerItem: avPlayerItem)
        let player = AVPlayerViewController()
        player.player = avPlayer
        
        avPlayer.play()
        
        self.present(player, animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if self.imageArray != nil {
            return (self.imageArray?.count)!
        } else {
            return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let image = self.imageArray![indexPath.row] as! UIImage
        var cell: UICollectionViewCell?
        var imageView: UIImageView?
        
        /*if asset.isVideo {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellVideo", for: indexPath)
            imageView = cell?.contentView.viewWithTag(1) as? UIImageView
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellImage", for: indexPath)
            imageView = cell?.contentView.viewWithTag(1) as? UIImageView
        }*/
        
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellImage", for: indexPath)
        imageView = cell?.contentView.viewWithTag(1) as? UIImageView
        
        if let cell = cell, let imageView = imageView {
            //let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            
            let tag = indexPath.row + 1
            cell.tag = tag
            imageView.image = image
            /*asset.fetchFullScreenImage(true, completeBlock: { image, info in
                if cell.tag == tag {
                    imageView.image = image
                }
            })*/
        }
        
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: CGFloat((collectionView.frame.size.width / 3) - 20), height: CGFloat((collectionView.frame.size.width / 3) - 20))
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: FlexiCollectionViewLayout, sizeForFlexiItemAt indexPath: IndexPath) -> ItemSizeAttributes {
        let size = CGSize(width: cellWidth(), height: 100)
        switch indexPath.row {
        case 0:
            return ItemSizeAttributes(itemSize: size, layoutSize: .large, widthFactor: 2, heightFactor: 2)
        case 1:
            return ItemSizeAttributes(itemSize: size, layoutSize: .regular, widthFactor: 1, heightFactor: 1)
        case 2:
            return ItemSizeAttributes(itemSize: size, layoutSize: .regular, widthFactor: 1, heightFactor: 1)
        case 3:
            return ItemSizeAttributes(itemSize: size, layoutSize: .large, widthFactor: 3, heightFactor: 1)
        case 4:
            return ItemSizeAttributes(itemSize: size, layoutSize: .large, widthFactor: 1, heightFactor: 3)
        case 5:
            return ItemSizeAttributes(itemSize: size, layoutSize: .regular, widthFactor: 1, heightFactor: 1)
        case 6:
            return ItemSizeAttributes(itemSize: size, layoutSize: .regular, widthFactor: 1, heightFactor: 1)
        case 7:
            return ItemSizeAttributes(itemSize: size, layoutSize: .large, widthFactor: 2, heightFactor: 1)
        case 8:
            return ItemSizeAttributes(itemSize: size, layoutSize: .regular, widthFactor: 1, heightFactor: 1)
        case 9:
            return ItemSizeAttributes(itemSize: size, layoutSize: .regular, widthFactor: 1, heightFactor: 1)
        case 10:
            return ItemSizeAttributes(itemSize: size, layoutSize: .large, widthFactor: 1, heightFactor: 2)
        case 11:
            return ItemSizeAttributes(itemSize: size, layoutSize: .large, widthFactor: 2, heightFactor: 2)
        default:
            return ItemSizeAttributes(itemSize: size, layoutSize: .regular, widthFactor: 1, heightFactor: 1)
        }
        
        /**
         if indexPath.item % 6 == 0 {
         return ItemSizeAttributes(itemSize: size, layoutSize: .large, widthFactor: 2, heightFactor: 2)
         }
         return ItemSizeAttributes(itemSize: size, layoutSize: .regular, widthFactor: 1, heightFactor: 1)
         */
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return edgeInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return interItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForFooterInSection section: Int) -> CGFloat {
        return 45
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

    
    func saveImageToDisk() {
        //var documentsDirectoryURL = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        //let imageFolder = previewContent?.folder
        //documentsDirectoryURL += "/" + (imageFolder as! String) + "/"
        
        for asset in self.assets! {
            let currentTime = Date().timeIntervalSinceNow
            //let processName = ProcessInfo.processInfo.globallyUniqueString
            let fileURL = URL(fileURLWithPath: self.imageFolder).appendingPathComponent(NSString(format: "image%ld.jpeg", currentTime) as String)
            
            asset.fetchOriginalImageWithCompleteBlock({ image, info in
                if !FileManager.default.fileExists(atPath: fileURL.path) {
                    do {
                        try UIImageJPEGRepresentation(image!, 0)!.write(to: fileURL)
                        print("Image Added Successfully")
                    } catch {
                        print(error)
                    }
                } else {
                    print("Image Did Add")
                }
            })
        }
        
        self.collectionView?.reloadData()
    }

}
