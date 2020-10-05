pragma solidity ^0.6.0;

import "./ClaimHolder.sol";

import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract TrustedIssuersRegistry is Ownable {
    //Mapping between a trusted issuer index and its corresponding identity contract address.
    mapping(uint => ClaimHolder) trustedIssuers;
    //Mapping between a trusted issuer address and true/false if address is/is not trusted issuer
    mapping(address => bool) public isTrustedIssuers;

    //Array stores the trusted issuer indexes
    uint[] public indexes;

    event TrustedIssuerAdded(uint indexed index, ClaimHolder indexed trustedIssuer);
    event TrustedIssuerRemoved(uint indexed ndex, ClaimHolder indexed trustedIssuer);
    event TrustedIssuerUpdated(uint indexed index, ClaimHolder indexed oldTrustedIssuer, ClaimHolder indexed newTrustedIssuer);

    function addTrustedIssuer(ClaimHolder _trustedIssuer, uint index) public onlyOwner {
        require(index > 0);
        require(address(trustedIssuers[index]) == address(0), "A trustedIssuer already exists by this name");
        require(address(_trustedIssuer) != address(0));
        uint length = indexes.length;
        for (uint i = 0; i < length; i++) {
            require(_trustedIssuer != trustedIssuers[indexes[i]], "Issuer address already exists in another index");
        }
        trustedIssuers[index] = _trustedIssuer;
        isTrustedIssuers[address(_trustedIssuer)] = true;
        indexes.push(index);
        emit TrustedIssuerAdded(index, _trustedIssuer);
    }

    function removeTrustedIssuer(uint index) public onlyOwner {
        require(index > 0);
        require(address(trustedIssuers[index]) != address(0), "No such issuer exists");
        isTrustedIssuers[address(trustedIssuers[index])] = false;
        delete trustedIssuers[index];
        emit TrustedIssuerRemoved(index, trustedIssuers[index]);
        uint length = indexes.length;
        for (uint i = 0; i < length; i++) {
            if (indexes[i] == index) {
                (indexes[i],  indexes[length - 1]) = (indexes[length - 1], indexes[i]);
                return;
            }
        }
    }

  
    function getTrustedIssuers() public view returns (uint[] memory) {
        return indexes;
    }

    function getTrustedIssuer(uint index) public view returns (ClaimHolder) {
        require(index > 0);
        require(address(trustedIssuers[index]) != address(0), "No such issuer exists");
        return trustedIssuers[index];
    }

    function updateIssuerContract(uint index, ClaimHolder _newTrustedIssuer) public onlyOwner {
        require(index > 0);
        require(address(trustedIssuers[index]) != address(0), "No such issuer exists");
        uint length = indexes.length;
        for (uint i = 0; i < length; i++) {
            require(trustedIssuers[indexes[i]] != _newTrustedIssuer, "Address already exists");
        }
        emit TrustedIssuerUpdated(index, trustedIssuers[index], _newTrustedIssuer);
        trustedIssuers[index] = _newTrustedIssuer;
    }
    
    function checkIsTrustedIssuer(address _trustedIssuerIdentity) public returns (bool) {
        return isTrustedIssuers[_trustedIssuerIdentity];
    }

}