//
//  LikeUViewController.swift
//  Pico
//
//  Created by 방유빈 on 2023/09/25.
//

import UIKit
import RxSwift
import RxCocoa

final class LikeUViewController: UIViewController {
    private let emptyView: EmptyViewController = EmptyViewController(type: .iLikeU)
    private let collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let viewModel: LikeUViewModel = LikeUViewModel()
    private let disposeBag: DisposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    private let listLoadPublisher = PublishSubject<Void>()
    private let refreshPublisher = PublishSubject<Void>()
    private var isLoading = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
        if viewModel.likeUList.isEmpty {
            refreshPublisher.onNext(())
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        configCollectionView()
        configRefresh()
        bind()
        listLoadPublisher.onNext(())
    }
    
    private func configCollectionView() {
        collectionView.register(cell: LikeCollectionViewCell.self)
        collectionView.register(cell: CollectionViewFooterLoadingCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    private func configRefresh() {
        refreshControl.addTarget(self, action: #selector(refreshTable(refresh:)), for: .valueChanged)
        refreshControl.tintColor = .picoBlue
        collectionView.refreshControl = refreshControl
    }

    @objc func refreshTable(refresh: UIRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            refreshPublisher.onNext(())
            refresh.endRefreshing()
        }
    }
}

extension LikeUViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isLoading ? viewModel.likeUList.count + 1 : viewModel.likeUList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isLoading && indexPath.row == viewModel.likeUList.count {
            let cell = collectionView.dequeueReusableCell(forIndexPath: indexPath, cellType: CollectionViewFooterLoadingCell.self)
            cell.startLoading()
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(forIndexPath: indexPath, cellType: LikeCollectionViewCell.self)
            let item = viewModel.likeUList[indexPath.row]
            cell.configData(image: item.imageURL, nameText: "\(item.nickName), \(item.age)", isHiddenDeleteButton: true, isHiddenMessageButton: false, mbti: item.mbti)
            cell.messageButtonTapObservable
                .subscribe { [weak self] _ in
                    // 메일 뷰 데이터 연결 후 userId 값 넘겨주기
                    let mailSendView = MailSendViewController()
                    mailSendView.configData(userId: item.likedUserId)
                    mailSendView.modalPresentationStyle = .formSheet
                    self?.present(mailSendView, animated: true, completion: nil)
                }
                .disposed(by: cell.disposeBag)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 디테일뷰 데이터 연결 후 UserId 값 넘겨주기
        let viewController = UserDetailViewController()
         // 유저정보 넘겨주세요요
        // viewController.viewModel = UserDetailViewModel(user: user)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if isLoading && indexPath.row == viewModel.likeUList.count {
            return CGSize(width: view.frame.width, height: 50)
        } else {
            let width = view.frame.width / 2 - 17.5
            return CGSize(width: width, height: width * 1.5)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if isLoading && viewModel.likeUList.count % 2 == 1 {
            // 데이터 셀이 홀수개일 때 가운데 정렬하기
            let cellWidth = (collectionView.bounds.width - 15) / 2
            let extraSpacing = (collectionView.bounds.width - cellWidth) / 2
            return UIEdgeInsets(top: 0, left: extraSpacing, bottom: 0, right: extraSpacing)
        } else {
            // 데이터 셀이 짝수개일 때 정상적으로 정렬
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 15
    }
}

// MARK: - 페이징 처리
extension LikeUViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let contentOffsetY = scrollView.contentOffset.y
        let collectionViewContentSizeY = collectionView.contentSize.height
        
        if contentOffsetY > collectionViewContentSizeY - scrollView.frame.size.height {
            self.isLoading = true
            self.collectionView.reloadData()
            self.listLoadPublisher.onNext(())
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                self.isLoading = false
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
    }
}

// MARK: - bind
extension LikeUViewController {
    private func bind() {
        let input = LikeUViewModel.Input(listLoad: listLoadPublisher, refresh: refreshPublisher)
        let output = viewModel.transform(input: input)
        
        output.likeUIsEmpty
            .withUnretained(self)
            .subscribe(onNext: { viewController, isEmpty in
                if isEmpty {
                    viewController.addChild(viewController.emptyView)
                    viewController.view.addSubview(viewController.emptyView.view ?? UIView())
                    viewController.emptyView.didMove(toParent: self)
                    viewController.emptyView.view.snp.makeConstraints { make in
                        make.edges.equalToSuperview()
                    }
                } else {
                    viewController.view.addSubview(viewController.collectionView)
                    viewController.collectionView.snp.makeConstraints { make in
                        make.top.leading.equalToSuperview().offset(10)
                        make.trailing.bottom.equalToSuperview().offset(-10)
                    }
                }
            })
            .disposed(by: disposeBag)
        
        output.reloadCollectionView
            .withUnretained(self)
            .subscribe { viewController, _ in
                viewController.collectionView.reloadData()
            }
            .disposed(by: disposeBag)
    }
}
