//
//  WebRTCConnectionManager.swift
//  RTC Chat
//
//  Created by Pepe Becker on 22.02.2018.
//  Copyright © 2018 Pepe Becker. All rights reserved.
//

import UIKit
import RxSwift
import WebRTC

public class WebRTCConnectionManager: NSObject {

    // MARK: Properties
    
    private let _signallingAdapter: SignallingAdapter
    private let _disposeBag: DisposeBag
    private let _statusSource = PublishSubject<String>()

    private var _connection: RTCPeerConnection?
    private var _dataChannel: RTCDataChannel?
    
    lazy var defaultConstraints: RTCMediaConstraints = {
        let constraints = [
            "OfferToReceiveAudio": "true"
            //,"OfferToReceiveVideo": "true"
        ]
        return RTCMediaConstraints(mandatoryConstraints: constraints, optionalConstraints: nil)
    }()

    // MARK: - Basic Functions

    func getStatusSource() -> PublishSubject<String> {
        return self._statusSource
    }

    func updateStatus(_ status: String) {
        self._statusSource.onNext(status)
    }
    
    func updateStatus(_ error: Error) {
        self.updateStatus(error)
    }

    init(signallingAdapter: SignallingAdapter) {
        self._statusSource.onNext("Initializing...")
        self._signallingAdapter = signallingAdapter
        self._disposeBag = DisposeBag()
        self._statusSource.onNext("Initialized")
    }
    
    func setupConnection(withVideo: Bool = false) {
        self.endCall()
        self.updateStatus("Seting up connection...")
        self._connection = WebRTCManager.shared.connection(withConstraints: self.defaultConstraints, delegate: self)
        let audioStream = WebRTCManager.shared.lazyLocalAudioStream
        if let connection = self._connection {
            self.updateStatus("Successfully setup connection")
            self._connection?.add(audioStream)
            self.listenForRemoteOffers(connection: connection)
        } else {
            self.updateStatus("Failed to setup connection")
        }
    }
    
    func startCall() -> Completable {
        self.updateStatus("Start callling")
        return Completable.create(subscribe: { completable in
            guard let connection = self._connection else {
                completable(.error(RTCError.SetupCallFailed))
                return Disposables.create()
            }
            
            self.createOffer(connection).subscribe(onSuccess: { description in

                self.setLocalDescription(connection: connection, description: description).subscribe(onCompleted: {

                    self.updateStatus("Sending offer to server...")
                    self._signallingAdapter.sendOffer(description.sdp).subscribe(onCompleted: {
    
                        completable(.completed)
                        self.listenForRemoteAnswers(connection: connection)

                    }, onError: { error in
                        completable(.error(error))
                    }).disposed(by: self._disposeBag)

                }, onError: { error in
                    completable(.error(error))
                }).disposed(by: self._disposeBag)

            }, onError: { error in
                completable(.error(error))
            }).disposed(by: self._disposeBag)

            return Disposables.create()
        })
    }

    func endCall() {
        self.updateStatus("Ending call...")
        self._connection?.close()
        self._connection = nil
        self.updateStatus("Call ended")
    }

    // MARK: - Helper Functions
    
    private func createOffer(_ connection: RTCPeerConnection) -> Single<RTCSessionDescription> {
        _statusSource.onNext("Creating offer...")
        return Single<RTCSessionDescription>.create(subscribe: { single in
            connection.offer(for: self.defaultConstraints, completionHandler: { description, error in
                if let error = error {
                    single(.error(error))
                } else if let description = description {
                    single(.success(description))
                    self.updateStatus("Successfully created offer")
                } else {
                    single(.error(RTCError.DescriptionIsNil))
                }
            })
            return Disposables.create()
        })
    }
    
    private func createAnswer(_ connection: RTCPeerConnection) -> Single<RTCSessionDescription> {
        self.updateStatus("Creating answer...")
        return Single<RTCSessionDescription>.create(subscribe: { single in
            connection.answer(for: self.defaultConstraints, completionHandler: { description, error in
                if let error = error {
                    single(.error(error))
                } else if let description = description {
                    self.updateStatus("Successfully created answer")
                    single(.success(description))
                } else {
                    single(.error(RTCError.DescriptionIsNil))
                }
            })
            return Disposables.create()
        })
    }
    
