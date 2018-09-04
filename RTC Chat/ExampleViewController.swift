////
////  ExampleViewController.swift
////  RTC Chat
////
////  Created by Pepe Becker on 15/06/2018.
////  Copyright © 2018 Pepe Becker. All rights reserved.
////
//
//import AVFoundation
//import UIKit
//import WebRTC
////import SocketIO
//import CoreTelephony
////import ReachabilitySwift
//
//let TAG = "ViewController"
//let AUDIO_TRACK_ID = TAG + "AUDIO"
//let LOCAL_MEDIA_STREAM_ID = TAG + "STREAM"
//
//class ExampleViewController: UIViewController, RTCPeerConnectionDelegate, RTCDataChannelDelegate {
//
//    var mediaStream: RTCMediaStream!
//    var localAudioTrack: RTCAudioTrack!
//    var remoteAudioTrack: RTCAudioTrack!
//    var dataChannel: RTCDataChannel!
//    var dataChannelRemote: RTCDataChannel!
//
//    var roomName: String!
//
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do any additional setup after loading the view, typically from a nib.
//
//        initWebRTC();
//        sigConnect(wsUrl: "http://192.168.1.69:3000");
//
//        localAudioTrack = peerConnectionFactory.audioTrack(withTrackId: AUDIO_TRACK_ID)
//        mediaStream = peerConnectionFactory.mediaStream(withStreamId: LOCAL_MEDIA_STREAM_ID)
//        mediaStream.addAudioTrack(localAudioTrack)
//    }
//
//    func getRoomName() -> String {
//        return (roomName == nil || roomName.isEmpty) ? "_defaultroom": roomName;
//    }
//
//    // webrtc
//    var peerConnectionFactory: RTCPeerConnectionFactory! = nil
//    var peerConnection: RTCPeerConnection! = nil
//    var mediaConstraints: RTCMediaConstraints! = nil
//
//    var peerStarted: Bool = false
//
//    func initWebRTC() {
//        RTCInitializeSSL()
//        peerConnectionFactory = RTCPeerConnectionFactory()
//
//        let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "false"]
//        let optionalConstraints = [ "DtlsSrtpKeyAgreement": "true", "RtpDataChannels" : "true", "internalSctpDataChannels" : "true"]
//
//
//        mediaConstraints = RTCMediaConstraints.init(mandatoryConstraints: mandatoryConstraints, optionalConstraints: optionalConstraints)
//
//    }
//
//    func connect() {
//        if (!peerStarted) {
//            sendOffer()
//            peerStarted = true
//        }
//    }
//
//    func hangUp() {
//        sendDisconnect()
//        stop()
//    }
//
//    func stop() {
//        if (peerConnection != nil) {
//            peerConnection.close()
//            peerConnection = nil
//            peerStarted = false
//        }
//    }
//
//    func prepareNewConnection() -> RTCPeerConnection {
//        var icsServers: [RTCIceServer] = []
//
//        icsServers.append(RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"], username:"",credential: ""))
//
//        let rtcConfig: RTCConfiguration = RTCConfiguration()
//        rtcConfig.tcpCandidatePolicy = RTCTcpCandidatePolicy.disabled
//        rtcConfig.bundlePolicy = RTCBundlePolicy.maxBundle
//        rtcConfig.rtcpMuxPolicy = RTCRtcpMuxPolicy.require
//        rtcConfig.iceServers = icsServers;
//
//        peerConnection = peerConnectionFactory.peerConnection(with: rtcConfig, constraints: mediaConstraints, delegate: self)
//        peerConnection.add(mediaStream);
//
//        let tt = RTCDataChannelConfiguration();
//        tt.isOrdered = false;
//
//
//        self.dataChannel = peerConnection.dataChannel(forLabel: "testt", configuration: tt)
//
//        self.dataChannel.delegate = self
//        print("Make datachannel")
//
//        return peerConnection;
//    }
//
//    // RTCPeerConnectionDelegate - begin [ ///////////////////////////////////////////////////////////////////////////////
//
//
//    /** Called when the SignalingState changed. */
//    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState){
//        print("signal state: \(stateChanged.rawValue)")
//    }
//
//
//    /** Called when media is received on a new stream from remote peer. */
//    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream){
//        if (peerConnection == nil) {
//            return
//        }
//
//        if (stream.audioTracks.count > 1) {
//            print("Weird-looking stream: " + stream.description)
//            return
//        }
//    }
//
//    /** Called when a remote peer closes a stream. */
//    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream){}
//
//
//    /** Called when negotiation is needed, for example ICE has restarted. */
//    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection){}
//
//
//    /** Called any time the IceConnectionState changes. */
//    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState){}
//
//
//    /** Called any time the IceGatheringState changes. */
//    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState){}
//
//
//    /** New ice candidate has been found. */
//    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate){
//
//
//        print("iceCandidate: " + candidate.description)
//        let json:[String: AnyObject] = [
//            "type" : "candidate" as AnyObject,
//            "sdpMLineIndex" : candidate.sdpMLineIndex as AnyObject,
//            "sdpMid" : candidate.sdpMid as AnyObject,
//            "candidate" : candidate.sdp as AnyObject
//        ]
//        sigSendIce(msg: json as NSDictionary)
//
//    }
//
//
//    /** Called when a group of local Ice candidates have been removed. */
////    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]){}
//
//
//    /** New data channel has been opened. */
//    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel){
//        print("Datachannel is open, name: \(dataChannel.label)")
//        dataChannel.delegate = self
//        self.dataChannelRemote = dataChannel
//    }
//
//
//
//    // RTCPeerConnectionDelegate - end ]/////////////////////////////////////////////////////////////////////////////////
//
//    public func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer){
//        print("iets ontvangen");
//    }
//
//    public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel){
//        print("channel.state \(dataChannel.readyState.rawValue)");
//    }
//
//
//    func sendData(message: String) {
//        let newData = message.data(using: String.Encoding.utf8)
//        let dataBuff = RTCDataBuffer(data: newData!, isBinary: false)
//        self.dataChannel.sendData(dataBuff)
//    }
//
//    func onOffer(sdp:RTCSessionDescription) {
//        print("on offer shizzle")
//
//        setOffer(sdp: sdp)
//        sendAnswer()
//        peerStarted = true;
//    }
//
//    func onAnswer(sdp:RTCSessionDescription) {
//        setAnswer(sdp: sdp)
//    }
//
//    func onCandidate(candidate:RTCIceCandidate) {
//        peerConnection.add(candidate)
//    }
//
//    func sendSDP(sdp:RTCSessionDescription) {
//        print("Converting sdp...")
//        let json:[String: AnyObject] = [
//            "type" : sdp.type.rawValue as AnyObject,
//            "sdp"  : sdp.sdp.description as AnyObject
//        ]
//
//        sigSend(msg: json as NSDictionary);
//    }
//
//    func sendOffer() {
//        peerConnection = prepareNewConnection();
//        peerConnection.offer(for: mediaConstraints) { (RTCSessionDescription, Error) in
//
//            if(Error == nil){
//                print("send offer")
//
//                self.peerConnection.setLocalDescription(RTCSessionDescription!, completionHandler: { (Error) in
//                    print("Sending: SDP")
//                    print(RTCSessionDescription as Any)
//                    self.sendSDP(sdp: RTCSessionDescription!)
//                })
//            } else {
//                print("sdp creation error: \(Error)")
//            }
//
//        }
//    }
//
//
//    func setOffer(sdp:RTCSessionDescription) {
//        if (peerConnection != nil) {
//            print("peer connection already exists")
//        }
//        peerConnection = prepareNewConnection();
//        peerConnection.setRemoteDescription(sdp) { (Error) in
//
//        }
//    }
//
//    func sendAnswer() {
//        print("sending Answer. Creating remote session description...")
//        if (peerConnection == nil) {
//            print("peerConnection NOT exist!")
//            return
//        }
//
//        peerConnection.answer(for: mediaConstraints) { (RTCSessionDescription, Error) in
//            print("ice shizzle")
//
//            if(Error == nil){
//                self.peerConnection.setLocalDescription(RTCSessionDescription!, completionHandler: { (Error) in
//                    print("Sending: SDP")
//                    print(RTCSessionDescription as Any)
//                    self.sendSDP(sdp: RTCSessionDescription!)
//                })
//            } else {
//                print("sdp creation error: \(Error)")
//            }
//
//        }
//    }
//
//    func setAnswer(sdp:RTCSessionDescription) {
//        if (peerConnection == nil) {
//            print("peerConnection NOT exist!")
//            return
//        }
//
//        peerConnection.setRemoteDescription(sdp) { (Error) in
//            print("remote description")
//        }
//    }
//
//    func sendDisconnect() {
//        let json:[String: AnyObject] = [
//            "type" : "user disconnected" as AnyObject
//        ]
//        sigSend(msg: json as NSDictionary);
//    }
//
//    // websocket related operations
//    func sigConnect(wsUrl:String) {
//        socket.on("message") { (data, emitter) in
//            if (data.count == 0) {
//                return
//            }
//
//            let json = data[0] as! NSDictionary
//            print("WSS->C: " + json.description);
//
//            let type = json["type"] as! Int
//
//            if (type == RTCSdpType.offer.rawValue) {
//                print("Received offer, set offer, sending answer....");
//                let sdp = RTCSessionDescription(type: RTCSdpType(rawValue: type)!, sdp: json["sdp"] as! String)
//                self.onOffer(sdp: sdp);
//            } else if (type == RTCSdpType.answer.rawValue && self.peerStarted) {
//                print("Received answer, setting answer SDP");
//                let sdp = RTCSessionDescription(type: RTCSdpType(rawValue: type)!, sdp: json["sdp"] as! String)
//                self.onAnswer(sdp: sdp);
//            } else {
//                print("Unexpected websocket message");
//            }
//        }
//
//        socket.on("ice") { (data, emitter) in
//            if (data.count == 0) {
//                return
//            }
//
//            let json = data[0] as! NSDictionary
//            print("WSS->C: " + json.description);
//
//            let type = json["type"] as! String
//
//
//            if (type == "candidate" && self.peerStarted) {
//                print("Received ICE candidate...");
//                let candidate = RTCIceCandidate(
//                    sdp: json["candidate"] as! String,
//                    sdpMLineIndex: Int32(json["sdpMLineIndex"] as! Int),
//                    sdpMid: json["sdpMid"] as? String)
//                self.onCandidate(candidate: candidate);
//            } else {
//                print("Unexpected websocket message");
//            }
//        }
//
//        socket.connect();
//    }
//
//    func sigRecoonect() {
//        socket.disconnect();
//        socket.connect();
//    }
//
//    func sigSend(msg:NSDictionary) {
//        socket.emit("message", msg)
//    }
//
//    func sigSendIce(msg:NSDictionary) {
//        socket.emit("ice", msg)
//    }
//}
