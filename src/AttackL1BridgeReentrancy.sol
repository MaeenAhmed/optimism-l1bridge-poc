// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// استيراد عقد L1StandardBridge من مكتبة Optimism الأصلية
import "optimism/L1/L1StandardBridge.sol";

/// @notice واجهة مبسطة لما نحتاجه من الجسر في PoC
interface IL1StandardBridgeMinimal {
    function depositETH(uint32 _l2Gas, bytes calldata _data) external payable;
}

/// @title AttackL1BridgeReentrancy
/// @notice عقد مهاجم تجريبي لاستكشاف/إثبات cross-layer reentrancy على L1StandardBridge
contract AttackL1BridgeReentrancy {
    IL1StandardBridgeMinimal public bridge;
    bool internal reentered;

    constructor(address _bridge) {
        bridge = IL1StandardBridgeMinimal(_bridge);
    }

    /// @notice نقطة بداية الهجوم: إيداع ETH من L1 إلى L2 عبر الجسر
    function attackDepositETH() external payable {
        require(msg.value > 0, "need ETH");
        bridge.depositETH{value: msg.value}(200_000, "");
    }

    /// @notice fallback ستكون نقطة إعادة الدخول (reentrancy vector)
    fallback() external payable {
        if (!reentered) {
            reentered = true;

            // 🔴 هنا لاحقاً سنضيف منطق إعادة الدخول الفعلي (استدعاء دالة تستغل النافذة)
            // عندما نحدد بدقة نقطة الاتصال الخارجي قبل تحديث الحالة في L1StandardBridge.

            reentered = false;
        }
    }

    receive() external payable {}
}
