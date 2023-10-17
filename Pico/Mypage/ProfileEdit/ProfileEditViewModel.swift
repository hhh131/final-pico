//
//  ProfileEditViewModel.swift
//  Pico
//
//  Created by 김민기 on 2023/10/11.
//

import RxSwift
import RxCocoa

final class ProfileEditViewModel {
    
    enum SubInfoCase {
        case imageURLs
        case nickName
        case location
        case intro
        case height
        case job
        case religion
        case drink
        case smoke
        case education
        case personalities
        case hobbies
        case favoriteMBTIs
        
        var name: String {
            switch self {
            case .nickName:
                return "이름변경"
            case .intro:
                return "한 줄 소개"
            case .height:
                return "키"
            case .education:
                return "학력"
            case .religion:
                return "종교"
            case .drink:
                return "음주"
            case .smoke:
                return "흡연"
            case .job:
                return "직업"
            case .personalities:
                return "나의 성격"
            case .hobbies:
                return "나의 취미"
            case .favoriteMBTIs:
                return "선호하는 MBTI"
            default:
                return ""
            }
        }
        
        var dataName: String {
            switch self {
                
            case .imageURLs:
                return "imageURLs"
            case .nickName:
                return "nickName"
            case .location:
                return "location"
            case .intro:
                return "subInfo.intro"
            case .height:
                return "subInfo.height"
            case .job:
                return "subInfo.job"
            case .religion:
                return "subInfo.religion"
            case .drink:
                return "subInfo.drinkStatus"
            case .smoke:
                return "subInfo.smokeStatus"
            case .education:
                return "subInfo.education"
            case .personalities:
                return "subInfo.personalities"
            case .hobbies:
                return "subInfo.hobbies"
            case .favoriteMBTIs:
                return "subInfo.favoriteMBTIs"
            }
        }
    }
    
    let frequencyType = FrequencyType.allCases.map { $0.name }
    let frequencyTypes: [FrequencyType] = FrequencyType.allCases
    let religionType = ReligionType.allCases.map { $0.name }
    let educationType = EducationType.allCases.map { $0.name }
    
    let modalName = BehaviorRelay<String>(value: "")
    var modalCollectionData = [String]()
    var modalType: SubInfoCase?
    
    var selectedIndex: Int?/*컬렉션뷰만잇는뷰에서 사용*/
    var textData: String? /*텍스트만잇는뷰 사용*/
    var collectionData: [String]? /*콜렉션텍스트뷰 사용*/
    
    var userData: User?
    
    private let userId = UserDefaultsManager.shared.getUserData().userId
    let sectionsRelay = BehaviorRelay<[SectionModel]>(value: [
        SectionModel(items: [.profileEditImageTableCell(images: [])]),
        SectionModel(items: [.profileEditNicknameTabelCell, .profileEditLoactionTabelCell(location: "")]),
        SectionModel(items: [
            .profileEditTextTabelCell(title: SubInfoCase.intro.name, content: nil),
            .profileEditTextTabelCell(title: SubInfoCase.height.name, content: nil),
            .profileEditTextTabelCell(title: SubInfoCase.job.name, content: nil),
            .profileEditTextTabelCell(title: SubInfoCase.religion.name, content: nil),
            .profileEditTextTabelCell(title: SubInfoCase.drink.name, content: nil),
            .profileEditTextTabelCell(title: SubInfoCase.smoke.name, content: nil),
            .profileEditTextTabelCell(title: SubInfoCase.education.name, content: nil),
            .profileEditTextTabelCell(title: SubInfoCase.personalities.name, content: nil),
            .profileEditTextTabelCell(title: SubInfoCase.hobbies.name, content: nil),
            .profileEditTextTabelCell(title: SubInfoCase.favoriteMBTIs.name, content: nil)
        ])
    ])
    
    init() {
        loadUserData()
    }
    
    func findIndex(for targetString: String, in array: [String]) -> Int? {
        if let index = array.firstIndex(of: targetString) {
            return index
        }
        return nil
    }
    
    func updateData<T: Codable>(data: T) {
        guard let field = modalType?.dataName else { return }
        
        if modalType == .location {
            SignLoadingManager.showLoading(text: "위치정보를 받는중이에요!!")
            FirestoreService.shared.updataDocuments(collectionId: .users, documentId: userId, field: field, data: data) { _ in
                SignLoadingManager.hideLoading()
            }
        } else {
            FirestoreService.shared.updateDocument(collectionId: .users, documentId: userId, field: field, data: data)
        }
        loadUserData()
    }
    
    func loadUserData() {
        FirestoreService.shared.loadDocument(collectionId: .users, documentId: userId, dataType: User.self) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let data):
                if let user = data {
                    UserDefaultsManager.shared.setUserData(userData: user)
                }
                guard let data else { return }
                userData = data
                let result =
                [
                    SectionModel(items: [.profileEditImageTableCell(images: data.imageURLs)]),
                    SectionModel(items: [.profileEditNicknameTabelCell, .profileEditLoactionTabelCell(location: data.location.address)]),
                    SectionModel(items: [
                        .profileEditTextTabelCell(title: SubInfoCase.intro.name, content: data.subInfo?.intro),
                        .profileEditTextTabelCell(title: SubInfoCase.height.name, content: "\(data.subInfo?.height ?? 0)"),
                        .profileEditTextTabelCell(title: SubInfoCase.job.name, content: data.subInfo?.job),
                        .profileEditTextTabelCell(title: SubInfoCase.religion.name, content: data.subInfo?.religion?.rawValue),
                        .profileEditTextTabelCell(title: SubInfoCase.drink.name, content: data.subInfo?.drinkStatus?.rawValue),
                        .profileEditTextTabelCell(title: SubInfoCase.smoke.name, content: data.subInfo?.smokeStatus?.rawValue),
                        .profileEditTextTabelCell(title: SubInfoCase.education.name, content: data.subInfo?.education?.rawValue),
                        .profileEditTextTabelCell(title: SubInfoCase.personalities.name, content: data.subInfo?.personalities?[0]),
                        .profileEditTextTabelCell(title: SubInfoCase.hobbies.name, content: data.subInfo?.hobbies?[0]),
                        .profileEditTextTabelCell(title: SubInfoCase.favoriteMBTIs.name, content: data.subInfo?.favoriteMBTIs?[0].rawValue)
                    ])
                ]
                sectionsRelay.accept(result)
            case .failure(let err):
                debugPrint(err)
            }
        }
    }
}
