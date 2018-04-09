//
//  AppDelegate.swift
//  MenuBarApp
//
//  Created by Wallace Wang on 1/10/17.
//  Copyright © 2018 Luigi Pizzolito. All rights reserved.
//

import Cocoa
import CoreLocation

var Updates = true
var timerDelay = 600.00

struct Weather {

    var city: String
    var currentTemp: Float
    var minTemp: Float
    var maxTemp: Float
    var humidity: Float
    var conditions: String
    
//    var description: String {
//        return "\(city): \(currentTemp)°C and \(conditions)"
//    }
}

var menu = NSMenu()
var item = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
var units = "metric"
var UnitsCounter = 0
var weatherS = Weather(
    city: "null",
    currentTemp: 0.00,
    minTemp: 0.00,
    maxTemp: 0.00,
    humidity: 0.00,
    conditions: "null"
)

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    var item : NSStatusItem? = nil
    var manager:CLLocationManager!
    
    var gameTimer: Timer!
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
//        startReceivingLocationChanges()
        
        
        
        manager = CLLocationManager()
        manager.delegate = self as? CLLocationManagerDelegate
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
        
        
        //update timer..
        
        gameTimer = Timer.scheduledTimer(timeInterval: timerDelay, target: self, selector: #selector(resumeTimer), userInfo: nil, repeats: true)
        
        
        let _ : Timer! = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(updateTemp), userInfo: nil, repeats: false)
        
        updateTemp()
    }
    func locationManager(manager:CLLocationManager, didUpdateLocations locations:    [AnyObject]) { // Updated to current array syntax [AnyObject] rather than  AnyObject[]
        NSLog("location changed")
        updateTemp()
    }
    func locationManager(manager:CLLocationManager, didChangeAuthorization locations:    [AnyObject]) { // Updated to current array syntax [AnyObject] rather than  AnyObject[]
        NSLog("permissions changed")
        updateTemp()
    }
    
    func updateTemp() {

        print ("It works!")

        NSLog(" got coord")
        
        
        
        if (manager.location?.coordinate.longitude != nil && manager.location?.coordinate.latitude != nil) {
            WeatherAPI().fetchWeather((manager.location?.coordinate.longitude.description)!, (manager.location?.coordinate.latitude.description)!)
            print("Lon: \(String(describing: manager.location?.coordinate.longitude)) Lat: \(String(describing: manager.location?.coordinate.latitude))")
        } else {
            WeatherAPI().fetchWeather("0.00", "0.00")
            print("no cords")
        }
        
    }
        
    
    func quitMe() {
        NSApplication.shared().terminate(self)
    }
    
    func clicked() {
        if (String(describing: manager.location?.coordinate.longitude) != "nil" && String(describing: manager.location?.coordinate.latitude) != "nil") {
            NSWorkspace.shared().open(NSURL(string: "https://maps.google.com/?q=\((manager.location?.coordinate.latitude.description)!),\((manager.location?.coordinate.longitude.description)!)")! as URL)
        } else {
            NSWorkspace.shared().open(NSURL(string: "https://maps.google.com/?q=0.00, 0.00")! as URL)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        manager.stopUpdatingLocation()
    }
    
    func UpdateUnits() {
        UnitsCounter += 1
        switch UnitsCounter {
        case 0:
            units = "metric"
        case 1:
            units = "imperial"
        case 2:
            units = ""
        case 3:
            UnitsCounter = -1
            UpdateUnits()
        default: break
        }
        NSLog(UnitsCounter.description)
        NSLog(units)
        updateTemp()
    }
    
    func toggleUpdates() {
        if (Updates == true) {
            gameTimer.invalidate()
            manager.stopUpdatingLocation()
            Updates = false
            menu.item(at: 5)?.title = "Turn \(Updates ? "Off" : "On") Temperature Updates"
            item?.menu = menu
        } else {
            manager.startUpdatingLocation()
            gameTimer = Timer.scheduledTimer(timeInterval: timerDelay, target: self, selector: #selector(resumeTimer), userInfo: nil, repeats: true)
            Updates = true
        }
    }
    
    func done() {
        manager.stopUpdatingLocation()
        NSLog("sleeping location")
    }

    func resumeTimer() {
        NSLog("waking location")
        manager.startUpdatingLocation()
        
        let _: Timer! = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(updateTemp), userInfo: nil, repeats: false)
        let _: Timer! = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(done), userInfo: nil, repeats: false)
    }

}

