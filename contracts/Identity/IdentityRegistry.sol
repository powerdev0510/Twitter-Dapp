pragma solidity ^0.6.0;

import "./ClaimHolder.sol";
import "./ClaimTypesRegistry.sol";
import "./ClaimVerifier.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";


contract IdentityRegistry is Ownable, ClaimVerifier {


    mapping(address => bool) public identity;
    
    uint256[] public claimTypes;

    ClaimTypesRegistry public typesRegistry;

    event IdentityRegistered(ClaimHolder indexed identity, uint256 indexed time);
    event IdentityRemoved(ClaimHolder indexed identity, uint256 indexed time);
    event ClaimTypesRegistrySet(address indexed _claimTypesRegistry);
    event TrustedIssuersRegistrySet(address indexed _trustedIssuersRegistry);
 
    modifier isValidIdentity(ClaimHolder _identityContract) {
        require(address(_identityContract) != address(0), "contract address can't be a zero address");
        require(checkValidIdentity(_identityContract),  "Your Claim is not valid for KYC");
        _;
    }

    constructor(address _trustedIssuersRegistry, address _claimTypesRegistry) public {
        issuersRegistry = TrustedIssuersRegistry(_trustedIssuersRegistry);
        emit TrustedIssuersRegistrySet(_trustedIssuersRegistry);
        typesRegistry = ClaimTypesRegistry(_claimTypesRegistry);
        emit ClaimTypesRegistrySet(_claimTypesRegistry);
    }


    function registerIdentity(ClaimHolder _identity) isValidIdentity(_identity) public returns (bool) {
        require(identity[address(_identity)] == false);
        identity[address(_identity)] = true;
        emit IdentityRegistered(_identity, now);
        return true;
    }


    function removeIdentity(ClaimHolder _identity) onlyOwner public returns (bool) {
        require(identity[address(_identity)] == true);
        emit IdentityRemoved(_identity, now);
        delete identity[address(_identity)];
        return true;
    }


    function setClaimTypesRegistry(address _claimTypesRegistry) public onlyOwner {
        typesRegistry = ClaimTypesRegistry(_claimTypesRegistry);
        emit ClaimTypesRegistrySet(_claimTypesRegistry);
    }


    function setTrustedIssuerRegistry(address _trustedIssuersRegistry) public onlyOwner {
        issuersRegistry = TrustedIssuersRegistry(_trustedIssuersRegistry);
        emit TrustedIssuersRegistrySet(_trustedIssuersRegistry);
    }

   
    function checkValidIdentity(ClaimHolder _identity) public returns (bool) {
        claimTypes = typesRegistry.getClaimTypes();
        for(uint i = 0; i < claimTypes.length; i++) {
            if(claimIsValid(_identity, claimTypes[i])) {
                return true;
            }
        }
        return false;
    }

    function isValidUser(ClaimHolder _identity) public view returns (bool){
        return identity[address(_identity)];
    }
} 