    private func setLocalDescription(connection: RTCPeerConnection, description: RTCSessionDescription) -> Completable {
        self.updateStatus("Setting local description...")
        return Completable.create(subscribe: { completable in
            connection.setLocalDescription(description, completionHandler: { error in
                if let error = error {
                    completable(.error(error))
                } else {
                    self.updateStatus("Successfully set local description")
                    completable(.completed)
                }
            })
            return Disposables.create()
        })
    }

    private func setRemoteDescription(connection: RTCPeerConnection, description: RTCSessionDescription) -> Completable {
        self.updateStatus("Setting remote description...")
        return Completable.create(subscribe: { completable in
            connection.setRemoteDescription(description, completionHandler: { error in
                if let error = error {
                    completable(.error(error))
                } else {
                    self.updateStatus("Successfully set remote description")
                    completable(.completed)
                }
            })
            return Disposables.create()
        })
    }
    
    private func sendCandidate(_ candidate: RTCIceCandidate) -> Completable {
        let data: [String: Any] = [
            "sdp": candidate.sdp,
            "sdpMid": candidate.sdpMid as Any,
            "sdpMLineIndex": candidate.sdpMLineIndex
        ]
        return self._signallingAdapter.sendCandidate(data)
    }
    
    private func sendText(_ text: String) -> Completable {
        return Completable.create(subscribe: { completable in
            if let dataChannel = self._dataChannel, let data = text.data(using: .utf8) {
                let buffer = RTCDataBuffer(data: data, isBinary: true)
                if (dataChannel.sendData(buffer)) {
                    completable(.completed)
                } else {
                    completable(.error(RTCError.FailedToSendData))
                }
            } else {
                completable(.error(RTCError.DataChannelIsNil))
            }
            return Disposables.create()
        })
    }

    // MARK: - Listening

    private func listenForRemoteOffers(connection: RTCPeerConnection) {
        self.updateStatus("Start listening for remote offers...")
        self._signallingAdapter.getRemoteOfferSource().subscribe(onNext: { data in
            self.updateStatus("Received remote offer")
            let description = RTCSessionDescription(type: RTCSdpType.offer, sdp: data)
            self.setRemoteDescription(connection: connection, description: description).subscribe(onCompleted: {
                self.createAnswer(connection).subscribe(onSuccess: { description in
                    self.setLocalDescription(connection: connection, description: description).subscribe(onCompleted: {
                        self.updateStatus("Sending answer to server...")
                        self._signallingAdapter.sendAnswer(description.sdp).subscribe(onCompleted: {
                            self.updateStatus("Successfully sent answer to server")
                            self.listenForRemoteCandidates(connection: connection)
                        }, onError: { error in
                            self.updateStatus(error)
                        }).disposed(by: self._disposeBag)
                    }, onError: { error in
                        self.updateStatus(error)
                    }).disposed(by: self._disposeBag)
                }, onError: { error in
                    self.updateStatus(error)
                }).disposed(by: self._disposeBag)
            }, onError: { error in
                self.updateStatus(error)
            }).disposed(by: self._disposeBag)
        }, onError: { error in
            self.updateStatus(error)
        }).disposed(by: self._disposeBag)
    }

    private func listenForRemoteAnswers(connection: RTCPeerConnection) {
        self.updateStatus("Start listening for remote answers...")
        self._signallingAdapter.getRemoteAnswerSource().subscribe(onNext: { data in
            self.updateStatus("Received remote answer")
            let description = RTCSessionDescription(type: RTCSdpType.answer, sdp: data)
            self.setRemoteDescription(connection: connection, description: description).subscribe(onCompleted: {
                self.listenForRemoteCandidates(connection: connection)
            }, onError: { error in
                self.updateStatus(error)
            }).disposed(by: self._disposeBag)
        }, onError: { error in
            self.updateStatus(error)
        }).disposed(by: self._disposeBag)
    }

