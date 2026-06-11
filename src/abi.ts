export const coffheeHookAbi = [
  {
    type: "function",
    name: "getEncryptedPositionHandles",
    stateMutability: "view",
    inputs: [
      { name: "planId", type: "bytes32" },
      { name: "asset", type: "uint8" }
    ],
    outputs: [
      { name: "exposure", type: "uint256" },
      { name: "target", type: "uint256" },
      { name: "lastRebalanceDelta", type: "uint256" }
    ]
  }
] as const;