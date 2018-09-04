//
//  SignallingAdapter.swift
//  RTC Chat
//
//  Created by Pepe Becker on 22/02/2018.
//  Copyright © 2018 Pepe Becker. All rights reserved.
//

import UIKit
import RxSwift

public class SignallingAdapter: NSObject {

    private let _remoteOfferSource = PublishSubject<String>()
    private let _remoteAnswerSource = PublishSubject<String>()
    private let _remoteCandiateSource = PublishSubject<[String: Any]>()

    func getRemoteOfferSource() -> PublishSubject<String> {
        return self._remoteOfferSource
    }
    
    func getRemoteAnswerSource() -> PublishSubject<String> {
        return self._remoteAnswerSource
    }
    
    func getRemoteCandidateSource() -> PublishSubject<[String: Any]> {
        return self._remoteCandiateSource
    }

    func sendOffer(_ offer: String) -> Completable {
        return Completable.error(RTCError.MethodNotOverriden)
    }

    func sendAnswer(_ answer: String) -> Completable {
        return Completable.error(RTCError.MethodNotOverriden)
    }

    func sendCandidate(_ candidate: [String: Any]) -> Completable {
        return Completable.error(RTCError.MethodNotOverriden)
    }

    internal func receivedRemoteOffer(offer: String) {
        self._remoteOfferSource.onNext(offer)
    }

    internal func receivedRemoteAnswer(answer: String) {
        self._remoteAnswerSource.onNext(answer)
    }

    internal func receivedRemoteCandidate(candidate: [String: Any]) {
        self._remoteCandiateSource.onNext(candidate)
    }

}
