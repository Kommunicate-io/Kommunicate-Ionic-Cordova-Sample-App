//
//  ALKMyGenericList.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 05/12/18.
//

class ALKMyGenericListCell: ALKChatBaseCell<ALKMessageViewModel> {
    var itemTitleLabel: InsetLabel = {
        let label = InsetLabel(insets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
        label.text = "title"
        label.numberOfLines = 1
        label.font = Font.bold(size: 16.0).font()
        label.textColor = UIColor.black
        return label
    }()

    var height: CGFloat!
    private var widthPadding: CGFloat = CGFloat(ALKMessageStyle.sentBubble.widthPadding)

    fileprivate lazy var messageView: ALKHyperLabel = {
        let label = ALKHyperLabel(frame: .zero)
        label.isUserInteractionEnabled = true
        label.numberOfLines = 0
        return label
    }()

    fileprivate var timeLabel: UILabel = {
        let lb = UILabel()
        lb.isOpaque = true
        return lb
    }()

    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    fileprivate var bubbleView: UIImageView = {
        let bv = UIImageView()
        bv.clipsToBounds = true
        bv.isUserInteractionEnabled = false
        bv.isOpaque = true
        return bv
    }()

    var mainBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 5
        view.layer.borderColor = UIColor.gray.cgColor
        view.layer.borderWidth = 1
        return view
    }()

