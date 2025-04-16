// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GovToken.sol";


contract Staking {
    IERC20 public baseToken;
    GovToken public govToken;

    uint256 public rewardRate = 1e18; // rewarding 1 gov token 

    struct StakeInfo {
        uint256 amount;
        uint256 lastClaimed;
        uint256 unclaimed;
    } // Creating a custom structure / struct called StakeInfo, which stores info about staking.

    mapping(address => StakeInfo) public stakes; // Then the mapping assigns an address to that info for lookup / data retreival

    constructor(address _baseToken, address _govToken) {
        baseToken = IERC20(_baseToken); // the address of the token used for staking, with IERC20 interface
        govToken = GovToken(_govToken); // the address of the GovToken contract, with GovToken interface
    } // state variable declarations for these tokens

    // Stake base tokens to earn GovTokens
    function stake(uint256 amount) external {
        require(amount > 0, "stake amount cannot be zero");

        _updateRewards(msg.sender); // update the rewards for the user before staking, to reset the count

        baseToken.transferFrom(msg.sender, address(this), amount); // requires the user to approve the contract to spend their tokens
        StakeInfo storage stakeInfo = stakes[msg.sender]; // modify contracts state for the user
        stakeInfo.amount += amount; // updates the mapping for message sender with amount staked
    }

    //Unstake all base tokens and claim GovToken rewards, all or nothing unstaske feature for simplicity - minimal design
    function unstake() external {
        StakeInfo storage stakeInfo = stakes[msg.sender]; 
        require(stakeInfo.amount > 0, "stake amount cannot be zero"); 

        _updateRewards(msg.sender); // update the rewards for the user before unstaking

        uint256 toUnstake = stakeInfo.amount; // get the amount to unstake, the full staked amount
        stakeInfo.amount = 0; // sets stake amount to zero as unstaked full amount

        baseToken.transfer(msg.sender, toUnstake); // transfer the unstaked amount back to the user
        _claimGovTokens(msg.sender); // mint the earned GovTokens
    }

    // Claim accrued GovTokens
    function claimGovToken() external {
        _updateRewards(msg.sender);
        _claimGovTokens(msg.sender);
    }

    // internal reward accrual calculation
    function _updateRewards(address user) internal {
        StakeInfo storage stakeInfo = stakes[user]; // modify contracts state for the user
        if (stakeInfo.amount > 0) { // avoids uneccesary gas use, only updates calculates rewareds if the user has staked
            uint256 timeElapsed = block.timestamp - stakeInfo.lastClaimed; // calculates the time elapsed since the last claim
            uint256 earned = (stakeInfo.amount * rewardRate * timeElapsed) / 1 days / 1e18; // calculates the earned amount based on the time elapsed and the reward rate
            stakeInfo.unclaimed += earned;
        }
        stakeInfo.lastClaimed = block.timestamp; // resets the last claimed time to the current block timestamp
    }

    /// Internal: Mint earned GovTokens
    function _claimGovTokens(address user) internal {
        uint256 amount = stakes[user].unclaimed;
        if (amount > 0) {
            stakes[user].unclaimed = 0;
            govToken.mint(user, amount);
        }
    }
}