forge script script/DeploySchrodingerHookRWA.s.sol \
  --rpc-url https://sepolia-rollup.arbitrum.io/rpc \
  --private-key \
  --broadcast \
  --sig "run(address,address,address)" \
   0x0000000000000000000000000000000000000001 \
   0x0000000000000000000000000000000000000001 \
   0x0000000000000000000000000000000000000001


   == Return ==
hook: contract Schrodinger1155RWAHook 0x66accaC6c88dcC3474013515eC3EE5Ecd3593D90
controller: contract ReactiveRWAController 0xd1E172c7617fB6e119E8dAc9a5c2c8A1AA5B416e
oracleAdapter: contract TellorRWAOracleAdapter 0xaa1dA24537F12c9B64006f1A196600478AF92587

== Logs ==
  Schrodinger1155RWAHook: 0x66accaC6c88dcC3474013515eC3EE5Ecd3593D90
  ReactiveRWAController: 0xd1E172c7617fB6e119E8dAc9a5c2c8A1AA5B416e
  TellorRWAOracleAdapter: 0xaa1dA24537F12c9B64006f1A196600478AF92587

## Setting up 1 EVM.

==========================

Chain 421614

Estimated gas price: 0.040048001 gwei

Estimated total gas used for script: 3715565

Estimated amount required: 0.000148800950835565 ETH

==========================

##### arbitrum-sepolia
✅  [Success] Hash: 0xb22c5aaaaf42e055856a185955f665db4f9f0aceb0b5203a6402a81f7db20472
Contract: Schrodinger1155RWAHook
Contract Address: 0x66accaC6c88dcC3474013515eC3EE5Ecd3593D90
Block: 269608027
Paid: 0.000035751200198 ETH (1675471 gas * 0.021338 gwei)


##### arbitrum-sepolia
✅  [Success] Hash: 0x323d3a2de5e15b9d63cf3656047faa2e4f5d0193d179364e3ccfc4c182338101
Contract: ReactiveRWAController
Contract Address: 0xd1E172c7617fB6e119E8dAc9a5c2c8A1AA5B416e
Block: 269608035
Paid: 0.000014133858904 ETH (705212 gas * 0.020042 gwei)


##### arbitrum-sepolia
✅  [Success] Hash: 0x37e2e24aa345d41fcf6fbf7bc5696b54c5eefc3501b99a0d4bd6371c84d289f4
Contract: TellorRWAOracleAdapter
Contract Address: 0xaa1dA24537F12c9B64006f1A196600478AF92587
Block: 269608043
Paid: 0.00000859864 ETH (429932 gas * 0.02 gwei)


##### arbitrum-sepolia
✅  [Success] Hash: 0x029c515678f94c0f0998987b9e060960c7cb7ce2d7434ca45a5956157453924a
Contract: ReactiveRWAController
Function: setHook(address)
Block: 269608052
Paid: 0.000000949024232 ETH (47281 gas * 0.020072 gwei)

✅ Sequence #1 on arbitrum-sepolia | Total Paid: 0.000059432723334 ETH (2857896 gas * avg 0.020363 gwei)
