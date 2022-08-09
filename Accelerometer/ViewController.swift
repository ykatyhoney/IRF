//
//  ViewController.swift
//  Accelerometer
//
//  Created by Dante Capaldi on 2019-09-01.

import UIKit
import Charts
import CoreMotion
import MessageUI

class ViewController: UIViewController, MFMailComposeViewControllerDelegate{
    
    let csvExporter = CSVExporter()
    var isRecording = false
    
    @IBOutlet weak var sendEmail: UIButton!
    
    @IBAction func sendEmail(_ sender: Any){
        if isRecording {
            exportAccelerometerData()
        } else {
            recordAccelerometerData()
        }
    }
    
    func recordAccelerometerData() {
        self.sendEmail.setTitle("Export", for: .normal)
        isRecording = true
        //add header to csv data
        csvExporter.addToCSVData("time,signal")
    }
    
    func exportAccelerometerData() {
        //stop recording
        isRecording = false
        //set button title back to "start recording"
        self.sendEmail.setTitle("Start Recording", for: .normal)
        let path = csvExporter.storeCSVData()
        let vc = UIActivityViewController(activityItems: [path!], applicationActivities: [])
        vc.excludedActivityTypes = [
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.postToTencentWeibo,
            UIActivity.ActivityType.postToTwitter,
            UIActivity.ActivityType.postToFacebook,
            UIActivity.ActivityType.openInIBooks
        ]
        self.present(vc, animated: true, completion: nil)
        csvExporter.eraseCSVData()
    }
    
    @IBOutlet weak var counterView: CounterView!
    @IBOutlet weak var counterLabel: UILabel!
    
    @IBOutlet weak var counterViewRef: CounterView!
    @IBOutlet weak var counterLabelRef: UILabel!
    
    var counter = 0
    var timer = Timer()
    var motionManager = CMMotionManager()
    var roll = Double(0)
    var pitch = Double(0)
    var yaw = Double(0)
    
    func degrees(radians:Double) -> Double {
        return 180 / Double.pi * radians
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBOutlet weak var lineChartView: LineChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        motionManager.deviceMotionUpdateInterval = 0.03
        motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) {(data,error) in
            if let myData = data
            {
                let attitude = myData.attitude
                self.roll = self.degrees(radians: attitude.roll)
                self.pitch = self.degrees(radians: attitude.pitch)
                self.yaw = self.degrees(radians: attitude.yaw)
            }
        }
        
        //chart
        self.lineChartView.delegate = self as? ChartViewDelegate
        let set_a: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "Pitch")
        set_a.drawCirclesEnabled = false
        set_a.setColor(UIColor.blue)
        set_a.drawValuesEnabled = false
        self.lineChartView.data = LineChartData(dataSets: [set_a])
        
        //timer
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    
    // add point
    var i = 1
    @objc func updateCounter() {
        
        //chart 1
        self.lineChartView.data?.addEntry(ChartDataEntry(x: Double(i), y: self.pitch), dataSetIndex: 0)
        
        self.lineChartView.notifyDataSetChanged()
        self.lineChartView.legend.enabled = false
        self.lineChartView.moveViewToX(Double(CGFloat(i)))
        self.lineChartView.setVisibleXRange(minXRange: Double(CGFloat(1)), maxXRange: Double(CGFloat(150)))
        counterView.counter = Int(25*(sin(Double.pi * Double(i) / 180 * 5)) + 45)
        counterLabel.text = String(format:"%.f", (25*(sin(Double.pi * Double(i) / 180 * 5)) + 45))
        counterViewRef.counter = Int(abs(self.pitch))
        counterLabelRef.text = String(format:"%.f", abs(self.pitch))
        
        i = i + 1
        if self.isRecording {
            //add values to csv file
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSSS"
            self.csvExporter.addToCSVData("\(formatter.string(from: date)),\(self.pitch)")
        }
    }
}

class CSVExporter {
    var fileName = "output.csv"
    var path: URL?
    var CSVData:String = ""
    init() {
        setup()
    }
    init(withFileName fileName: String) {
        self.fileName = fileName
        setup()
    }
    private func setup() {
        self.path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(self.fileName)
    }
    func addToCSVData(_ data:String) {
        CSVData.append(data)
        CSVData.append("\n")
        print(CSVData)
    }
    func storeCSVData() -> URL? {
        do {
            try self.CSVData.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
            return path!
        } catch {
            print("Failed to create file")
            print("\(error)")
            return nil
        }
    }
    func eraseCSVData() {
        CSVData = ""
    }
}
