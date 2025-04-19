// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ERC1967Proxy
 * @dev Minimal, hardened upgradeable proxy using EIP-1967 standard.
 * Stores logic address in a predefined slot and safely delegates calls.
 */
contract ERC1967Proxy {
    // EIP-1967 implementation slot: keccak256("eip1967.proxy.implementation") - 1
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Initializes the proxy with an implementation and optional initialization data.
     * @param _logic Address of the implementation contract.
     * @param _initData Optional data to call during construction.
     */
    constructor(address _logic, bytes memory _initData) {
        require(_logic != address(0), "Proxy: zero implementation address");

        assembly {
            sstore(IMPLEMENTATION_SLOT, _logic)
        }

        if (_initData.length > 0) {
            (bool success, bytes memory result) = _logic.delegatecall(_initData);
            require(success, string(result));
        }
    }

    /**
     * @dev Delegates execution to the implementation contract.
     * This is a low-level function that doesn't return to its internal call site.
     */
    fallback() external payable {
        _delegate(_implementation());
    }

    /**
     * @dev Fallback for plain Ether transfers.
     */
    receive() external payable {
        _delegate(_implementation());
    }

    /**
     * @dev Returns the current implementation address.
     * @return impl Address of the current logic contract.
     */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
        require(impl != address(0), "Proxy: implementation not set");
    }

    /**
     * @dev Performs the delegatecall to the implementation contract.
     * @param impl Address of the logic contract.
     */
    function _delegate(address impl) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
