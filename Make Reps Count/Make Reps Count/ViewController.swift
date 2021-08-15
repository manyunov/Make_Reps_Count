//
//  ViewController.swift
//  Make Reps Count
//
//  Created by Abhimanyu Das on 7/29/21.
//

import UIKit
import CoreBluetooth
import Foundation
import Charts

struct CBUUIDs{

    static let kBLEService_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
    static let kBLE_Characteristic_uuid_Tx = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
    static let kBLE_Characteristic_uuid_Rx = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"

    static let BLEService_UUID = CBUUID(string: kBLEService_UUID)
    static let BLE_Characteristic_uuid_Tx = CBUUID(string: kBLE_Characteristic_uuid_Tx)//(Property = Write without response)
    static let BLE_Characteristic_uuid_Rx = CBUUID(string: kBLE_Characteristic_uuid_Rx)// (Property = Read/Notify)

}
var timer: Int = 0
var hit = 0, maximum = 0, min = 0, number = 0, curr = 0, sumArray = 0, storeMax = 0
var storeAvg = 0.0
var showGraph = false
var avgArray = 0.0

class ViewController: UIViewController {
    
    var centralManager: CBCentralManager!
    private var bluefruitPeripheral: CBPeripheral!
    private var txCharacteristic: CBCharacteristic!
    private var rxCharacteristic: CBCharacteristic!
    var receivedData = [Int]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        centralManager = CBCentralManager(delegate: self, queue: nil)
        TextField.delegate = self
    }
    
    
    @IBOutlet weak var AppName: UILabel!
    @IBOutlet weak var LineChartBox: LineChartView!
    @IBAction func StartButton(_ sender: Any) {
        showGraph = true
        timer = 0
        receivedData = [Int]()
        sumArray = 0
        avgArray = 0.0
        maximum = 0
    }
    
    @IBAction func SaveButton(_ sender: Any) {
        hit = hit + 1
        if hit%2 == 0{
            Stats2.text = "Muscle group: \(TextField.text!)\nMaximum activation: \(storeMax)\nBaseline activation: \(Int(avgArray))"
        }
        else{
            Stats1.text = "Muscle group: \(TextField.text!)\nMaximum activation: \(storeMax)\nBaseline activation: \(Int(avgArray))"
        }
    }
    
    @IBAction func StopButton(_ sender: Any) {
        showGraph = false
        storeAvg = avgArray
        storeMax = maximum
    }
    
    @IBOutlet weak var TextField: UITextField!
    @IBOutlet weak var Stats1: UILabel!
    @IBOutlet weak var Stats2: UILabel!
    
    func startScanning() -> Void {
      // Start Scanning
      centralManager?.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {

        bluefruitPeripheral = peripheral

        bluefruitPeripheral.delegate = self

        print("Peripheral Discovered: \(peripheral)")
        print("Peripheral name: \(peripheral.name)")
        print ("Advertisement Data : \(advertisementData)")
            
        centralManager?.stopScan()
        centralManager?.connect(bluefruitPeripheral!, options: nil)
       }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
       bluefruitPeripheral.discoverServices([CBUUIDs.BLEService_UUID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            print("*******************************************************")

            if ((error) != nil) {
                print("Error discovering services: \(error!.localizedDescription)")
                return
            }
            guard let services = peripheral.services else {
                return
            }
            //We need to discover the all characteristic
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
            print("Discovered Services: \(services)")
        }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
           
               guard let characteristics = service.characteristics else {
              return
          }

          print("Found \(characteristics.count) characteristics.")

          for characteristic in characteristics {

            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Rx)  {

              rxCharacteristic = characteristic

              peripheral.setNotifyValue(true, for: rxCharacteristic!)
              peripheral.readValue(for: characteristic)

              print("RX Characteristic: \(rxCharacteristic.uuid)")
            }

            if characteristic.uuid.isEqual(CBUUIDs.BLE_Characteristic_uuid_Tx){
              
              txCharacteristic = characteristic
              
              print("TX Characteristic: \(txCharacteristic.uuid)")
            }
          }
    }
    
    func disconnectFromDevice () {
        if bluefruitPeripheral != nil {
        centralManager?.cancelPeripheralConnection(bluefruitPeripheral!)
        }
     }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

          guard characteristic == rxCharacteristic,
          let characteristicValue = characteristic.value,
          let ASCIIstring = NSString(data: characteristicValue, encoding: String.Encoding.utf8.rawValue) else { return }

        for i in 0..<ASCIIstring.length {
            curr = Int(ASCIIstring.character(at: i)) - 48
            number = number*10 + curr
        }

        receivedData.append(number)
        sumArray = sumArray + number
        avgArray = Double(sumArray)/Double(receivedData.count + timer)
        maximum = max(maximum, max(receivedData.max() ?? 0, receivedData.min() ?? 0))
        
        if (receivedData.count > 100) {
            receivedData.removeFirst(receivedData.count-100)
            timer += 1
        }
        
        number = 0
        
        if (showGraph && receivedData.count > 0) {
            graphLineChart(dataArray: receivedData)
        }
    }
    
    func writeOutgoingValue(data: String){
          
        let valueString = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        
        if let bluefruitPeripheral = bluefruitPeripheral {
              
          if let txCharacteristic = txCharacteristic {
                  
            bluefruitPeripheral.writeValue(valueString!, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
              }
          }
      }
    
    func graphLineChart(dataArray: [Int]){
        //define LineChartBox frame origin (screen top left) and dimensions
        LineChartBox.frame = CGRect(x: 0, y: 0,
                                    width: self.view.frame.size.width*0.95,
                                    height: self.view.frame.size.width*0.80)
        
        //center the LineChartBox horizontally and 240 points away from the origin (up)
        LineChartBox.center.x = self.view.center.x
        LineChartBox.center.y = LineChartBox.frame.height/2 + AppName.frame.maxY + 10
        
        LineChartBox.backgroundColor = UIColor.white
        //settings when chart has no data
        LineChartBox.noDataText = "No data available"
        LineChartBox.noDataTextColor = UIColor.black
        LineChartBox.borderColor = UIColor.black
        
        //Initialilze array that will be eventually displayed on the graph
        var entries = [ChartDataEntry]()
        
        //for every element in given dataset, set the X and Y coordinates in a Chart Data entry and append to the list
        for i in 0..<dataArray.count-1 {
            let value = ChartDataEntry(x: 0.1*Double(i+timer), y: Double(dataArray[i]))
            entries.append(value)
        }
        
        //use the entries object and a label string to make a LineChartDataSet object
        let dataSet = LineChartDataSet(entries: entries, label: "Muscle activation")
        
        //customize the graph color settings
        dataSet.drawCirclesEnabled = false
        dataSet.colors = [NSUIColor.black]
        dataSet.drawValuesEnabled = false
        dataSet.lineWidth = 2.0
        
        //make object that will be added to the chart and set it to variable in the storyboard
        let data =  LineChartData(dataSet: dataSet)
        LineChartBox.data = data
        LineChartBox.leftAxis.axisMinimum = 0
        LineChartBox.leftAxis.axisMaximum = 500
        LineChartBox.leftAxis.drawGridLinesEnabled = false
        LineChartBox.rightAxis.drawGridLinesEnabled = false
        LineChartBox.xAxis.drawGridLinesEnabled = false
        LineChartBox.rightAxis.drawLabelsEnabled = false
        LineChartBox.xAxis.labelPosition = .bottom
        LineChartBox.chartDescription?.text = "Live EMG vs Time(s)"
    }
}

extension ViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        TextField.resignFirstResponder()
        return true
    }
}

extension ViewController: CBCentralManagerDelegate {

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    
     switch central.state {
          case .poweredOff:
              print("Is Powered Off.")
          case .poweredOn:
              print("Is Powered On.")
              startScanning()
          case .unsupported:
              print("Is Unsupported.")
          case .unauthorized:
          print("Is Unauthorized.")
          case .unknown:
              print("Unknown")
          case .resetting:
              print("Resetting")
          @unknown default:
            print("Error")
          }
  }

}

extension ViewController: CBPeripheralDelegate {
}

extension ViewController: CBPeripheralManagerDelegate {

  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    switch peripheral.state {
    case .poweredOn:
        print("Peripheral Is Powered On.")
    case .unsupported:
        print("Peripheral Is Unsupported.")
    case .unauthorized:
    print("Peripheral Is Unauthorized.")
    case .unknown:
        print("Peripheral Unknown")
    case .resetting:
        print("Peripheral Resetting")
    case .poweredOff:
      print("Peripheral Is Powered Off.")
    @unknown default:
      print("Error")
    }
  }
}
