//
//  ViewController.swift
//  FIT5120-Hear_The_Sea-Alpha
//
//  Created by Daniel Liu on 15/08/2016.
//  Copyright © 2016 Daniel Liu. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation
import GoogleMaps

class ViewController: UIViewController, CLLocationManagerDelegate, NSURLSessionTaskDelegate {

    @IBOutlet weak var surroundingsButton: UIButton!
    @IBOutlet weak var weatherButton: UIButton!
    
    let weatherAPIKey:String = "248efdeb4891301e4f6eaa3fd72deb6f"
    var weatherTimer:NSTimer!
    let weatherTimerInterval:Double = 60
    var weatherJson:NSDictionary!
    
    let googleMapsAPIKey:String = "AIzaSyDZlPF8XHRD-mLV6jWmxLw_R71g--5zK7E"
    let googlePlacesWebAPIKey:String = "AIzaSyBR8Ygb9wpRKFboDNjUJr4ZCKIvHR__S-M"
    var surroundingsUpdateTimer:NSTimer!
    let surroundingsTimerInterval:Double = 60
    var surroundingsAPIRadius:Int = 500
    var surroundingsJson:NSDictionary!
    
    
    let locationManager = CLLocationManager()
    let synthesizer:AVSpeechSynthesizer = AVSpeechSynthesizer()
    var currentLocation:CLLocationCoordinate2D?
    var urlSessionConfig:NSURLSessionConfiguration!
    var urlSession:NSURLSession!
    var isInit:Bool = true
    var gpsSignalIsWeak:Bool = false
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do all the initial stuff here
        
        // Modify the background color of button
        weatherButton.backgroundColor = UIColor.redColor()
        weatherButton.addTarget(self, action: #selector(self.highlightButton), forControlEvents: UIControlEvents.TouchDown)
        weatherButton.addTarget(self, action: #selector(self.recoverButton), forControlEvents: UIControlEvents.TouchUpInside)
        
        surroundingsButton.backgroundColor = UIColor.blueColor()
        
        // Register Location service
        locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        // Register the timer for weather retrieving
        weatherTimer = NSTimer.scheduledTimerWithTimeInterval(weatherTimerInterval, target: self, selector: #selector(self.updateWeather), userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(weatherTimer, forMode: NSDefaultRunLoopMode)
        
        // Register the timer for surroundings retrieving
        surroundingsUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(surroundingsTimerInterval, target: self, selector: #selector(self.updateSurroundings), userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(surroundingsUpdateTimer, forMode: NSDefaultRunLoopMode)
        
        // Configure the url session
        // First create the urlsession object
        //urlSessionConfig = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("HearTheSeaSession")
        urlSessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        urlSessionConfig.allowsCellularAccess = true
        urlSession = NSURLSession(configuration: urlSessionConfig, delegate: self, delegateQueue: nil)
        
        // Google Maps Code
        GMSServices.provideAPIKey(googleMapsAPIKey)
        // Google Places Code
        
        
    }
    
    // Delegate function of location manager
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = manager.location?.coordinate
        if currentLocation != nil {
            print("Current Location: \(currentLocation!.latitude), \(currentLocation!.longitude), accuracy: \(locations[0].horizontalAccuracy)m")
            if locations[0].horizontalAccuracy > 10 && !self.gpsSignalIsWeak {
                self.gpsSignalIsWeak = true
                narrateInfo("Warning, GPS signal is weak, current location could be inaccurate.")
            }
            if locations[0].horizontalAccuracy < 10 {
                self.gpsSignalIsWeak = false
            }
            if self.isInit {
                self.isInit = false
                self.weatherTimer.fire()
                self.surroundingsUpdateTimer.fire()
            }
        }
        
    }
    
    /* 
        Delegate function of url session - task level
     */
    // This function handles the success response when the app is in background
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        
    }
    
    // This function handles the error
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        
    }
    
    /*
        End of delegate functions of url session
     */
    
    func highlightButton() {
        
    }

    func recoverButton() {
        
    }
    
    func weatherAPIURL() -> NSURL {
        return NSURL(string: "http://api.openweathermap.org/data/2.5/forecast?lat=\(currentLocation!.latitude)&lon=\(currentLocation!.longitude)&units=metric&APPID=\(weatherAPIKey)")!
    }
    
