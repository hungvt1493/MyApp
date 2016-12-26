//
//  AddEventViewController.swift
//  MyApp
//
//  Created by Hung Vuong on 12/21/16.
//  Copyright © 2016 Hung Vuong. All rights reserved.
//

import UIKit

protocol AddEventViewControllerDelegate:class {
    // protocol definition goes here
    func didAddNewEvent(content: PreviewContent, addNew: Bool, index: NSInteger)
}

class AddEventViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    // MARK: Properties
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTf: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var dateLabel: UILabel!
    
    var addNew: Bool!
    var index: NSInteger?
    
    weak var delegate:AddEventViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.isNavigationBarHidden = false
        // Do any additional setup after loading the view.
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(selectImage))
        imageView.addGestureRecognizer(tap)
        imageView.isUserInteractionEnabled = true
        
        datePicker.date = Date()
        dateLabel.text = fromDateToString(date: datePicker.date)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func selectImage() {
        print("Did tap image")
        let actionSheetController: UIAlertController = UIAlertController(title: "Please select", message: nil, preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        let saveActionButton: UIAlertAction = UIAlertAction(title: "Take Photo", style: .default)
        { action -> Void in
            self.takePhoto()
        }
        actionSheetController.addAction(saveActionButton)
        
        let deleteActionButton: UIAlertAction = UIAlertAction(title: "Choose From Library", style: .default)
        { action -> Void in
            self.choosePhoto()
        }
        actionSheetController.addAction(deleteActionButton)
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func takePhoto() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
            let image = UIImagePickerController()
            image.delegate = self
            image.sourceType = .camera;
//            imag.mediaTypes = [kUTTypeImage as String]
            image.allowsEditing = false
            image.modalPresentationStyle = .popover
            self.present(image, animated: true, completion: nil)
        }
    }
    
    func choosePhoto() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary){
            let image = UIImagePickerController()
            image.delegate = self
            image.sourceType = .photoLibrary;
//            imag.mediaTypes = [kUTTypeImage as String]
            image.allowsEditing = false
            image.modalPresentationStyle = .popover
            self.present(image, animated: true, completion: nil)
        }
    }
    
    // MARK: UIImagePicker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerControllerOriginalImage]
        imageView.image = image as! UIImage?
    }
    
    func fromDateToString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        //        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        let dateObj = dateFormatter.string(from: date as Date)
         print("Dateobj: \(dateObj)")
        
        return dateObj as String;
    }
    
    // MARK: Action
    @IBAction func dateChanged(_ sender: Any) {
        dateLabel.text = fromDateToString(date: datePicker.date)
    }
    
    @IBAction func doneBtnTapped(_ sender: Any) {
        let previewContent = PreviewContent(image: imageView.image, date: dateLabel.text! as NSString, title: titleTf.text! as NSString)
        delegate?.didAddNewEvent(content: previewContent, addNew: addNew, index: index!)
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelBtnTapped(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    // MARK: TextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
