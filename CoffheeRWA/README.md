# The Schrödinger Hook: Encrypted Market Infrastructure for RWAs

The **Schrödinger Hook** is a privacy-preserving Uniswap v4 Hook designed for Real-World Assets (RWAs), institutional portfolios, and encrypted trading strategies.

By combining **Uniswap v4 Hooks**, **Fully Homomorphic Encryption (FHE)**, **Tellor Oracles**, and **Reactive Network automation**,, the Schrödinger Hook enables portfolio management and execution logic to remain private while assets continue to settle transparently on public blockchains.

The protocol introduces a new category of market infrastructure where allocations, exposures, rebalance decisions, and strategy parameters can remain encrypted while preserving composability with existing DeFi ecosystems.

---

# Architecture Overview

The protocol separates data ingestion, truth verification, automation, and execution into independent layers.

```text
┌───────────────────────────────┐
│ External Data Layer           │
│ RWA APIs               │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│ Oracle Layer                  │
│ Tellor Oracle Network         │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│ Automation Layer              │
│ Reactive Network              │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│ Execution Layer               │
│ Schrödinger Hook              │
│ Encrypted ERC-1155 Positions  │
└───────────────────────────────┘
```

This architecture ensures that smart contracts never depend directly on web APIs or centralized automation infrastructure.

---

# Uniswap v4 Integration

The Schrödinger Hook is implemented as a **Uniswap v4 Hook**.

The hook attaches directly to Uniswap v4 pools and enables custom execution logic before and after pool interactions.

Examples include:

* Dark Pool JIT Rebalancing
* Encrypted portfolio management
* RWA allocation strategies
* Selective disclosure workflows
* Compliance-aware execution

The hook does not replace Uniswap's settlement engine.

Instead, it augments liquidity pools with encrypted state management and programmable execution logic.

---

# Core Infrastructure Components

## 1. Tellor Oracle Layer

The Schrödinger Hook does not trust external APIs directly.

Instead, data from RWA providers is normalized and published to Tellor, where it becomes part of a cryptoeconomically secured oracle layer.

### Responsibilities

* RWA pricing
* Net Asset Value (NAV)
* Yield information
* Asset status updates
* Compliance status

### Why Tellor

Tellor acts as the protocol's economic truth layer.

By consuming oracle data rather than direct API responses, the hook gains:

* Tamper resistance
* Historical data verification
* Decentralized reporting
* Reduced trust assumptions

The hook consumes Tellor data through the `TellorRWAOracleAdapter`.

---

## 2. Reactive Network Automation Layer

Reactive Network serves as the protocol's event-driven automation layer.

Rather than relying on centralized keeper bots, Reactive Network continuously monitors oracle state and trigger conditions.

Examples include:

* NAV changes
* Price movements
* Yield adjustments
* Portfolio drift thresholds
* Compliance status updates

When a predefined condition is met, Reactive Network automatically triggers the appropriate action through the `ReactiveRWAController`.

This allows encrypted strategies to remain synchronized with market conditions without manual intervention.

---

## 3. Schrödinger Hook Execution Layer

The Schrödinger Hook is responsible for encrypted portfolio management and strategy execution.

Using Fully Homomorphic Encryption (FHE), the hook maintains encrypted strategy state while interacting with public settlement infrastructure.

Encrypted data may include:

* Portfolio allocations
* Exposure metrics
* Rebalance thresholds
* Risk parameters
* Position metadata

The result is a privacy-preserving execution environment that minimizes information leakage while preserving on-chain composability.

---

# The Schrödinger RWA Hook

The Schrödinger RWA Hook extends the architecture to tokenized real-world assets.

These positions are represented inside the protocol through encrypted ERC-1155 wrappers.

The wrapper abstracts the underlying asset while allowing the hook to:

* Monitor NAV changes
* Track compliance status
* Evaluate portfolio drift
* Execute automated rebalances
* Manage multi-asset strategies

without exposing portfolio composition to the public market.

---

# Key Problems Solved

## MEV Resistance

The hook reduces information leakage associated with portfolio management and large allocation changes.

By keeping strategy state encrypted, market participants cannot easily identify or exploit institutional rebalancing activity.

---

## Selective Disclosure

Institutions often require privacy while simultaneously satisfying auditors, regulators, or compliance teams.

The Schrödinger Hook supports programmable access controls through functions such as:

```solidity
grantPositionViewAccess(...)
```

This allows authorized parties to view encrypted strategy information without exposing it publicly.

---

## Oracle-Based Trust Model

The hook does not rely on direct API access.

All market-sensitive RWA information flows through Tellor's oracle network before reaching execution logic.

This creates a cleaner and more auditable trust model.

---

## Autonomous Portfolio Management

Reactive Network enables automated strategy execution based on verified oracle data.

This removes the need for centralized keeper infrastructure while ensuring portfolios remain aligned with market conditions.

---

# Technology Stack

* Uniswap v4 Hooks
* Fully Homomorphic Encryption (FHE)
* Tellor Oracle Network
* Reactive Network
* ERC-1155 Multi-Token Standard
* Solidity
* Foundry

---

# Quick Start

## Install Dependencies

```bash
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std
npm install -D @cofhe/foundry-plugin@^0.5.2 @cofhe/mock-contracts@^0.5.2 @fhenixprotocol/cofhe-contracts@^0.1.3 @openzeppelin/contracts
```

## Build

```bash
forge build
```

## Run Tests

```bash
forge test -vvvv
```

---

# Vision

The Schrödinger Hook introduces a new category of encrypted market infrastructure.

By combining FHE, decentralized oracles, autonomous automation, and cross-chain execution, the protocol enables institutions to bring real-world assets on-chain without sacrificing privacy, security, or composability.

