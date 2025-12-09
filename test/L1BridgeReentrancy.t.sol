// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import "../src/AttackL1BridgeReentrancy.sol";

contract L1BridgeReentrancyTest is Test {
    // عقد Optimism L1StandardBridge الحقيقي على Ethereum mainnet
    // العنوان بصيغة checksummed صحيحة
    address constant L1_BRIDGE_MAINNET =
        0xeb9bf100225c214Efc3E7C651ebbaDcF85177607;

    AttackL1BridgeReentrancy attacker;
    address constant ATTACKER_EOA = address(0xBEEF);

    function setUp() public {
        // استخدام RPC من متغيّر البيئة MAINNET_RPC_URL
        string memory rpcUrl = vm.envString("MAINNET_RPC_URL");
        vm.createSelectFork(rpcUrl);

        // نشر عقد المهاجم على الفورك مع توجيه للجسر الحقيقي
        attacker = new AttackL1BridgeReentrancy(L1_BRIDGE_MAINNET);

        // تزويد المهاجم برصيد ETH على الفورك
        vm.deal(ATTACKER_EOA, 100 ether);
    }

    function test_AttemptReentrancy() public {
        uint256 beforeBalance = address(attacker).balance;
        console.log("Attacker contract balance BEFORE:", beforeBalance);

        // ✅ نتوقع أن الجسر سيرفض النداء لأنه من عقد وليس من EOA
        vm.expectRevert(
            bytes("StandardBridge: function can only be called from an EOA")
        );

        vm.prank(ATTACKER_EOA);
        attacker.attackDepositETH{value: 1 ether}();

        uint256 afterBalance = address(attacker).balance;
        console.log("Attacker contract balance AFTER:", afterBalance);

        // بما أن العملية رجعت بـ revert، رصيد عقد المهاجم لا يجب أن يتغير
        assertEq(afterBalance, beforeBalance, "no ETH should remain in attacker");
    }
}