class WeatherAPI {
    let API_KEY = "af74098a4ccb70d1cf90703d5c1cd5d7"
    let BASE_URL = "http://api.openweathermap.org/data/2.5/weather"
    
    func fetchWeather(_ lon: String, _ lat: String) {
        
        item.title = "--"
        menu.removeAllItems()
        menu.autoenablesItems = false
//        menu.addItem(NSMenuItem(title: "Updating...", action: #selector(AppDelegate.clicked), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Retry Update", action: #selector(AppDelegate.updateTemp), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit TinyTemp", action: #selector(AppDelegate.quitMe), keyEquivalent: "q"))
//        menu.item(at: 0)?.isEnabled = false
        item.menu = menu
        
        let session = URLSession.shared
        // url-escape the query string we're passed
        //let escapedQuery = query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let url = URL(string: "\(BASE_URL)?APPID=\(API_KEY)&units=\(units)&lon=\(lon)&lat=\(lat)")
        let task = session.dataTask(with: url!) { data, response, err in
            // first check for a hard error
            if let error = err {
                NSLog("weather api error: \(error)")
                AppDelegate().updateTemp()
            }
            
            // then check the response code
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200: // all good!
                    if let weather = self.weatherFromJSONData(data!) {
                        NSLog("Got Temp: \(Int(weather.currentTemp))°")
                        
                        
                        item.title = "\(Int(weather.currentTemp))°"
                        
                        menu.removeAllItems()
                        menu.autoenablesItems = false
                        
                        menu.addItem(NSMenuItem(title: "Area: \(weather.city)", action: #selector(AppDelegate.clicked), keyEquivalent: ""))
                        menu.addItem(NSMenuItem(title: "Humidity: \(String(describing: Int(weather.humidity)))%", action: #selector(AppDelegate.clicked), keyEquivalent: ""))
                        menu.addItem(NSMenuItem(title: "Weather: \(weather.conditions)", action: #selector(AppDelegate.clicked), keyEquivalent: ""))
                        menu.addItem(NSMenuItem.separator())
                        //menu.addItem(NSMenuItem(title: "Update", action: #selector(AppDelegate.updateTemp), keyEquivalent: ""))
                        var name = ""
                        switch UnitsCounter {
                        case 0:
                            name = "Farenheit"
                        case 1:
                            name = "Kelvin"
                        case 2:
                            name = "Celsius"
                        default: break
                        }
                        menu.addItem(NSMenuItem(title: "Switch to \(name)", action: #selector(AppDelegate.UpdateUnits), keyEquivalent: ""))
                        menu.addItem(NSMenuItem(title: "Turn \(Updates ? "Off" : "On") Updates", action: #selector(AppDelegate.toggleUpdates), keyEquivalent: ""))
                        menu.addItem(NSMenuItem.separator())
                        menu.addItem(NSMenuItem(title: "Quit TinyTemp", action: #selector(AppDelegate.quitMe), keyEquivalent: "q"))
                        
                        
                        menu.item(at: 0)?.isEnabled = false
                        menu.item(at: 1)?.isEnabled = false
                        menu.item(at: 2)?.isEnabled = false
                        
                        item.menu = menu
                        
                        
                    }
                case 401: // unauthorized
                    NSLog("weather api returned an 'unauthorized' response. Did you set your API key?")
                default:
                    NSLog("weather api returned response: %d %@", httpResponse.statusCode, HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                }
            }
        }
        task.resume()
    }
    
    func weatherFromJSONData(_ data: Data) -> Weather? {
        typealias JSONDict = [String:AnyObject]
        let json : JSONDict
        
        do {
            json = try JSONSerialization.jsonObject(with: data, options: []) as! JSONDict
        } catch {
            NSLog("JSON parsing failed: \(error)")
            return nil
        }
        
        var mainDict = json["main"] as! JSONDict
        var weatherList = json["weather"] as! [JSONDict]
        var weatherDict = weatherList[0]
        
        let weather = Weather(
            city: json["name"] as! String,
            currentTemp: mainDict["temp"] as! Float,
            minTemp: mainDict["temp_min"] as! Float,
            maxTemp: mainDict["temp_max"] as! Float,
            humidity: mainDict["humidity"] as! Float,
            conditions: weatherDict["main"] as! String
        )
        
        return weather
    }
    
}
