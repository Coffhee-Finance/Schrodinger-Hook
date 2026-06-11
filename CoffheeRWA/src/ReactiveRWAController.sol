// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Arbitrum Sepolia address: 0x1324Db5bD1a6BDaFdc184AaC755D05bfA9e4fFCf
// Reactive Network is not imported here; it is represented as a trusted automation sender that calls this controller. For the MVP/demo

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {
    IHyperlaneMailbox,
    IHyperlaneRecipient
} from "./interfaces/IHyperlaneMailbox.sol";

interface ISchrodinger1155RWAHook {
    function setFrappecinoWhitelist(address token, bool allowed) external;
}

contract ReactiveRWAController is Ownable, IHyperlaneRecipient {
    IHyperlaneMailbox public immutable mailbox;

    address public hook;
    address public trustedReactiveSender;

    mapping(uint32 originDomain => bool allowed) public allowedOriginDomain;
    mapping(bytes32 remoteSender => bool allowed) public allowedRemoteSender;

    mapping(uint256 tokenId => uint256 nav) public latestNAV;
    mapping(uint256 tokenId => uint256 timestamp) public latestNAVTimestamp;

    event HookSet(address indexed hook);
    event TrustedReactiveSenderSet(address indexed sender);
    event OriginDomainAllowed(uint32 indexed domain, bool allowed);
    event RemoteSenderAllowed(bytes32 indexed sender, bool allowed);
    event CrossChainNAVDispatched(
        uint32 indexed destinationDomain,
        bytes32 indexed recipient,
        uint256 indexed tokenId,
        uint256 nav
    );
    event CrossChainNAVReceived(
        uint32 indexed origin,
        bytes32 indexed sender,
        uint256 indexed tokenId,
        uint256 nav,
        uint256 timestamp
    );
    event FrappecinoWhitelistRequested(address indexed token, bool allowed);

    error OnlyMailbox();
    error BadOriginDomain();
    error BadRemoteSender();
    error HookNotSet();

    constructor(
        address mailboxAddress,
        address initialOwner
    ) Ownable(initialOwner) {
        mailbox = IHyperlaneMailbox(mailboxAddress);
    }

    function setHook(address hookAddress) external onlyOwner {
        hook = hookAddress;
        emit HookSet(hookAddress);
    }

    function setTrustedReactiveSender(address sender) external onlyOwner {
        trustedReactiveSender = sender;
        emit TrustedReactiveSenderSet(sender);
    }

    function setAllowedOriginDomain(uint32 domain, bool allowed)
        external
        onlyOwner
    {
        allowedOriginDomain[domain] = allowed;
        emit OriginDomainAllowed(domain, allowed);
    }

    function setAllowedRemoteSender(bytes32 sender, bool allowed)
        external
        onlyOwner
    {
        allowedRemoteSender[sender] = allowed;
        emit RemoteSenderAllowed(sender, allowed);
    }

    function dispatchNAVUpdate(
        uint32 destinationDomain,
        bytes32 recipient,
        uint256 tokenId,
        uint256 nav,
        uint256 timestamp
    ) external payable onlyOwner returns (bytes32 messageId) {
        bytes memory body = abi.encode(tokenId, nav, timestamp);

        messageId = mailbox.dispatch{value: msg.value}(
            destinationDomain,
            recipient,
            body
        );

        emit CrossChainNAVDispatched(
            destinationDomain,
            recipient,
            tokenId,
            nav
        );
    }

    function handle(
        uint32 origin,
        bytes32 sender,
        bytes calldata message
    ) external payable override {
        if (msg.sender != address(mailbox)) revert OnlyMailbox();
        if (!allowedOriginDomain[origin]) revert BadOriginDomain();
        if (!allowedRemoteSender[sender]) revert BadRemoteSender();

        (
            uint256 tokenId,
            uint256 nav,
            uint256 timestamp
        ) = abi.decode(message, (uint256, uint256, uint256));

        latestNAV[tokenId] = nav;
        latestNAVTimestamp[tokenId] = timestamp;

        emit CrossChainNAVReceived(origin, sender, tokenId, nav, timestamp);
    }

    function reactiveWhitelistFrappecino(address token, bool allowed) external {
        if (msg.sender != trustedReactiveSender) {
            revert BadRemoteSender();
        }

        if (hook == address(0)) revert HookNotSet();

        ISchrodinger1155RWAHook(hook).setFrappecinoWhitelist(token, allowed);

        emit FrappecinoWhitelistRequested(token, allowed);
    }
}
