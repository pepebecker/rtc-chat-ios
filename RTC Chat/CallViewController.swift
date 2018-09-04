//
//  CallViewController.swift
//  RTC Chat
//
//  Created by Pepe Becker on 15/06/2018.
//  Copyright © 2018 Pepe Becker. All rights reserved.
//

import UIKit
import WebRTC

class CallViewController: UIViewController {

    @IBOutlet weak var remoteVideoView: RTCEAGLVideoView!
    @IBOutlet weak var localVideoView: RTCEAGLVideoView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
