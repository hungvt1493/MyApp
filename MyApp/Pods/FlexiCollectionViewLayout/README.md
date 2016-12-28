# FlexiCollectionViewLayout

[![CI Status](http://img.shields.io/travis/Deepak Kumar/FlexiCollectionViewLayout.svg?style=flat)](https://travis-ci.org/Deepak Kumar/FlexiCollectionViewLayout)
[![Version](https://img.shields.io/cocoapods/v/FlexiCollectionViewLayout.svg?style=flat)](http://cocoapods.org/pods/FlexiCollectionViewLayout)
[![License](https://img.shields.io/cocoapods/l/FlexiCollectionViewLayout.svg?style=flat)](http://cocoapods.org/pods/FlexiCollectionViewLayout)
[![Platform](https://img.shields.io/cocoapods/p/FlexiCollectionViewLayout.svg?style=flat)](http://cocoapods.org/pods/FlexiCollectionViewLayout)

## Summary

FlexiCollectionViewLayout is a subclass of UICollectionViewLayout for creating a vertical flow layout with different size items. Idea is to make it dynamic and make it work like the photos section in Messages App. Apps using the layout can define what size of the items that they need and can get the results as shwon in screenshots. This layout will be useful for photos, Media(movies or videos) kind of applications where you can have a fancy layout and stand out in a croud of million apps in app store. Apps can use a bigger size items for prominent cells and probably less height but spanning whole width cell for navigational or advertisement items.

## Screen Shots
------------
iPhone:

![Screenshot](https://github.com/dPackumar/FlexiCollectionViewLayout/blob/master/screenshots/iPhone.jpg)

iPad:

![Screenshot](https://github.com/dPackumar/FlexiCollectionViewLayout/blob/master/screenshots/iPad.jpg)

## Features

* Supports Header and Footer Views
* Supports iOS 8+
* Great performance, even with thousands of items the load time is negligible and smooth scrolling
* Simple to use, just implementing one required method is all thats needed
* Supports multitasking very well
* Helps achieve very flexible and different looking layout with many columns and different width and height items


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

* Cocoapods:

FlexiCollectionViewLayout is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "FlexiCollectionViewLayout"
```
* Manual:

Add the FlexiCollectionViewLayout.swift to your project and thats all is needed.

## Author

Deepak Kumar, deepak.hebbar@gmail.com

## License

FlexiCollectionViewLayout is available under the MIT license. See the LICENSE file for more info.
