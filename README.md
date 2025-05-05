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

### `zedpass1x0.sol`
ERC-1155 contract handling ZedPass mechanics.

---

## Audit

This codebase has been audited.
View the audit report hosted directly on the auditors' GitHub [here.](https://github.com/zokyo-sec/audit-reports/blob/main/FlowZed/FlowZed_Zokyo_audit_report_April11th_2025.pdf)

---

FlowZed is a tokenised luxury fashion house building a new frontier of physical permanence and digital ownership. Learn more at [flowzed.com](https://flowzed.com).
