
# 🛡️ DeFi Guardian – Autonomous Risk Manager & Yield Optimizer

**DeFi Guardian** is a modular and secure smart contract system built to protect digital assets in decentralized finance. By intelligently assessing risk and automatically rebalancing yields across protocols, it provides peace of mind for both individual investors and DeFi platforms.

**Mainnet Deployment:**  
🔗 [Base Mainnet](https://basescan.org/address/0x34bd4ca19f05ff704be9d3de5c8f6fdf4a82f2c6)  
**Testnet Deployment:**  
🧪 [Base Sepolia Testnet](https://sepolia.basescan.org/address/0x34bd4ca19f05ff704be9d3de5c8f6fdf4a82f2c6)

---

## 💡 What It Does

- **Risk Monitoring**: Tracks market volatility and triggers withdrawals if risks exceed safe thresholds.
- **Yield Optimization**: Shifts funds between supported DeFi protocols based on comparative yield performance.
- **Dynamic Portfolio Adjustments**: Continuously evaluates asset performance, reallocating capital autonomously.
- **Security First**: Owner-controlled, with fail-safe emergency withdrawal, customizable thresholds, and modular extensibility.

---

## 🔍 Core Features

### 🔁 **Automated Yield Rebalancing**
When a supported token in a low-performing protocol is compared to another with a higher APY (above a set threshold), funds are automatically withdrawn and redeployed to the higher-yielding option.

### ⚠️ **Risk Mitigation**
Contracts use on-chain oracles to track price volatility. If an asset experiences abnormal price movement or has outdated data, the system withdraws funds from its protocol to prevent loss.

### ⚙️ **Customizable Thresholds**
Owners can tune:
- Volatility threshold (e.g., 10% market movement)
- Minimum yield differential required to trigger rebalancing
- Maximum staleness before considering data invalid

### 📊 **Multi-Asset, Multi-Protocol**
- Supports multiple ERC-20 tokens
- Allows registration of different DeFi yield protocols per token

### 🔐 **Owner-Only Control**
All key operations—deposits, withdrawals, configuration—are restricted to the contract owner for security.

---

## 🧱 Architecture Overview

- **Asset Struct**
  - `amount`: Amount deposited
  - `lastPrice`: Last known price of token (for volatility detection)
  - `protocol`: Yield protocol where the token is allocated
  - `lastUpdate`: Timestamp of last update

- **Oracle Interface**
  - Fetches latest price per token to support risk checks.

- **YieldProtocol Interface**
  - Abstracts away protocol-specific logic with common `deposit`, `withdraw`, and `getYield` functions.

---

## 📘 Usage Guide

### ➕ Add a Supported Token
```solidity
addSupportedToken(tokenAddress, protocolAddress);
```
Registers a token and links it to a DeFi protocol.

### 💰 Deposit Assets
```solidity
deposit(tokenAddress, amount);
```
Transfers tokens from the owner to this contract and deposits them in the associated protocol.

### 📉 Monitor Risk
```solidity
monitorAllRisks();
```
Scans every registered token and withdraws if volatility exceeds threshold or price data is outdated.

### 📈 Optimize Yield
```solidity
optimizeAllYields();
```
Compares all token-pairs to find yield optimization opportunities.

### 🆘 Emergency Withdraw
```solidity
emergencyWithdraw(tokenAddress);
```
Withdraws all funds from a token's protocol and returns them to the owner.

---

## 📦 Example Workflow

1. Owner adds USDC and DAI as supported tokens.
2. Owner deposits 10,000 USDC into Protocol A.
3. Oracle detects USDC price drop beyond 10% — the contract automatically withdraws funds.
4. Contract compares DAI in Protocol B and USDC in Protocol A — if DAI yields 5% more, USDC is moved to DAI in Protocol B.
5. Owner checks asset status via `getAssetStatus`.

---

## 🔒 Security & Best Practices

- **OnlyOwner Access**: All key functions are restricted to the contract deployer.
- **Safe Withdrawals**: Includes a manual emergency withdrawal feature.
- **Oracle Integration**: Make sure to use reliable price feeds like Chainlink.
- **Protocol Audits**: Only connect to audited and trusted DeFi yield platforms.

---

## 📈 Monitoring & Maintenance

- Regularly call `monitorAllRisks()` and `optimizeAllYields()` (can be automated via a bot or Chainlink Automation).
- Adjust thresholds based on current market volatility.
- Use `getAssetStatus(token)` to view details on any supported token.

---

## 🌐 Live Deployments

| Network     | Address                                                                 |
|-------------|--------------------------------------------------------------------------|
| Base Mainnet   | [`0x34bd4ca1...`](https://basescan.org/address/0x34bd4ca19f05ff704be9d3de5c8f6fdf4a82f2c6)        |
| Base Sepolia   | [`0x34bd4ca1...`](https://sepolia.basescan.org/address/0x34bd4ca19f05ff704be9d3de5c8f6fdf4a82f2c6)  |

---

## 🧩 Extend the System

The modular nature of DeFi Guardian allows for:

- Swapping out oracles or price feeds
- Adding new strategy layers (e.g., options hedging)
- Integrating governance modules (e.g., DAO voting on thresholds)
- Building dashboards on top of `getAssetStatus`, `getAllTokens`, and event logs

---

## 📝 License

This project is licensed under the **MIT License** — use, modify, and share freely.
