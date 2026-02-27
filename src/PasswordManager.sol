// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {PasswordStore} from "./PasswordStore.sol";
contract PasswordManager {
    PasswordStore public store;

    constructor(address _store) {
        store = PasswordStore(_store);
    }

    function changePassword(string memory newPassword) external {
        store.setPassword(newPassword);
    }

    function readPassword() external view returns (string memory) {
        return store.getPassword();
    }
}