//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/Clones.sol";

struct BullaTag {
    bytes32 creditorTag;
    bytes32 debtorTag;
}
struct Multihash {
    bytes32 hash;
    uint8 hashFunction;
    uint8 size;
}

interface IBullaClaim {
    function init(
        address _bullaManager,
        address payable _owner,
        address payable _creditor,
        address payable _debtor,
        string memory _description,
        uint256 _claimAmount,
        uint256 _dueBy
    ) external;

    function initMultihash(
        address _bullaManager,
        address payable _owner,
        address payable _creditor,
        address payable _debtor,
        string memory _description,
        uint256 _claimAmount,
        uint256 _dueBy,
        Multihash calldata _multihash
    ) external;

    function getCreditor() external view returns (address);

    function getDebtor() external view returns (address);
}

contract BullaBanker {
    address public bullaManager;
    mapping(address => BullaTag) public bullaTags;

    address public claimImplementation;

    event BullaTagUpdated(
        address indexed bullaManager,
        address indexed bullaClaim,
        address indexed updatedBy,
        bytes32 creditorTag,
        bytes32 debtorTag,
        uint256 blocktime
    );

    event BullaBankerCreated(
        address indexed bullaManager,
        address bullaBanker,
        uint256 blocktime
    );

    constructor(address _bullaManager, address _claimImplementation) {
        bullaManager = _bullaManager;
        claimImplementation = _claimImplementation;
        emit BullaBankerCreated(bullaManager, address(this), block.timestamp);
    }

    function createBullaClaim(
        uint256 claimAmount,
        address payable creditor,
        address payable debtor,
        string memory description,
        bytes32 bullaTag,
        uint256 dueBy
    ) public {
        address newClaimAddress = Clones.clone(claimImplementation);

        IBullaClaim(newClaimAddress).init(
            bullaManager,
            payable(msg.sender),
            creditor,
            debtor,
            description,
            claimAmount,
            dueBy
        );

        BullaTag memory newTag;
        if (msg.sender == creditor) newTag.creditorTag = bullaTag;
        if (msg.sender == debtor) newTag.debtorTag = bullaTag;
        bullaTags[newClaimAddress] = newTag;

        emit BullaTagUpdated(
            bullaManager,
            newClaimAddress,
            msg.sender,
            newTag.creditorTag,
            newTag.debtorTag,
            block.timestamp
        );
    }

    function createBullaClaimMultihash(
        uint256 claimAmount,
        address payable creditor,
        address payable debtor,
        string memory description,
        bytes32 bullaTag,
        uint256 dueBy,
        Multihash calldata multihash
    ) external {
        address newClaimAddress = Clones.clone(claimImplementation);

        IBullaClaim(newClaimAddress).initMultihash(
            bullaManager,
            payable(msg.sender),
            creditor,
            debtor,
            description,
            claimAmount,
            dueBy,
            multihash
        );

        BullaTag memory newTag;
        if (msg.sender == creditor) newTag.creditorTag = bullaTag;
        if (msg.sender == debtor) newTag.debtorTag = bullaTag;
        bullaTags[newClaimAddress] = newTag;

        emit BullaTagUpdated(
            bullaManager,
            newClaimAddress,
            msg.sender,
            newTag.creditorTag,
            newTag.debtorTag,
            block.timestamp
        );
    }

    function updateBullaTag(address _bullaClaim, bytes32 newTag) public {
        IBullaClaim bullaClaim = IBullaClaim(_bullaClaim);
        require(
            msg.sender == bullaClaim.getCreditor() ||
                msg.sender == bullaClaim.getDebtor()
        );

        if (msg.sender == bullaClaim.getCreditor())
            bullaTags[_bullaClaim].creditorTag = newTag;
        if (msg.sender == bullaClaim.getDebtor())
            bullaTags[_bullaClaim].debtorTag = newTag;

        emit BullaTagUpdated(
            bullaManager,
            address(bullaClaim),
            msg.sender,
            bullaTags[_bullaClaim].creditorTag,
            bullaTags[_bullaClaim].debtorTag,
            block.timestamp
        );
    }
}
