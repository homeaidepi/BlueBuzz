/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The commands view controller of the iOS app.
*/

import UIKit
import WatchConnectivity
import Foundation

class CommandsViewController: UITableViewController, TestDataProvider, SessionCommands {
    func updateApplicationContext(applicationContext: [String : Any]) {
        return;
    }
    
    
    // List the supported methods, shown in the main table.
    //
    //let commands: [Command] = [.updateAppConnection, .sendMessage, .sendMessageData]
    let commands: [Command] = [.sendMessageData]
    
    var currentCommand: Command = .sendMessageData // Default to .sendMessageData.
    var currentColor: UIColor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 42

        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).dataDidFlow(_:)),
            name: .dataDidFlow, object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // .dataDidFlow notification handler. Update the UI with the notification object.
    //
    @objc
    func dataDidFlow(_ notification: Notification) {
        if let commandStatus = notification.object as? CommandStatus {
            currentCommand = commandStatus.command
            currentColor = commandStatus.timedColor.color.color
            tableView.reloadData()
        }
    }
}

extension CommandsViewController { // MARK: - UITableViewDelegate and UITableViewDataSource.
    
    // Create a button for the specified command and with the title color.
    // The button is used as the accessory view of the table cell.
    //
    private func newAccessoryView(cellCommand: Command, titleColor: UIColor?) -> UIButton {
        
        // Create and configure the button.
        //
        let button = UIButton(type: .roundedRect)
        //button.addTarget(self, action: #selector(type(of: self).showTransfers(_:)), for: .touchUpInside)
        button.setTitleColor(titleColor, for: .normal)
        button.sizeToFit()
        return button
    }
    

    // UITableViewDelegate and UITableViewDataSource.
    //
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commands.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommandCell", for: indexPath)
        
        let cellCommand = commands[indexPath.row]
        
        let commandPhrase = cellCommand.rawValue
        
        let red = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let green = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let blue = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        
        let randomColor = UIColor(red: red, green: green, blue: blue, alpha: 1)
        
        let textColor: UIColor? = cellCommand == currentCommand ? currentColor : nil
        cell.textLabel?.textColor = textColor
        cell.textLabel?.text = commandPhrase
        
        cell.detailTextLabel?.textColor = randomColor
        cell.detailTextLabel?.text = nil
        cell.accessoryView = nil
        
        return cell
    }
    
    // Do the command associated with the selected table row.
    //
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentCommand = commands[indexPath.row]
        switch currentCommand {
            case .sendMessageData: sendMessageData(messageData, location: testLocation, instanceId: SessionDelegater().getInstanceIdentifier(), deviceId: "ios")
        case .updateAppConnection: updateApplicationContext(applicationContext: SessionDelegater().getSettings())
            
        }
    }
}

class CommandPhrase: NSObject {
    var id: String?
    var phrase: String?
    var command: String?
    var location: (lat: Double, long: Double)?
    var deviceId: String?
    var secCheckLocation: Int?
    var secCheckDistance: Int?
    var distanceBeforeNotifying: Double?
    var timeStamp: Date?
}

enum SerializationError: Error {
    case missing(String)
    case invalid(String, Any)
}

extension NSObject{
    convenience init(jsonStr:String) {
        self.init()
        
        if let jsonData = jsonStr.data(using: String.Encoding.utf8, allowLossyConversion: false)
        {
            do {
                let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: AnyObject]
                
                // Loop
                for (key, value) in json {
                    let keyName = key as String
                    let keyValue: String = value as! String
                    
                    self.setValue(keyValue, forKey: keyName)
                }
                
            } catch let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
            }
        }
        else
        {
            print("json is of wrong format!")
        }
    }
}
