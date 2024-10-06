// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract staking is IERC721Receiver, ERC721Holder {
   
   IERC721 immutable nft;
   IERC20 immutable token;

   mapping(address => mapping(uint256 => uint256)) public stakes;

   constructor(address _nft, address _token) {
    nft = IERC721(_nft);
    token = IERC20(_token);
   }

   function calculateRate(uint256 time) private pure returns(uint8) {
    if(time < 1 minutes) {
        return 0;
    } else if(time < 3 minutes) {
        return 3;
    } else if (time < 5 minutes) {
        return 5;
    } else {
        return 10;
    }
   }

  function stake(uint256 _tokenId) public {
    //ensure the owner of the nft
    require(nft.ownerOf(_tokenId) == msg.sender, "YOU ARE NOT THE OWNER OF THE NFT");
    //stake the NFT
    stakes[msg.sender][_tokenId] = block.timestamp;
    nft.safeTransferFrom(msg.sender, address(this), _tokenId, ""); //transfer of the nft from the msg.sender to the contract address

  }

  function calculateReward(uint256 _tokenId) public view returns(uint256) {
    require(stakes[msg.sender][_tokenId] > 0, "NFT NOT STAKED");
    uint256 time = block.timestamp - stakes[msg.sender][_tokenId];
    uint256 reward = calculateRate(time) * time *(10 ** 18) / 1 minutes;
    return reward;
  }

  function unstake(uint256 _tokenId) public {
    //calculate reward
    uint256 reward = calculateReward(_tokenId);
    delete stakes[msg.sender][_tokenId];
    //transfer the nft back to the original owner
    nft.safeTransferFrom(address(this), msg.sender, _tokenId, "");
    //send the reward
    token.transfer(msg.sender, reward);

  }

}