    let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }()

    let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
        return stackView
    }()

    public enum Padding {
        enum MainStackView {
            static var bottom: CGFloat = -20.0
            static var left: CGFloat = 95
            static var right: CGFloat = -10
        }
    }

    open var actionButtons = [UIButton]()

    open var template: ALKGenericListTemplate!
    open var buttonSelected: ((_ index: Int, _ name: String) -> Void)?

    private var items = [ALKGenericListTemplate]()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func setupViews() {
        super.setupViews()
        setUpButtons()
        setUpViews()
    }

    open class func rowHeightFor(template: [ALKGenericListTemplate], viewModel: ALKMessageViewModel) -> CGFloat {
        let buttonHeight = 35
        let baseHeight: CGFloat = 10
        let padding: CGFloat = 10
        let totalButtonHeight: CGFloat = CGFloat(buttonHeight * template.count)
        return baseHeight + totalButtonHeight + padding + ALKFriendMessageView.rowHeigh(viewModel: viewModel, widthNoPadding: UIScreen.main.bounds.width - 200) + 40
    }

    @objc func buttonSelected(_ action: UIButton) {
        buttonSelected?(action.tag, action.currentTitle ?? "")
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)
        updateMessageView(viewModel)
        guard let metadata = viewModel.metadata, let payload = metadata["payload"] as? String else {
            return
        }
        do {
            let cardTemplate = try JSONDecoder().decode([ALKGenericListTemplate].self, from: payload.data)
            guard let title = metadata["headerText"] as? String else {
                return
            }
            updateTitle(title)
            updateViewFor(cardTemplate)
        } catch {
            print("\(error)")
        }
    }

    private func setUpButtons() {
        actionButtons = (0 ... 7).map {
            let button = UIButton()
            button.setTitleColor(UIColor(netHex: 0x5C5AA7), for: .normal)
            button.setFont(font: UIFont.font(.bold(size: 16.0)))
            button.setTitle("Button", for: .normal)
            button.addTarget(self, action: #selector(buttonSelected(_:)), for: .touchUpInside)
            button.layer.borderWidth = 1.0
            button.tag = $0
            button.layer.borderColor = UIColor.lightGray.cgColor
            return button
        }
    }

    private func setUpViews() {
        setupConstraints()
        backgroundColor = .clear
    }

    override func setupStyle() {
        super.setupStyle()
        if ALKMessageStyle.sentBubble.style == .edge {
            let image = UIImage(named: "chat_bubble_rounded", in: Bundle.applozic, compatibleWith: nil)
            bubbleView.tintColor = UIColor(netHex: 0xF1F0F0)
            bubbleView.image = image?.imageFlippedForRightToLeftLayoutDirection()
        } else {
            bubbleView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
            bubbleView.tintColor = ALKMessageStyle.sentBubble.color
            bubbleView.backgroundColor = ALKMessageStyle.sentBubble.color
        }
    }

    private func setupConstraints() {
        let view = contentView

        actionButtons.forEach {
            buttonStackView.addArrangedSubview($0)
            $0.heightAnchor.constraint(equalToConstant: 35).isActive = true
        }
        mainStackView.addArrangedSubview(itemTitleLabel)
        mainStackView.addArrangedSubview(buttonStackView)
        view.addViewsForAutolayout(views: [mainBackgroundView, mainStackView, self.messageView, self.bubbleView, timeLabel, stateView])
        view.bringSubviewToFront(messageView)

        messageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2).isActive = true
        messageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 95).isActive = true
        messageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25).isActive = true
        messageView.heightAnchor.constraint(lessThanOrEqualToConstant: 1000).isActive = true
        messageView.layoutIfNeeded()

        bubbleView.leadingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: -widthPadding).isActive = true
        bubbleView.trailingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: widthPadding).isActive = true
        bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0).isActive = true
        bubbleView.bottomAnchor.constraint(equalTo: messageView.bottomAnchor, constant: 2).isActive = true

        stateView.widthAnchor.constraint(equalToConstant: 17.0).isActive = true
        stateView.heightAnchor.constraint(equalToConstant: 9.0).isActive = true
        stateView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -1.0).isActive = true
        stateView.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -2.0).isActive = true

        timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -2.0).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2).isActive = true

        mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Padding.MainStackView.left).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: Padding.MainStackView.right).isActive = true
        mainStackView.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 5).isActive = true
        mainStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: Padding.MainStackView.bottom).isActive = true

        itemTitleLabel.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor, constant: 0).isActive = true
        itemTitleLabel.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor, constant: 0).isActive = true
        itemTitleLabel.topAnchor.constraint(equalTo: mainStackView.topAnchor, constant: 0).isActive = true
        itemTitleLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        itemTitleLabel.backgroundColor = UIColor.lightGray

        mainBackgroundView.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor).isActive = true
        mainBackgroundView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor).isActive = true
        mainBackgroundView.topAnchor.constraint(equalTo: mainStackView.topAnchor).isActive = true
        mainBackgroundView.bottomAnchor.constraint(equalTo: mainStackView.bottomAnchor).isActive = true

        buttonStackView.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor, constant: 0).isActive = true
    }

    private func updateMessageView(_ viewModel: ALKMessageViewModel) {
        messageView.text = viewModel.message ?? ""
        messageView.setStyle(ALKMessageStyle.sentMessage)
        timeLabel.text = viewModel.time
        timeLabel.setStyle(ALKMessageStyle.time)

        if viewModel.isAllRead {
            stateView.image = UIImage(named: "read_state_3", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = UIColor(netHex: 0x0578FF)
        } else if viewModel.isAllReceived {
            stateView.image = UIImage(named: "read_state_2", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = nil
        } else if viewModel.isSent {
            stateView.image = UIImage(named: "read_state_1", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = nil
        } else {
            stateView.image = UIImage(named: "seen_state_0", in: Bundle.applozic, compatibleWith: nil)
            stateView.tintColor = UIColor.red
        }
    }

    private func updateViewFor(_ buttons: [ALKGenericListTemplate]) {
        // Hide3 extra buttons
        actionButtons.enumerated().forEach {
            if $0 >= buttons.count { $1.isHidden = true } else { $1.isHidden = false; $1.setTitle(buttons[$0].title, for: .normal) }
        }
    }

    private func updateTitle(_ title: String?) {
        guard let text = title else {
            itemTitleLabel.isHidden = true
            return
        }
        itemTitleLabel.text = text
    }
}
