// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GovToken is ERC20, Ownable {
    address public minter;
    constructor() ERC20("GovToken", "GOV") Ownable(msg.sender) {}

    /// Owner / deployer address can set the address allowed to mint GovTokens to be the Staking contract
    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    /// Only allow the Staking contract can mint GovTokens
    function mint(address to, uint256 amount) external {
        require(msg.sender == minter, "Address not designated as minter");
        _mint(to, amount);
    }
}
