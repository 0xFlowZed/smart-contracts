// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ZedPass1x0 is ERC1155, Ownable, ReentrancyGuard {
    string public constant name = "ZedPass 1.0";
    string public constant symbol = "ZP1x0";

    uint256 public totalSupply0;
    uint256 public totalSupply1;
    mapping(uint256 => string) public _tokenURIs;

    address public _admin;
    address public _fzContract;

    event Nomination(address from, address to);

    constructor(address owner) ERC1155("uri//tbc") Ownable(owner) {}

    modifier onlyAdmin() {
        require(msg.sender == _admin || msg.sender == owner(), "Only Admin");
        _;
    }

    modifier onlyContract() {
        require(
            msg.sender == _fzContract ||
                msg.sender == _admin ||
                msg.sender == owner(),
            "Only Admin"
        );
        _;
    }

    // MARK: - Only Owner
    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

    function setFzContract(address fzContract) external onlyOwner {
        _fzContract = fzContract;
    }

    function setTokenUri(
        uint256 tokenId,
        string memory _uri
    ) external onlyOwner {
        _tokenURIs[tokenId] = _uri;
    }

    // MARK: only Admin
    function mint0(
        address account,
        uint256 amount
    ) external onlyContract nonReentrant {
        _mint(account, 0, amount, "");
        totalSupply0 += amount;
    }

    function mint1(
        address account,
        uint256 amount
    ) external onlyAdmin nonReentrant {
        _mint(account, 1, amount, "");
        totalSupply1 += amount;
        emit Nomination(msg.sender, account);
    }

    // MARK: - Public
    function burn(uint256 tokenId, uint256 amount) external {
        require(
            balanceOf(msg.sender, tokenId) >= amount,
            "Insufficient tokens owned to burn"
        );
        _burn(msg.sender, tokenId, amount);
        if (tokenId == 0) {
            totalSupply0 -= amount;
        } else {
            totalSupply1 -= amount;
        }
    }

    // MARK: - Overrides
    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        // If set via setTokenUri, return that, otherwise return base
        if (bytes(_tokenURIs[tokenId]).length > 0) {
            return _tokenURIs[tokenId];
        }
        return super.uri(tokenId); // or return a default
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        // Check standard approval
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        require(id == 0, "Tokens with ID > 0 are soulbound");

        // If tokenId == 0, "upgrade" to tokenId == 1
        // Burn from the sender
        _burn(from, 0, amount);
        totalSupply0 -= amount;

        // Mint the same amount of tokenId == 1 to the recipient
        _mint(to, 1, amount, data);
        totalSupply1 += amount;

        emit Nomination(from, to);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        // Standard length check
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        uint256 totalBurn0;
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == 0) {
                totalBurn0 += amounts[i];
            }
        }

        safeTransferFrom(from, to, 0, totalBurn0, data);
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override {
        // If it's a normal transfer (from != address(0) && to != address(0)),
        // and any token ID is > 0, revert.
        if (from != address(0) && to != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                if (ids[i] > 0) {
                    revert("Tokens with ID > 0 are soulbound");
                }
            }
        }
        super._update(from, to, ids, values);
    }
}
