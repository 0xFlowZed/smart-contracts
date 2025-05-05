// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../lib/ERC721A/contracts/ERC721A.sol";
import "../lib/ERC721A/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface ZedPassIntrerface {
    function mint0(address account, uint256 amount) external;

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);
}

contract FZ1x0 is
    ERC721A,
    ERC721AQueryable,
    IERC2981,
    Ownable,
    ReentrancyGuard
{
    using ECDSA for bytes32;
    uint256 public publicSupply = 0;

    enum size {
        None,
        XS,
        S,
        M,
        L,
        XL,
        XXL
    }

    enum colour {
        Default,
        Black,
        Purple,
        Navy,
        Emerald,
        Burgundy
    }

    ZedPassIntrerface public zedPass;
    bool public _zedPassRequired = true;
    uint256 public _zpPerMint = 3;

    mapping(uint256 => bool) public _printed;
    mapping(uint256 => bool) public _editionAllowed;
    mapping(uint256 => size) public _sizeOf;
    mapping(uint256 => colour) public _colourOf;
    mapping(uint256 => uint8) public _edition;

    mapping(address => uint256) private _lastMintBlock;

    address public _admin;
    address public _printer;
    address public _fzWallet;

    uint256 public _price;
    uint256 public _newEditionPrice = 0;

    uint256 public constant _maxSupply = 5_050;
    uint256 public constant _maxPublicSupply = 5_000;
    uint public constant _maxMintPerTx = 10;

    uint256 public _maxCurrentSupply = 0;
    string public _baseTokenURI;

    address public _royaltyRecipient;
    uint256 public _royaltyValue;

    event NewEdition(uint256 tokenId, uint8 edition);
    event Printed(uint256 tokenId, uint8 edition, size size, colour colour);

    constructor(
        address owner,
        address fzWallet
    ) ERC721A("FlowZed 1.0: The Merkle Tree", "FZ1.0") Ownable(owner) {
        _fzWallet = fzWallet;
        _royaltyRecipient = _fzWallet;
        _royaltyValue = 400; // 4%
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin || msg.sender == owner(), "Only Admin");
        _;
    }

    modifier onlyPrinter() {
        require(
            msg.sender == _admin ||
                msg.sender == owner() ||
                msg.sender == _printer,
            "Only Printer"
        );
        _;
    }

    // MARK: - Only Owner
    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

    function setPrinter(address printer) external onlyOwner {
        _printer = printer;
    }

    function setFZWallet(address fzWallet) external onlyOwner {
        _fzWallet = fzWallet;
    }

    function setZedPassAddress(address zp) external onlyOwner {
        zedPass = ZedPassIntrerface(zp);
    }

    function setZedPassRequired(bool required) external onlyOwner {
        _zedPassRequired = required;
    }

    function setZpPerMint(uint256 zpPerMint) external onlyOwner {
        _zpPerMint = zpPerMint;
    }

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    function setNewEditionPrice(uint256 price) external onlyOwner {
        _newEditionPrice = price;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = address(_fzWallet).call{
            value: address(this).balance
        }("");
        require(success, "Failure to withdraw from the FZ1x0 contract");
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // MARK: - Only Admin
    function mintPromo(address to, uint256 tokenId) external onlyAdmin {
        require(tokenId > _maxPublicSupply, "Invalid token ID");
        require(tokenId <= _maxSupply, "Invalid token id");
        require(!_exists(tokenId), "ID owned already");
        _safeMintSpot(to, tokenId);
    }

    function print(
        uint256 tokenId,
        size _size,
        colour _colour,
        bytes32 messageHash,
        bytes calldata signature
    ) external onlyPrinter {
        require(_exists(tokenId), "Token does not exist");
        require(!_printed[tokenId], "Token already printed");
        require(_size != size.None, "Size must be specified");
        require(_colour != colour.Default, "Colour must be specified");
        address signer = messageHash.recover(signature);
        require(signer == ownerOf(tokenId), "Invalid signature");
        _printed[tokenId] = true;
        _sizeOf[tokenId] = _size;
        _colourOf[tokenId] = _colour;
        emit Printed(tokenId, _edition[tokenId], _size, _colour);
    }

    function enableNewPhase(uint256 newMax) external onlyAdmin {
        require(_price > 0, "Price not set");
        require(newMax <= _maxSupply, "Cannot exceed max supply");
        _maxCurrentSupply = newMax;
    }

    function enableNewEdition(
        uint256 tokenId,
        bool allowed
    ) external onlyAdmin {
        _editionAllowed[tokenId] = allowed;
    }

    // MARK: - Only Collector
    function burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only holder can burn tokens.");
        _burn(tokenId);
    }

    function invalidateCurrentEdition(uint256 tokenId) external payable {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only holder can increment edition."
        );
        require(_editionAllowed[tokenId], "New edition not allowed");
        require(msg.value >= _newEditionPrice, "Insufficient funds");
        uint256 excess = msg.value - _newEditionPrice;

        _edition[tokenId] += 1;
        _printed[tokenId] = false;
        _editionAllowed[tokenId] = false;
        _sizeOf[tokenId] = size.None;
        emit NewEdition(tokenId, _edition[tokenId]);

        if (excess > 0) {
            (bool success, ) = payable(msg.sender).call{value: excess}("");
            require(success, "ETH refund failed");
        }
    }

    // MARK: - Public
    function publicMint(uint256 quantity) external payable nonReentrant {
        require(
            _lastMintBlock[msg.sender] != block.number,
            "Calls per block exceeded"
        );
        _lastMintBlock[msg.sender] = block.number;
        require(
            totalSupply() < _maxCurrentSupply,
            "Public minting is not enabled"
        );
        require(quantity <= _maxMintPerTx, "Exceeds max mint per tx");
        uint256 totalCost = _price * quantity;
        require(msg.value >= totalCost, "Insufficient funds");
        uint256 excess = msg.value - totalCost;

        require(
            zedPass != ZedPassIntrerface(address(0)),
            "ZedPass address not set"
        );
        require(
            (totalSupply() + quantity) <= _maxCurrentSupply,
            "Exceeds current supply"
        );
        require(
            (publicSupply + quantity) <= _maxPublicSupply,
            "Exceeds public supply"
        );

        if (_zedPassRequired) {
            require(
                zedPass.balanceOf(msg.sender, 1) > 0 ||
                    balanceOf(msg.sender) > 0,
                "No ZedPass possessed by minter"
            );
        }

        publicSupply += quantity;
        _safeMint(msg.sender, quantity);

        if (excess > 0) {
            (bool success, ) = payable(msg.sender).call{value: excess}("");
            require(success, "ETH refund failed");
        }

        zedPass.mint0(msg.sender, _zpPerMint * quantity);
    }

    // MARK: - Internal
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // MARK: - IERC2981
    function royaltyInfo(
        uint256 /* tokenId */,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = _royaltyRecipient;
        royaltyAmount = (salePrice * _royaltyValue) / 10000;
        return (receiver, royaltyAmount);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // MARK: ERC721A
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _sequentialUpTo()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return _maxPublicSupply;
    }
}
