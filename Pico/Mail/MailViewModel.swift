//
//  MailViewModel.swift
//  Pico
//
//  Created by 양성혜 on 2023/10/05.
//

import UIKit
import RxSwift
import RxRelay
import FirebaseFirestore

final class MailViewModel {
    var mailSendList: [Mail.MailInfo] = []
    var mailSendListRx = BehaviorRelay<[Mail.MailInfo]>(value: [])
    var isMailSendEmpty: Observable<Bool> {
        return mailSendListRx
            .map { $0.isEmpty }
    }
    
    var mailRecieveList: [Mail.MailInfo] = []
    var mailRecieveListRx = BehaviorRelay<[Mail.MailInfo]>(value: [])
    var isMailReceiveEmpty: Observable<Bool> {
        return mailRecieveListRx
            .map { $0.isEmpty }
    }
    private let dbRef = Firestore.firestore()
    
    private let pageSize = 6
    var startIndex = 0
    
    var user: User?
    
    init() {
        loadNextMailPage()
    }
    
    func loadNextMailPage() {
        let ref = dbRef.collection(Collections.mail.name).document(UserDefaultsManager.shared.getUserData().userId)
        let endIndex = startIndex + pageSize
        
        ref.getDocument { [weak self] document, error in
            guard let self = self else { return }
            if let error = error {
                print(error)
                return
            }
            
            if let document = document, document.exists {
                if let datas = try? document.data(as: Mail.self).sendMailInfo?.filter({ $0.mailType == .send }) {
                    
                    if startIndex > datas.count - 1 { return }
                    
                    let currentPageDatas: [Mail.MailInfo] = Array(datas[startIndex..<min(endIndex, datas.count)])
                    mailSendList.append(contentsOf: currentPageDatas)
                    startIndex += currentPageDatas.count
                    mailSendListRx.accept(mailSendList)
                } else if let datas = try? document.data(as: Mail.self).receiveMailInfo?.filter({ $0.mailType == .receive }) {
                    
                    if startIndex > datas.count - 1 { return }
                    
                    let currentPageDatas: [Mail.MailInfo] = Array(datas[startIndex..<min(endIndex, datas.count)])
                    mailRecieveList.append(contentsOf: currentPageDatas)
                    startIndex += currentPageDatas.count
                    mailRecieveListRx.accept(mailRecieveList)
                } else {
                    print("문서를 찾을 수 없습니다.")
                }
            }
        }
    }
    
    func refresh() {
        mailSendList = []
        mailRecieveList = []
        loadNextMailPage()
    }
    
    func saveMailData(receiveUserId: String, message: String) {
        let senderUserId: String = UserDefaultsManager.shared.getUserData().userId
        
        let sendMessages: [String: Any] = [
            "id": UUID().uuidString,
            "sendedUserId": senderUserId,
            "receivedUserId": receiveUserId,
            "message": message,
            "sendedDate": Date().timeIntervalSince1970.toString(),
            "mailType": "send",
            "isReading": true
        ]
        
        let receiveMessages: [String: Any] = [
            "id": UUID().uuidString,
            "sendedUserId": senderUserId,
            "receivedUserId": receiveUserId,
            "message": message,
            "sendedDate": Date().timeIntervalSince1970.toString(),
            "mailType": "receive",
            "isReading": false
        ]
        
        // 보내는 사람
        dbRef.collection(Collections.mail.name).document(senderUserId).setData(
            [
                "userId": senderUserId,
                "sendMailInfo": FieldValue.arrayUnion([sendMessages])
            ], merge: true) { error in
                if let error = error {
                    print("평가 업데이트 에러: \(error)")
                } else {
                    print("평가 업데이트 성공")
                }
            }
        
        // 받는 사람
        dbRef.collection(Collections.mail.name).document(receiveUserId).setData(
            [
                "userId": receiveUserId,
                "receiveMailInfo": FieldValue.arrayUnion([receiveMessages])
            ], merge: true) { error in
                if let error = error {
                    print("평가 업데이트 에러: \(error)")
                } else {
                    print("평가 업데이트 성공")
                }
            }
    }
    
    func getUser(userId: String, completion: @escaping () -> ()) {
        DispatchQueue.global().async {
            self.dbRef.collection(Collections.users.name).document(userId)
                .getDocument(as: User.self) { result in
                    switch result {
                    case .success(let user):
                        self.user = user
                        completion()
                    case .failure(let error):
                        print("Error decoding room: \(error)")
                    }
                }
        }
    }
    
    func toType (text: String) -> MailType {
        switch text {
        case "받은 쪽지":
            return .receive
        case "보낸 쪽지":
            return .send
        default:
            return .receive
        }
    }
}
