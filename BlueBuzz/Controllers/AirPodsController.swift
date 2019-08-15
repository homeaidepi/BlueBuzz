//
//  AirPodsController.swift
//  BlueBuzz
//
//  Created by Matthew J Vandergrift on 8/14/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

var manager: CBCentralManager!
var peripheralBLE: CBPeripheral!

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    let deviceName = "AirPods de Iván"
    var isConnected = false
    
    
    @IBOutlet weak var Label: UILabel!
    @IBAction func Click(_ sender: UIButton) {
        self.connect()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func connect()  {
        manager.connect(peripheralBLE, options: nil)
        print("connect")
        self.updateLabelStatus()
    }
    
    func disconnect() {
        manager.cancelPeripheralConnection(peripheralBLE!)
        print("disconnect")
        self.updateLabelStatus()
    }
    
    func updateLabelStatus() {
        switch peripheralBLE.state {
        case.connected:
            Label.text = "connected"
        case.disconnected:
            Label.text = "disconnected"
        case.connecting:
            Label.text = "connecting"
        case.disconnecting:
            Label.text = "disconnecting"
        default:
            Label.text = "label"
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch manager.state {
        case.poweredOff:
            print("BLE service is powered off")
        case.poweredOn:
            print("BLE service is powered on and scanning")
            manager.scanForPeripherals(withServices: nil, options: nil)
        default:
            print("BLE service in another state")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == deviceName && isConnected == false {
            print("found AirPods \(peripheral)")
            peripheralBLE = peripheral
            peripheralBLE!.delegate = self
            manager.stopScan()
            self.updateLabelStatus()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("AirPods Connected")
        peripheral.discoverServices(nil)
        self.updateLabelStatus()
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        print("AirPods Connect error")
        print(error)
        self.updateLabelStatus()
    }
}
