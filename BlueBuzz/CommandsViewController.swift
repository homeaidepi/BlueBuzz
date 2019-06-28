/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The commands view controller of the iOS app.
*/

import UIKit
import WatchConnectivity

class CommandsViewController: UITableViewController, TestDataProvider, SessionCommands {

    // List the supported methods, shown in the main table.
    //
    let commands: [Command] = [.updateAppConnection, .sendMessage, .sendMessageData]
    
    var currentCommand: Command = .updateAppConnection // Default to .updateAppConnection.
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
            currentColor = commandStatus.timedColor?.color
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
        //button.setTitle(" \(transferCount) ", for: .normal)
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
        cell.textLabel?.text = cellCommand.rawValue
        
        let textColor: UIColor? = cellCommand == currentCommand ? currentColor : nil
        cell.textLabel?.textColor = textColor
        cell.detailTextLabel?.textColor = textColor
        cell.detailTextLabel?.text = nil
        cell.accessoryView = nil
        
        return cell
    }
    
    // Do the command associated with the selected table row.
    //
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        currentCommand = commands[indexPath.row]
        switch currentCommand {
            case .updateAppConnection: updateAppConnection(appConnection)
            case .sendMessage: sendMessage(message)
            case .sendMessageData: sendMessageData(messageData, location: location)
        }
    }
}

