// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {PasswordStore} from "../src/PasswordStore.sol";
import {DeployPasswordStore} from "../script/DeployPasswordStore.s.sol";
import {PasswordManager} from "../src/PasswordManager.sol";

contract PasswordStoreTest is Test {
    PasswordStore public passwordStore;
    DeployPasswordStore public deployer;
    address public owner;

    function setUp() public {
        deployer = new DeployPasswordStore();
        passwordStore = deployer.run();
        owner = msg.sender;
    }





    // ----------------------
    // Unit Tests
    // ----------------------

    function test_owner_can_set_password() public {
        vm.startPrank(owner);
        string memory expectedPassword = "myNewPassword";
        passwordStore.setPassword(expectedPassword);
        string memory actualPassword = passwordStore.getPassword();
        assertEq(actualPassword, expectedPassword);
        vm.stopPrank();
    }

    function test_non_owner_reading_password_reverts() public {
        address attacker = address(1);
        vm.prank(attacker);
        vm.expectRevert(PasswordStore.PasswordStore__NotOwner.selector);
        passwordStore.getPassword();
    }




    // ----------------------
    // Fuzz Test
    // ----------------------






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





    // ----------------------
    // Invariant Test
    // ----------------------





    function invariant_nonOwnerCanChangePassword() public {
        // generate random non-owner address
        address randomUser = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, block.number)))));
        vm.assume(randomUser != owner);

        string memory randomPassword = "invariantPass";

        // Non-owner changes password
        vm.prank(randomUser);
        passwordStore.setPassword(randomPassword);

        // Owner reads password
        string memory current = passwordStore.getPassword();

        // If this passes → bug exists
        assertEq(current, randomPassword);
    }




// ----------------------
    // Integration Test
    // ----------------------




function test_Integration_NonOwnerAttack() public {
    PasswordManager manager = new PasswordManager(address(passwordStore));

    address attacker = address(0x1234);

    // attacker tries to change password through manager
    vm.prank(attacker);
    manager.changePassword("hacked");

    // owner reads password
    vm.prank(owner);
    string memory stored = passwordStore.getPassword();

    // If this passes → security bug
    assertEq(stored, "hacked");
   }

}