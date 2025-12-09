
```markdown
# PoC: L1StandardBridge ETH Deposit Behavior on OP Mainnet (Mainnet Fork + Foundry)

This repository contains a minimal, reproducible Proof-of-Concept (PoC) designed to test whether a **cross-layer reentrancy vulnerability** can be triggered during an ETH deposit from L1 into Optimism’s canonical L1 bridge.

The PoC operates directly against a **live Ethereum mainnet fork**, ensuring that the tested behavior reflects the real deployed bridge contract.

---

## 🔗 **Relevant Files (Gists)**

| File | Description | Link |
|------|-------------|------|
| **foundry.toml** | Foundry configuration with full remappings for Optimism Bedrock & OpenZeppelin | https://gist.github.com/MaeenAhmed/9c19bc373b8c1f692b45c8a05d8b18cc |
| **AttackL1BridgeReentrancy.sol** | Minimal attacker contract attempting to trigger reentrancy via depositETH | https://gist.github.com/MaeenAhmed/c1270ea9a4ebfe10b90b3e90efb620c3 |
| **L1BridgeReentrancy.t.sol** | Foundry test performing a real mainnet-fork attack attempt | https://gist.github.com/MaeenAhmed/7a614ab667b3133c028a51a0bd8689b2 |

---

# 📌 **1. Overview**

This PoC evaluates whether an attacker-controlled L1 contract can:

1. Call `depositETH` on the **real Optimism L1StandardBridge**
2. Receive an unexpected external callback during processing (via fallback)
3. Use that callback window to perform **cross-layer reentrancy**  
4. Ultimately double-spend ETH across L1 and L2

The tested contract is the **canonical OP Mainnet L1 Ethereum bridge**:

```

L1StandardBridge
0xeb9bf100225c214Efc3E7C651ebbaDcF85177607

```

The PoC demonstrates actual execution behavior using a mainnet fork.

---

# 📌 **2. Project Structure**

```

optimism-l1bridge-poc/
│
├── src/
│   └── AttackL1BridgeReentrancy.sol
│
├── test/
│   └── L1BridgeReentrancy.t.sol
│
└── foundry.toml

```

Dependencies are vendored into:

```

lib/optimism
lib/openzeppelin-contracts
lib/forge-std

````

---

# 📌 **3. Attacker Contract Summary**

The attacker contract:

- Stores a reference to the real L1 bridge
- Attempts to call `depositETH` with 1 ETH
- Provides a `fallback()` entrypoint for capturing unexpected callbacks  
- Serves as a probe for whether the Optimism bridge interacts with untrusted callers before updating internal state

The PoC is intentionally minimal: the goal is to validate the **reentrancy window**, not the final exploit payload.

---

# 📌 **4. Test Summary**

The test:

1. Forks **Ethereum mainnet**
2. Deploys the attacker contract
3. Funds an EOA with 100 ETH
4. Calls the attacker → which calls the bridge
5. Monitors:
   - revert messages  
   - event emissions  
   - state updates  
   - attacker contract balance  
6. Captures behavior through verbose call traces (`-vvv`)

The PoC expects a revert enforcing the **onlyEOA** restriction.

---

# 📌 **5. Running the PoC**

### **Prerequisites**
- Foundry (`forge`, `anvil`, `cast`)
- A mainnet RPC endpoint (Alchemy, Infura, etc.)

### **Run Commands**

```bash
export MAINNET_RPC_URL="https://eth-mainnet.g.alchemy.com/v2/<YOUR_KEY>"
forge test -vvv
````

---

# 📌 **6. Expected Output**

A successful run yields:

```
[PASS] test_AttemptReentrancy()
Logs:
  Attacker contract balance BEFORE: <value>
  Attacker contract balance AFTER:  <same value>

Revert Expected:
  StandardBridge: function can only be called from an EOA
```

Meaning:

* The **real L1 bridge contract** rejects depositETH when invoked by a contract
* Internal bridge logic (`onlyEOA`) prevents this specific reentrancy path
* No ETH is lost, no state is mutated, and attacker cannot reenter

---

# 📌 **7. Security Interpretation**

This PoC demonstrates that:

### ✔️ The tested attack path is **not reachable** on OP Mainnet

Because `depositETH` enforces:

```
onlyEOA → EOA.isSenderEOA()
```

### ✔️ No external callback to the attacker occurs

Thus no fallback-driven reentrancy window exists in this execution path.

### ✔️ A contract cannot initiate the ETH deposit logic

Meaning the canonical deposit route is safe from reentrancy initiated by smart contracts.

---

# 📌 **8. Next Steps (Advanced Analysis)**

This PoC validates only one path: `depositETH`.

To fully test for **cross-layer reentrancy** possibilities, next attack surfaces include:

### 🧪 **finalizeBridgeETH (L1 finalization path)**

Potential for reentrancy if:

* External calls occur before state updates
* L2→L1 message replaying triggers unexpected execution

### 🧪 **finalizeBridgeERC20**

ERC20 flows often involve:

* token callbacks
* untrusted contract interactions
* meta-transaction paths

### 🧪 **Legacy bridge flows**

Some older OP Stack deployments behave differently.

### 🧪 **Message relaying from L2 to L1**

A particularly important path because:

* Contracts *do* receive calls during L2 message execution
* State may be updated after external calls
* This is where real cross-layer reentrancy becomes feasible

---

# 📌 **9. Conclusion**

This PoC:

* Correctly targets the real Optimism L1 bridge via a mainnet fork
* Demonstrates actual EVM behavior instead of hypothetical reasoning
* Verifies that the tested ETH-deposit flow is protected
* Establishes a foundation for deeper cross-layer reentrancy research

Next steps (phase 2) will expand analysis toward finalization paths and ERC20 bridging where reentrancy primitives are **much more likely** to appear.

```