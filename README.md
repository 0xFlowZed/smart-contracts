# FlowZed Smart Contracts

This repository contains the smart contracts behind **FlowZed Collection 1.0: The Merkle Tree**, a collection of 5,050 one-of-one silk jackets backed by on-chain ownership.

All contracts are written in Solidity and deployed to Ethereum Mainnet.

---

## Structure

```
src/
├── the-merkle-tree/
│ └── flowzed1x0.sol # ERC-721A contract for The Merkle Tree collection
├── zedpass/
│ └── zedpass1x0.sol # ERC-1155 contract for ZedPass and Nomination tokens
```

---

## Contracts

### `flowzed1x0.sol`
The primary ERC-721A contract governing The Merkle Tree collection.
- Ethereum Mainnet address: [0x38d2e875ca963d87801C8FA5f6E3B4EDd21cabE7](https://etherscan.io/address/0x38d2e875ca963d87801c8fa5f6e3b4edd21cabe7)

### `zedpass1x0.sol`
ERC-1155 contract handling ZedPass mechanics.
- Ethereum Mainnet address: [0x06502e996723BBB690777f07cD462411C6Be56DF](https://etherscan.io/address/0x06502e996723BBB690777f07cD462411C6Be56DF)

---

## Audit

This codebase has been audited.
View the audit report hosted directly on the auditors' GitHub [here.](https://github.com/zokyo-sec/audit-reports/blob/main/FlowZed/FlowZed_Zokyo_audit_report_April11th_2025.pdf)

---

FlowZed is a tokenised luxury fashion house building a new frontier of physical permanence and digital ownership. Learn more at [flowzed.com](https://flowzed.com).
