//
//  MailViewController.swift
//  Pico
//
//  Created by 최하늘 on 2023/09/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxRelay

final class MailViewController: BaseViewController {
    
    private let viewModel = MailViewModel()
    private var disposeBag = DisposeBag()
    
    private let emptyView = EmptyViewController(type: .message)
    private let refreshControl = UIRefreshControl()
    
    private var mailTypeButtons: [UIButton] = []
    private var mailType: MailType = .receive
    private var isEmpty: Bool = true
    
    private let mailText: UILabel = {
        let label = UILabel()
        label.text = "Mail"
        label.font = UIFont.picoTitleFont
        label.textColor = .picoFontBlack
        return label
    }()
    
    private let buttonStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        return stackView
    }()
    
    private let receiveButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .picoAlphaBlue
        button.setTitle("받은 쪽지", for: .normal)
        button.titleLabel?.font = .picoDescriptionFont
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.setTitleColor(.white, for: .normal)
        button.isSelected = true
        return button
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .picoGray
        button.setTitle("보낸 쪽지", for: .normal)
        button.titleLabel?.font = .picoDescriptionFont
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.setTitleColor(.picoBetaBlue, for: .normal)
        return button
    }()
    
    private let mailListTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(cell: MailListTableViewCell.self)
        return tableView
    }()
    
    // MARK: - MailView +LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewRefresh()
        configRefresh()
        configTableviewDelegate()
        configTableView()
        configMailTypeButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mailListTableView.reloadData()
    }
    
    // MARK: - MailView +UI
    private func viewRefresh() {
        addViews()
        makeConstraints()
        configMailTableviewDatasource()
    }
    
    private func addViews() {
        view.addSubview(mailText)
        
        [receiveButton, sendButton].forEach { item in
            mailTypeButtons.append(item)
        }
        
        buttonStack.addArrangedSubview([receiveButton, sendButton])
        
        view.addSubview(buttonStack)
        
        if mailType == .receive {
            viewModel.isMailReceiveEmpty
                .subscribe(onNext: { [weak self] isEmpty in
                    if isEmpty {
                        self?.view.addSubview(self?.emptyView.view ?? UIView())
                        self?.emptyView.didMove(toParent: self)
                    } else {
                        self?.view.addSubview(self?.mailListTableView ?? UITableView())
                    }
                })
                .disposed(by: disposeBag)
        } else {
            viewModel.isMailSendEmpty
                .subscribe(onNext: { [weak self] isEmpty in
                    if isEmpty {
                        self?.view.addSubview(self?.emptyView.view ?? UIView())
                        self?.emptyView.didMove(toParent: self)
                    } else {
                        self?.view.addSubview(self?.mailListTableView ?? UITableView())
                    }
                })
                .disposed(by: disposeBag)
        }
    }
    
    private func makeConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        
        mailText.snp.makeConstraints { make in
            make.top.equalTo(safeArea).offset(10)
            make.leading.equalTo(safeArea).offset(20)
            make.trailing.equalTo(safeArea).offset(-30)
        }
        
        buttonStack.snp.makeConstraints { make in
            make.top.equalTo(mailText.snp.bottom).offset(10)
            make.leading.equalTo(safeArea.snp.leading).offset(20)
        }
        
        sendButton.snp.makeConstraints { make in
            make.width.equalTo(60)
        }
        
        receiveButton.snp.makeConstraints { make in
            make.width.equalTo(60)
        }
        
        if mailType == .receive {
            viewModel.isMailReceiveEmpty
                .subscribe(onNext: { [weak self] isEmpty in
                    if isEmpty {
                        self?.emptyView.view.snp.makeConstraints { make in
                            make.top.equalTo(self?.buttonStack.snp.bottom ?? UIStackView())
                            make.leading.trailing.bottom.equalTo(safeArea)
                        }
                    } else {
                        self?.mailListTableView.snp.makeConstraints { make in
                            make.top.equalTo(self?.buttonStack.snp.bottom ?? UIStackView()).offset(10)
                            make.leading.equalTo(safeArea).offset(10)
                            make.trailing.bottom.equalTo(safeArea).offset(-10)
                        }
                    }
                })
                .disposed(by: disposeBag)
        } else {
            viewModel.isMailSendEmpty
                .subscribe(onNext: { [weak self] isEmpty in
                    if isEmpty {
                        self?.emptyView.view.snp.makeConstraints { make in
                            make.top.equalTo(self?.buttonStack.snp.bottom ?? UIStackView())
                            make.leading.trailing.bottom.equalTo(safeArea)
                        }
                    } else {
                        self?.mailListTableView.snp.makeConstraints { make in
                            make.top.equalTo(self?.buttonStack.snp.bottom ?? UIStackView()).offset(10)
                            make.leading.equalTo(safeArea).offset(10)
                            make.trailing.bottom.equalTo(safeArea).offset(-10)
                        }
                    }
                })
                .disposed(by: disposeBag)
        }
    }
    
    // MARK: - config
    private func configMailTypeButtons() {
        sendButton.addTarget(self, action: #selector(tappedMailTypeButton), for: .touchUpInside)
        receiveButton.addTarget(self, action: #selector(tappedMailTypeButton), for: .touchUpInside)
    }
    
    private func configTableView() {
        mailListTableView.rowHeight = 80
        
        refreshControl.endRefreshing()
        mailListTableView.refreshControl = refreshControl
    }
    
    private func configRefresh() {
        refreshControl.addTarget(self, action: #selector(refreshTable(refresh:)), for: .valueChanged)
        refreshControl.tintColor = .picoBlue
        mailListTableView.refreshControl = refreshControl
    }
   
    // MARK: - objc
    @objc func refreshTable(refresh: UIRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.viewModel.refresh()
            refresh.endRefreshing()
        }
    }
    
    @objc func tappedMailTypeButton(_ sender: UIButton) {
        for button in mailTypeButtons {
            button.isSelected = (button == sender)
            guard let text = sender.titleLabel?.text else { return }
            switch button.isSelected {
            case true:
                sender.backgroundColor = .picoAlphaBlue
                sender.setTitleColor(.white, for: .normal)
                mailType = viewModel.toType(text: text)
            case false:
                button.backgroundColor = .picoGray
                button.setTitleColor(.picoBetaBlue, for: .normal)
            }
        }
        viewRefresh()
        mailListTableView.reloadData()
    }
}
// MARK: - UIMailTableView +Rx
extension MailViewController {
    private func configMailTableviewDatasource() {
        Loading.showLoading()
        
        mailListTableView.delegate = nil
        mailListTableView.dataSource = nil
        
        if mailType == .receive {
            
            if viewModel.mailRecieveList.isEmpty {
                Loading.hideLoading()
            }

            viewModel.mailRecieveListRx.bind(to: mailListTableView.rx
                .items(cellIdentifier: MailListTableViewCell.reuseIdentifier,
                       cellType: MailListTableViewCell.self)) { _, item, cell in
                cell.getData(senderUser: item, type: .receive)
                cell.selectionStyle = .none
                Loading.hideLoading()
            }
                       .disposed(by: disposeBag)
        } else {
           
            if viewModel.mailSendList.isEmpty {
                Loading.hideLoading()
            }
            
            viewModel.mailSendListRx.bind(to: mailListTableView.rx
                .items(cellIdentifier: MailListTableViewCell.reuseIdentifier,
                       cellType: MailListTableViewCell.self)) { _, item, cell in
                cell.getData(senderUser: item, type: .send)
                cell.selectionStyle = .none
                Loading.hideLoading()
            }
                       .disposed(by: disposeBag)
        }
    }
    
    private func configTableviewDelegate() {
        mailListTableView.rx.modelSelected(Mail.MailInfo.self)
            .subscribe(onNext: { item in
                let mailReceiveView = MailReceiveViewController()
                mailReceiveView.modalPresentationStyle = .formSheet
                mailReceiveView.getReceiver(mailSender: item)
                self.present(mailReceiveView, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
}
// MARK: - Paging
extension MailViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let contentOffsetY = scrollView.contentOffset.y
        let mailListViewContentSizeY = mailListTableView.contentSize.height
        
        if contentOffsetY > mailListViewContentSizeY - scrollView.frame.size.height {
            viewModel.loadNextMailPage()
        }
    }
}
