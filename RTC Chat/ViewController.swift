//
//  ViewController.swift
//  RTC Chat
//
//  Created by Pepe Becker on 12/06/2018.
//  Copyright © 2018 Pepe Becker. All rights reserved.
//

import UIKit
import FirebaseFirestore
import RxSwift

class ViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    var connectionManager: WebRTCConnectionManager?

    @IBOutlet weak var roomIdField: UITextField!
    @IBOutlet weak var startCallButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBAction func joinRoom(_ sender: UIButton) {
        if let text = roomIdField.text, text.count > 0 {
            statusLabel.text = "Joining room..."
            let signallingAdapter = FirebaseSignallingAdapter(roomID: text)
            self.connectionManager = WebRTCConnectionManager(signallingAdapter: signallingAdapter)

            if let connectionManager = self.connectionManager {
                listenForStatusChange(connectionManager)
            }

            self.connectionManager?.setupConnection()
            startCallButton.isEnabled = true
            startCallButton.addTarget(self, action: #selector(startCall), for: .touchUpInside)
        } else {
            statusLabel.text = "Please enter a valid room ID"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func listenForStatusChange(_ connectionManager: WebRTCConnectionManager) {
        self.connectionManager?.getStatusSource().subscribe(onNext: { status in
            DispatchQueue.main.async {
                self.statusLabel.text = status
            }
        }).disposed(by: self.disposeBag)
    }

    @objc func startCall() {
        self.statusLabel.text = "Start calling"
        self.connectionManager?.startCall().subscribe(onError: { error in
            DispatchQueue.main.async {
                self.statusLabel.text = "Error: \(error.localizedDescription)"
            }
        }).disposed(by: self.disposeBag)
    }

}

