// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;
import "./Owned.sol";

interface IWallet {
  
    function implementation() external view returns (address);
}


contract WalletDetector is Owned {
	
    // The accepted code hashes
    bytes32[] private codes;
    // The accepted implementations
    address[] private implementations;
    // mapping to efficiently check if a code is accepted
    mapping (bytes32 => Info) public acceptedCodes;
    // mapping to efficiently check is an implementation is accepted
    mapping (address => Info) public acceptedImplementations;

    struct Info {
        bool exists;
        uint128 index;
    }

    // emits when a new accepted code is added
    event CodeAdded(bytes32 indexed code);
    // emits when a new accepted implementation is added 
    event ImplementationAdded(address indexed implementation);

    constructor(bytes32[] memory _codes, address[] memory _implementations) {
        for(uint i = 0; i < _codes.length; i++) {
            addCode(_codes[i]);
        }
        for(uint j = 0; j < _implementations.length; j++) {
            addImplementation(_implementations[j]);
        }
    }

    /**
    * @notice Adds a new accepted code hash.
    * @param _code The new code hash.
    */
    function addCode(bytes32 _code) public onlyOwner {
        require(_code != bytes32(0), "AWR: empty _code");
        Info storage code = acceptedCodes[_code];
        if(!code.exists) {
            codes.push(_code);
            code.exists = true;
            code.index = uint128(codes.length - 1);
            emit CodeAdded(_code);
        }
    }
	
    /**
    * @notice Adds a new accepted implementation.
    * @param _impl The new implementation.
    */
    function addImplementation(address _impl) public onlyOwner {
        require(_impl != address(0), "AWR: empty _impl");
        Info storage impl = acceptedImplementations[_impl];
        if(!impl.exists) {
            implementations.push(_impl);
            impl.exists = true;
            impl.index = uint128(implementations.length - 1);
            emit ImplementationAdded(_impl);
        }
    }

    /**
    * @notice Adds a new accepted code hash and implementation from a deployed  wallet.
    * @param _Wallet The deployed  wallet.
    */
    function addCodeAndImplementationFromWallet(address _Wallet) external onlyOwner {
        bytes32 codeHash;   
        // solhint-disable-next-line no-inline-assembly
        assembly { codeHash := extcodehash(_Wallet) }
        addCode(codeHash);
        address implementation = IWallet(_Wallet).implementation(); 
        addImplementation(implementation);
    }

    /**
    * @notice Gets the list of accepted implementations.
    */
    function getImplementations() public view returns (address[] memory) {
        return implementations;
    }

    /**
    * @notice Gets the list of accepted code hash.
    */
    function getCodes() public view returns (bytes32[] memory) {
        return codes;
    }

    /**
    * @notice Checks if an address is an wallet
    * @param _wallet The target wallet
    */
    function isArgentWallet(address _wallet) external view returns (bool) {
        bytes32 codeHash;    
        // solhint-disable-next-line no-inline-assembly
        assembly { codeHash := extcodehash(_wallet) }
        return acceptedCodes[codeHash].exists && acceptedImplementations[IWallet(_wallet).implementation()].exists;
    }
}
