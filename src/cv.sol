// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

struct Recommend {
    bool submitted;
    address owner;
    uint256 good; // 좋아요 수
    uint256 bad; // 싫어요 수
}

struct Subscribe {
    bool subscribe;
    uint256 lastSubscribe;
}

contract CV is ERC20 {
    uint256 constant ONE_MONTH = 30 days;

    uint256 public lastupdated;
    address public owner;
    uint256 public submitCount;
    uint256 public voteCount;

    mapping(string => mapping(uint256 => mapping(uint256 => Recommend))) private votes; // 추천 의견
    mapping(address => mapping(string => Subscribe)) public Subscribers; // 무료 구독자
    uint256 public totalSubscriptionAmount; // 총 구독료
    mapping(address => uint256) private rewards; // 각 추천에 대한 보상
    mapping(string => bool) public tokenWhitelist;

    event OptionSubmitted(bytes32 indexed optionHash, address indexed owner);
    event Voted(uint256 indexed voteCount, address indexed voter, bool like);
    event Subscribed(string tokenType, address indexed subscriber);

    constructor(address _owner) ERC20("Crypto Valley", "CV") {
        owner = _owner;
        _mint(owner, 3000 * (10 ** decimals()));
        lastupdated = block.timestamp;
        totalSubscriptionAmount = 3 * (10 ** decimals());
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    function addtoken(string memory tokenType, bool _add) external onlyOwner {
        tokenWhitelist[tokenType] = _add;
    }

    function initDuration() external onlyOwner {
        require(lastupdated + ONE_MONTH < block.timestamp);
        totalSubscriptionAmount = 0;
    }

    // 의견 제출
    function submitOption(string memory tokenType, string memory _data) external {
        bytes32 dataHash = getOptionHash(_data);

        votes[tokenType][submitCount][voteCount] = Recommend({submitted: true, owner: msg.sender, good: 0, bad: 0});
        submitCount += 1;

        emit OptionSubmitted(dataHash, msg.sender);
    }

    // 투표 기능
    function addVote(string memory tokenType, bool _like) external {
        Recommend storage _vote = votes[tokenType][submitCount][voteCount];
        voteCount += 1;

        if (_like) {
            _vote.good += 1;
        } else {
            _vote.bad += 1;
        }

        emit Voted(voteCount, msg.sender, _like);
    }

    // 보상 계산
    function calculateReward(string memory tokenType) private {
        Recommend storage _vote = votes[tokenType][submitCount][voteCount];
        uint256 totalVotes = _vote.good + _vote.bad;

        if (totalVotes >= 100 && (_vote.good * 100 / totalVotes) >= 80) {
            uint256 rewardAmount = (totalSubscriptionAmount * 80) / 100;
            rewards[_vote.owner] = rewardAmount; // 보상 저장
        }
    }

    // 구독 기능
    function subscribe(string memory tokenType) external {
        if (
            keccak256(abi.encodePacked(tokenType)) != keccak256("BTC")
                || keccak256(abi.encodePacked(tokenType)) != keccak256("ETH")
        ) {
            require(balanceOf(msg.sender) >= 2 * (10 ** decimals()), "Not enough CV tokens"); // 2 CV 필요

            // CV 토큰 소모
            transferFrom(msg.sender, address(this), 2 * (10 ** decimals()));

            Subscribers[msg.sender][tokenType] = Subscribe({subscribe: true, lastSubscribe: block.timestamp});

            totalSubscriptionAmount += 2 * (10 ** decimals()); // 총 구독료 증가
        }

        emit Subscribed(tokenType, msg.sender);
    }

    // 보상 분배 기능
    function distributeRewards(string memory tokenType) external {
        Recommend storage _vote = votes[tokenType][submitCount][voteCount];

        address _owner = _vote.owner;
        require(_owner == msg.sender, "you are not owner");

        uint256 reward = rewards[_owner];
        require(reward > 0, "No rewards available");

        // 보상 지급
        transfer(_owner, reward);

        rewards[_owner] = 0; // 보상 초기화
    }

    // 해시 생성
    function getOptionHash(string memory _data) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, block.timestamp, _data));
    }
}
