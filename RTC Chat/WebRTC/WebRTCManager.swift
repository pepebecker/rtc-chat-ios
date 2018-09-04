//
//  WebRTCManager.swift
//  RTC Chat
//
//  Created by Pepe Becker on 16/02/2018.
//  Copyright © 2018 Pepe Becker. All rights reserved.
//

import Foundation
import WebRTC

public class WebRTCManager {

    static let shared = WebRTCManager()

    private let _factory: RTCPeerConnectionFactory
    private let _streamName: String
    private var _audioStream: RTCMediaStream
    private var _videoStream: RTCMediaStream

    private lazy var _localAudioTrack: RTCAudioTrack = {
        let audioTrackName = "audio0_\(self._streamName)"
        return self._factory.audioTrack(withTrackId: audioTrackName)
    }()

    private lazy var _localVideoTrack: RTCVideoTrack = {
        let videoTrackName = "video0_\(self._streamName)"
        let videoSource = self._factory.videoSource()
        let capturer = RTCCameraVideoCapturer(delegate: videoSource)
        return self._factory.videoTrack(with: videoSource, trackId: videoTrackName)
    }()

    lazy var lazyLocalAudioStream: RTCMediaStream = {
        let streamName = "stream0_\(self._streamName)"
        self._audioStream = self._factory.mediaStream(withStreamId: streamName)
        self._audioStream.addAudioTrack(self._localAudioTrack)
        return self._audioStream
    }()

    private lazy var lazyLocalVideoStream: RTCMediaStream = {
        let streamName = "v_stream0_\(self._streamName)"
        self._videoStream = self._factory.mediaStream(withStreamId: streamName)
        self._videoStream.addVideoTrack(self._localVideoTrack)
        return self._videoStream
    }()

    private var iceServers: [RTCIceServer] {
        get {
            let stun = RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
            let turn = RTCIceServer(urlStrings: ["turn:turn.bistri.com:80"], username: "homeo", credential: "homeo")
            return [stun, turn]
        }
    }

    init() {
        RTCPeerConnectionFactory.initialize()
        self._factory = RTCPeerConnectionFactory()

        self._streamName = UI_USER_INTERFACE_IDIOM() == .pad ? "pad" : "phone"
        #if __i386__
            self._streamName = "sim"
        #endif

        self._audioStream = self._factory.mediaStream(withStreamId: self._streamName)
        self._videoStream = self._factory.mediaStream(withStreamId: self._streamName)
    }

    func connection(withConstraints constraints: RTCMediaConstraints, delegate: RTCPeerConnectionDelegate) -> RTCPeerConnection {
        let configuration = RTCConfiguration()
        configuration.iceServers = self.iceServers
        return self._factory.peerConnection(with: configuration, constraints: constraints, delegate: delegate)
    }

    func addAudioStream() {
        self._audioStream.addAudioTrack(self._localAudioTrack)
    }

    func removeAudioStream() {
        self._audioStream.removeAudioTrack(self._localAudioTrack)
    }

    func addVideoStream() {
        self._videoStream.addVideoTrack(self._localVideoTrack)
    }

    func removeVideoStream() {
        self._videoStream.removeVideoTrack(self._localVideoTrack)
    }

}