    func updateWeather() {
        print("Update weather!")
        if self.currentLocation != nil {
            let urlSessionTask = urlSession.dataTaskWithRequest(NSURLRequest(URL: weatherAPIURL()), completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) in
                do {
                    self.weatherJson = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                }
                catch {
                    print("Failed to process JSON.")
                    self.weatherJson = nil
                }
            })
            urlSessionTask.resume()
        }
    }
    
    func narrateInfo(info:String) {
        let utterance = AVSpeechUtterance(string: info)
        utterance.pitchMultiplier = 1.8
        utterance.rate = 0.48
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        self.synthesizer.speakUtterance(utterance)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func narrateWeatherBtnClicked(sender: AnyObject) {
        if self.weatherJson != nil {
            print("Generate weather info.")
            narrateInfo("Current city is \(self.weatherJson["city"]!["name"]!!), current temperature is \(Int(self.weatherJson["list"]![0]!["main"]!!["temp"]!! as! NSNumber)) degree celsius.")
        } else {
            self.narrateInfo("The weather data has'n been loaded. Please wait for a minute.")
        }
        
    }

    func surroundingsAPIUrl() -> NSURL{
        return NSURL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(self.currentLocation!.latitude),\(self.currentLocation!.longitude)&radius=\(self.surroundingsAPIRadius)&key=\(self.googlePlacesWebAPIKey)")!
    }
    
    func updateSurroundings() {
        print("Update surroundings!")
        if self.currentLocation != nil {
            let urlSessionTask = urlSession.dataTaskWithRequest(NSURLRequest(URL: surroundingsAPIUrl()), completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) in
                do {
                    self.surroundingsJson = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                    //print(self.surroundingsJson)
                }
                catch {
                    self.surroundingsJson = nil
                }
            })
            urlSessionTask.resume()
        }
    }
    
    @IBAction func surroundingsBtnClicked(sender: AnyObject) {
        if self.surroundingsJson != nil {
            narrateInfo("You are surrounded by ")
            var index = 0
            repeat {
                /*
                var sentence = "a "
                
                var flag = false
                print(self.surroundingsJson["results"]![index]!["types"]!)
                for type in self.surroundingsJson["results"]![index]!["types"]!! as! NSArray {
                    if flag {
                        break
                    }
                    switch type as! String {
                        case "bar": sentence = sentence + "bar "
                        flag = true
                        case "bank": sentence = sentence + "bank "
                        flag = true
                        case "cafe": sentence = sentence + "coffee shop "
                        flag = true
                        case "gym": sentence = sentence + "gym "
                        flag = true
                        case "hospital": sentence = sentence + "hospital "
                        flag = true
                        case "laundry": sentence = sentence + "laundry "
                        flag = true
                        //case "lodging": sentence = sentence + "lodging "
                        //flag = true
                        case "library": sentence = sentence + "library "
                        flag = true
                        case "museum": sentence = sentence + "museum "
                        flag = true
                        case "park": sentence = sentence + "park "
                        flag = true
                        case "parking": sentence = sentence + "car park "
                        flag = true
                        case "pharmacy": sentence = sentence + "pharmacy "
                        flag = true
                        case "police": sentence = sentence + "police station "
                        flag = true
                        case "school": sentence = sentence + "school "
                        flag = true
                        case "shopping_mall": sentence = sentence + "shopping mall "
                        flag = true
                        case "store": sentence = sentence + "store "
                        flag = true
                        case "university": sentence = sentence + "university "
                        flag = true
                        case "zoo": sentence = sentence + "zoo "
                        flag = true
                        default: break
                    }
                }
                if !flag {
                    index += 1
                    continue
                }
                print(sentence + "called \(self.surroundingsJson["results"]![index]!["name"]!!)")
                narrateInfo(sentence + "called \(self.surroundingsJson["results"]![index]!["name"]!!)")
                */
                narrateInfo(" \(self.surroundingsJson["results"]![index]!["name"]!!)")
                index += 1
            }while(index < 5)
            
        }
        
    }
}

