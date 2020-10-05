pragma solidity ^0.6.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";


contract ClaimTypesRegistry is Ownable {
    uint256[] public claimTypes;

    event claimTypeAdded(uint256 indexed claimType);
    event claimTypeRemoved(uint256 indexed claimType);

    function addClaimType(uint256 claimType) public onlyOwner {
        uint length = claimTypes.length;
        for (uint i = 0; i < length; i++) {
            require(claimTypes[i] != claimType, "claimType already exists");
        }
        claimTypes.push(claimType);
        emit claimTypeAdded(claimType);
    }

    function removeClaimType(uint256 claimType) public onlyOwner {
        uint length = claimTypes.length;
        for (uint i = 0; i < length; i++) {
            if (claimTypes[i] == claimType) {
                (claimTypes[i], claimTypes[length - 1]) = (claimTypes[length - 1], claimTypes[i]);
                emit claimTypeRemoved(claimType);
                return;
            }
        }
    }

    function getClaimTypes() public view  returns (uint256[] memory) {
        return claimTypes;
    }
}