    private func listenForRemoteCandidates(connection: RTCPeerConnection) {
        self.updateStatus("Start listening for remote candidates...")
        self._signallingAdapter.getRemoteCandidateSource().subscribe(onNext: { data in
            self.updateStatus("Received candidate")
            let candidate = RTCIceCandidate(
                sdp: data["sdp"] as! String,
                sdpMLineIndex: Int32(data["sdpMLineIndex"] as! Int),
                sdpMid: data["sdpMid"] as? String
            )
            self._connection?.add(candidate)
        }, onError: { error in
            self.updateStatus(error)
        }).disposed(by: self._disposeBag)
    }

}

// MARK: - RTCPeerConnectionDelegate
extension WebRTCConnectionManager: RTCPeerConnectionDelegate {

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        switch stateChanged {
        case .stable:
            self.updateStatus("Signalling state changed: STABLE")
        case .haveLocalOffer:
            self.updateStatus("Signalling state changed: HAVE LOCAL OFFER")
        case .haveLocalPrAnswer:
            self.updateStatus("Signalling state changed: HAVE LOCAL PR ANSWER")
        case .haveRemoteOffer:
            self.updateStatus("Signalling state changed: HAVE REMOTE OFFER")
        case .haveRemotePrAnswer:
            self.updateStatus("Signalling state changed: HAVE REMOTE PR ANSWER")
        case.closed:
            self.updateStatus("Signalling state changed: CLOSED")
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        self.updateStatus("Added stream")
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        self.updateStatus("Removed stream")
    }

    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
//        self.updateStatus("Negotiating...")
//        self.createOffer(peerConnection).subscribe(onSuccess: { description in
//            self.setLocalDescription(connection: peerConnection, description: description).subscribe(onCompleted: {
//                self.updateStatus("Sending offer to server...")
//                self._signallingAdapter.sendOffer(description.sdp).subscribe(onCompleted: {
//                    self.updateStatus("Successfully negotiated")
//                }, onError: { error in
//                    self.updateStatus(error)
//                }).disposed(by: self._disposeBag)
//            }, onError: { error in
//                self.updateStatus(error)
//            }).disposed(by: self._disposeBag)
//        }, onError: { error in
//            self.updateStatus(error)
//        }).disposed(by: self._disposeBag)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch newState {
        case .new:
            self.updateStatus("Ice connection state changed: NEW")
        case .checking:
            self.updateStatus("Ice connection state changed: CHECKING")
        case .connected:
            self.updateStatus("Ice connection state changed: CONNECTED")
        case .completed:
            self.updateStatus("Ice connection state changed: COMPLETED")
        case .failed:
            self.updateStatus("Ice connection state changed: FAILED")
        case .disconnected:
            self.updateStatus("Ice connection state changed: DISCONNECTED")
        case .closed:
            self.updateStatus("Ice connection state changed: CLOSED")
        case .count:
            self.updateStatus("Ice connection state changed: COUNT")
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        switch newState {
        case .new:
            self.updateStatus("Ice gathering state changed: NEW")
        case .gathering:
            self.updateStatus("Ice gathering state changed: GATHERING")
        case .complete:
            self.updateStatus("Ice gathering state changed: COMPLETE")
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
//        self.updateStatus("Sending candidate...")
        self.sendCandidate(candidate).subscribe(onCompleted: {
//            self.updateStatus("Successfully sent candidate")
        }, onError: { error in
            self._statusSource.onNext("Error: \(error.localizedDescription)")
        }).disposed(by: self._disposeBag)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        self.updateStatus("Removed candidates")
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        self.updateStatus("Opened new data channel")
        self._dataChannel = dataChannel
        self._dataChannel?.delegate = self
    }

}

// MARK: - RTCDataChannelDelegate
extension WebRTCConnectionManager: RTCDataChannelDelegate {

    public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        switch dataChannel.readyState {
        case .connecting:
            self.updateStatus("Data channel changed state: CONNECTING")
        case .open:
            self.updateStatus("Data channel changed state: OPEN")
        case .closing:
            self.updateStatus("Data channel changed state: CLOSING")
        case .closed:
            self.updateStatus("Data channel changed state: CLOSED")
        }
    }

    public func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        let text = String.init(data: buffer.data, encoding: .utf8)
        self.updateStatus("Data channel received message with message: \(text!)")
    }

}
