// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./security/ERC721PausableEach.sol";

contract Villain is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    ERC721PausableEach
{
    event Receive(address from, uint amount);

    using Counters for Counters.Counter;
    using SafeMath for uint256;

    address payable public communityVault;
    uint256 public feeBpsForCommunity = 400;
    uint256 public feeBpsForGenesis = 100;
    uint256 public fee = feeBpsForCommunity + feeBpsForGenesis;
    uint256 public saleCost = 500 ether;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    uint256 public maxSupply;
    mapping(uint256 => uint256) refundAmountOf;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 maxSupply_
    ) ERC721(name, symbol) {
        maxSupply = maxSupply_;
        _baseTokenURI = baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    receive() payable external {
        uint256 feeForCommunity = msg.value.mul(feeBpsForCommunity.div(10000, "Error feeBpsForCommunity.div"));
        uint256 feeForGenesis = msg.value.mul(feeBpsForGenesis.div(10000, "Error feeBpsForGenesis.div"));
        uint256 refundAmount = msg.value - feeForCommunity - feeForGenesis;
        communityVault.transfer(feeForCommunity);
        payable(this.ownerOf(0)).transfer(refundAmount);
        emit Receive(msg.sender, refundAmount);
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupply = newMaxSupply;
    }

    function _mint(address to) private {
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    // balance is not power in villains
    function mint(uint256 amount) public virtual payable {
        require(amount + totalSupply() <= maxSupply, "totalSupply cannot beyond maxSupply");
        require(saleCost == msg.value, "ss"); // TODO: error message;
        require(amount * saleCost == msg.value, "ss"); // TODO: error message;
        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender);
        }
        payable(msg.sender).transfer(msg.value);
    }

    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Villain: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Villain: must have pauser role to unpause");
        _unpause();
    }

    function pauseToken(uint256 tokenId) public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Villain: must have pauser role to pause");
        _pauseToken(tokenId);
    }

    function unpauseToken(uint256 tokenId) public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Villain: must have pauser role to pause");
        _unpauseToken(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable, ERC721PausableEach) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
