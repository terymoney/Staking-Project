// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";


contract BlackGirl is ERC721, ERC721Enumerable, ERC721Pausable,  ERC721URIStorage, Ownable, IERC2981 {

    event Mint(address indexed to, uint256 indexed tokenId);
    
    uint256 private _nextTokenId;
    uint256 maxSupply = 100;
    uint256 allowlistmaxSupply = 10;

    address private royaltyRecipient;
    uint96 private royaltyPercentage; // Denominated in basis points (bps), so 500 = 5%.

    bool public publicMintopen = false;
    bool public allowlistMintopen = false;

    uint256 public constant maxPerWallet = 1;
    mapping(address => uint256) public Walletmints;

    mapping(address => bool) public allowList;

    constructor(address initialOwner, address _royaltyRecipient, uint96 _royaltyPercentage)
        ERC721("BlackGirl", "BG")
        Ownable(initialOwner)
       
    {
        require(_royaltyRecipient != address(0), "Royalty recipient cannot be zero address");
        require(_royaltyPercentage <= 10000, "Royalty percentage too high");
       
        royaltyRecipient = _royaltyRecipient;
        royaltyPercentage = _royaltyPercentage;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmS6j4NH6Muq1cXRGLBrrCGGXDs6TgkME8HzLT4AWYrLo1/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //MODIFY THE PUBLICMINT AND ALLOWLISTMINT WINDOWS
    function editMintWindows(
        bool  _publicMintopen,
        bool _allowlistMintopen
    ) external onlyOwner{
     publicMintopen = _publicMintopen;
     allowlistMintopen = _allowlistMintopen;   
    }

    //ONLY ALLOW THE PEOPLE ON THE ALLOW LIST TO MINT
    //ADD PUBLICMINTOPEN AND ALLOWLISTMINTOPEN VARIABLES
    function allowlistMint(uint256 amount) public payable  {
        require(allowlistMintopen, "ALLOW LIST CLOSED");
        require(allowList[msg.sender], "YOU ARE NOT ON THE ALLOW LIST");
        require(msg.value ==  amount * 0.0001 ether, "NOT ENOUGH FUNDS");
        require(totalSupply() + amount <= allowlistmaxSupply, "SOLD OUT");
        for (uint256 i = 0; i < amount; i++) {
        internalMint();
    }
        
    }

    //LIMIT TOKEN MINTED PER WALLET
    //ADD PAYMENT
    //LIMIT SUPPLY
    function publicMint(uint256 amount) public payable  {
        require(publicMintopen, "PUBLIC MINT CLOSED");
        require(amount > 0,"MUST MINT ATLEAST ONE TOKEN"); //MUST MINT ATLEAST ONE TOKEN
        require(Walletmints[msg.sender] + amount <= maxPerWallet, "EXCEEDED MAX PER WALLET");
        Walletmints[msg.sender] += amount;
        require(msg.value == amount * 0.001 ether, "NOT ENOUGH FUNDS");
        require(totalSupply() + amount <= maxSupply, "SOLD OUT");
        for (uint256 i = 0; i < amount; i++) {
        internalMint();
    }
        
    }

    //CUT GASES
    function internalMint() internal {
      uint256 tokenId = _nextTokenId++;
     _safeMint(msg.sender, tokenId);  
     emit Mint(msg.sender, tokenId); // Emit Mint event
    }

    //WITHDRAWAL OF THE MONEY FROM THE CONTRACT ADDRESS TO THE OWNER'S ADDRESS
    function withdraw(address _addr) external onlyOwner{
        //GET THE BALANCE OF THE CONTRACT
        uint256 balance = address(this).balance;
        payable(_addr).transfer(balance);
    }

    //POPULATE THE ALLOWLIST
    function setAllowList(address[] calldata addresses) external onlyOwner{
        for(uint256 i = 0; i < addresses.length; i++){
            require(!allowList[addresses[i]], "Address already on the allowlist");
            allowList[addresses[i]] = true;
        }
    }

    // EIP-2981 royalty implementation
    function royaltyInfo(uint256 /*_tokenId*/, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyRecipient;
        royaltyAmount = (_salePrice * royaltyPercentage) / 10000;
    }

    function setRoyaltyInfo(address recipient, uint96 percentage) external onlyOwner {
        royaltyRecipient = recipient;
        royaltyPercentage = percentage;
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId || 
            super.supportsInterface(interfaceId);
    }
}