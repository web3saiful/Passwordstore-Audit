// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {PasswordStore} from "../src/PasswordStore.sol";
import {DeployPasswordStore} from "../script/DeployPasswordStore.s.sol";

contract PasswordStoreTest is Test {
    PasswordStore public passwordStore;//! src instance
    DeployPasswordStore public deployer;//! script instance
    address public owner;//!the owner of the contract during tests.

    function setUp() public {
        deployer = new DeployPasswordStore();
        passwordStore = deployer.run();
        owner = msg.sender;
     }

    function test_owner_can_set_password() public {
        vm.startPrank(owner);
        string memory expectedPassword = "myNewPassword";
        passwordStore.setPassword(expectedPassword);
        string memory actualPassword = passwordStore.getPassword();
        assertEq(actualPassword, expectedPassword);
    }

     function test_non_owner_reading_password_reverts() public {
        vm.startPrank(address(1));
 
        vm.expectRevert(PasswordStore.PasswordStore__NotOwner.selector);
        passwordStore.getPassword();
    }



    function testFuzz_NonOwnerCanChangePassword_BUG(
    address randomUser,
    string memory randomPassword
) public {

    vm.assume(randomUser != address(this));

    // Attacker changes password
    vm.prank(randomUser);
    passwordStore.setPassword(randomPassword);

    // Owner reads
    string memory stored = passwordStore.getPassword();

    // If this passes → bug confirmed
    assertEq(stored, randomPassword);
  }


function testFuzz_AttackerChangesPassword(string memory randomPassword) public {
    address attacker = address(0x1234); // fixed non-owner

    // Owner sets initial password
    vm.startPrank(owner);
    passwordStore.setPassword("initialPassword");
    vm.stopPrank();

    // Attacker sets a random password
    vm.prank(attacker);
    passwordStore.setPassword(randomPassword);

    // Owner reads the password
    vm.startPrank(owner);
    string memory stored = passwordStore.getPassword();
    vm.stopPrank();

    // Assert the password was changed → confirms bug
    assertEq(stored, randomPassword);
    }
}
