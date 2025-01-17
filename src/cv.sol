// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

struct Recommend {
    bool submited;
    address owner;
    uint256 good;
    uint256 bad;
}

contract CV is ERC20 {
    mapping (bytes32 => Recommend) private vote;

    constructor() ERC20("Crypto Valley", "CV") {
        // init
    }

    function submitOption(string memory _data) external returns(bytes32) {
        bytes32 data = getOptionHash(_data);

        require(!vote[data].submited, "already submited");
        
        vote[data] = Recommend({
            submited: true,
            owner: msg.sender,
            good: 0,
            bad: 0
        });

        return data;
    }

    function addVote(bytes32 data_hash, bool _like) external {
        require(vote[data_hash].owner != msg.sender, "owner can't recommend this voting");

        Recommend storage _vote = vote[data_hash];

        if (_like) {
            _vote.good += 1;
        } else {
            _vote.bad += 1;
        }
    }

    function getOptionHash(string memory _data) internal view returns(bytes32) {
        return keccak256(abi.encodePacked(msg.sender, block.timestamp, _data));
    }
    
}