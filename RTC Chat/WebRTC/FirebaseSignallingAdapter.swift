//
//  FirebaseSignallingAdapter.swift
//  RTC Chat
//
//  Created by Pepe Becker on 23/02/2018.
//  Copyright © 2018 Pepe Becker. All rights reserved.
//

import UIKit
import RxSwift
import FirebaseFirestore

public class FirebaseSignallingAdapter: SignallingAdapter {
    
    private let _uid: String
    private let _roomRef: DocumentReference
    
    init(roomID: String) {
        self._roomRef = Firestore.firestore().collection(Paths.rooms).document(roomID)
        self._uid = UIDevice.current.identifierForVendor!.uuidString
        super.init()
        self.addOfferPacketListener()
        self.addAnswerPacketListener()
        self.addCandiatePacketListener()
    }

    private func sendData(_ data: String, forCollection collection: String) -> Completable {
        return Completable.create(subscribe: { completable in
            let documentData: [String: Any] = ["uid": self._uid, "date": FieldValue.serverTimestamp(), "data": data]
            self._roomRef.collection(collection).addDocument(data: documentData, completion: { error in
                if let error = error {
                    completable(.error(error))
                } else {
                    completable(.completed)
                }
            })
            return Disposables.create()
        })
    }

    override func sendOffer(_ offer: String) -> Completable {
        return sendData(offer, forCollection: Paths.offers)
    }

    override func sendAnswer(_ answer: String) -> Completable {
        return sendData(answer, forCollection: Paths.answers)
    }

    override func sendCandidate(_ candidate: [String : Any]) -> Completable {
        return Completable.create(subscribe: { completable in
            let documentData: [String: Any] = [
                "uid": self._uid,
                "date": FieldValue.serverTimestamp(),
                "sdp": candidate["sdp"] as Any,
                "sdpMid": candidate["sdpMid"] as Any,
                "sdpMLineIndex": candidate["sdpMLineIndex"] as Any
            ]
            self._roomRef.collection(Paths.candidates).addDocument(data: documentData, completion: { error in
                if let error = error {
                    completable(.error(error))
                } else {
                    completable(.completed)
                }
            })
            return Disposables.create()
        })
    }

    private func addOfferPacketListener() {
        let offersRef = self._roomRef.collection(Paths.offers)
        offersRef.order(by: "date", descending: true).limit(to: 1).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot else {
                print("Error: snapshot is nil")
                return
            }
            
            for document in snapshot.documents {
                let data = document.data()
                if let uid = data["uid"] as? String {
                    if uid != self._uid {
                        if let offer = data["data"] as? String {
                            self.receivedRemoteOffer(offer: offer)
                        }
                        offersRef.document(document.documentID).delete()
                    }
                }
            }
        }
    }
    
    private func addAnswerPacketListener() {
        let answersRef = self._roomRef.collection(Paths.answers)
        answersRef.order(by: "date", descending: true).limit(to: 1).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot else {
                print("Error: snapshot is nil")
                return
            }
            
            for document in snapshot.documents {
                let data = document.data()
                if let uid = data["uid"] as? String {
                    if uid != self._uid {
                        if let answer = data["data"] as? String {
                            self.receivedRemoteAnswer(answer: answer)
                        }
                        answersRef.document(document.documentID).delete()
                    }
                }
            }
        }
    }
    
    private func addCandiatePacketListener() {
        let candidatesRef = self._roomRef.collection(Paths.candidates)
        candidatesRef.order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot else {
                print("Error: snapshot is nil")
                return
            }
            
            for document in snapshot.documents {
                let data = document.data()
                if let uid = data["uid"] as? String {
                    if uid != self._uid {
                        self.receivedRemoteCandidate(candidate: data)
                        candidatesRef.document(document.documentID).delete()
                    }
                }
            }
        }
    }

}
