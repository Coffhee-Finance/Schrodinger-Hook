import express from "express";
import cors from "cors";
import dotenv from "dotenv";

dotenv.config();

const app = express();

const PORT = process.env.PORT || 3001;

const SCHRODINGER_HOOK =
  process.env.SCHRODINGER_HOOK ||
  "0xC4Dd117e53f9624ED2EE02e6c8CD662645F6e56A";

app.use(cors());
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({
    ok: true,
    service: "Coffhee Schrodinger Hook Demo Backend",
    hook: SCHRODINGER_HOOK
  });
});

app.post("/api/update-risk-inputs", (req, res) => {
  const {
    owner,
    hookAddress,
    pair,
    strategy,
    rebalanceThresholdBps,
    volatilityBps
  } = req.body;

  res.json({
    success: true,
    mode: "demo",
    message: "Dark Pool JIT Strategy updated.",
    hookAddress: hookAddress || SCHRODINGER_HOOK,
    owner,
    pair: pair || "eBTC / eUSD",
    strategy: strategy || "Dark Pool JIT Rebalancing",
    rebalanceThresholdBps,
    volatilityBps,
    txHash: "demo-update-risk-inputs"
  });
});

app.post("/api/deactivate-plan", (req, res) => {
  const { owner, hookAddress, pair, strategy } = req.body;

  res.json({
    success: true,
    mode: "demo",
    message: "Dark Pool JIT Strategy paused.",
    hookAddress: hookAddress || SCHRODINGER_HOOK,
    owner,
    pair: pair || "eBTC / eUSD",
    strategy: strategy || "Dark Pool JIT Rebalancing",
    txHash: "demo-deactivate-plan"
  });
});

app.post("/api/encrypted-entity", (req, res) => {
  const { owner, hookAddress, target, address, pair, strategy } = req.body;

  const targetEntity = target || address;

  if (!targetEntity) {
    return res.status(400).json({
      success: false,
      error: "Target entity required."
    });
  }

  res.json({
    success: true,
    mode: "demo",
    message: "Owner-only decryption successful.",
    hookAddress: hookAddress || SCHRODINGER_HOOK,
    owner,
    target: targetEntity,
    pair: pair || "eBTC / eUSD",
    strategy: strategy || "Dark Pool JIT Rebalancing",
    encryptedHandles: {
      exposure: "0xenc_exposure_4120bps",
      targetAllocation: "0xenc_target_5000bps",
      drift: "0xenc_drift_880bps",
      lastRebalanceDelta: "0xenc_delta_124bps"
    },
    decrypted: {
      exposure: "4,120 BPS",
      targetAllocation: "5,000 BPS",
      drift: "880 BPS",
      lastRebalanceDelta: "124 BPS",
      rebalanceStatus: "JIT rebalance eligible",
      visibility: "Owner / approved viewer only"
    }
  });
});

app.post("/api/grant-position-view-access", (req, res) => {
  const {
    owner,
    viewer,
    hookAddress,
    assetIndex,
    ticker,
    pair,
    strategy
  } = req.body;

  if (!viewer) {
    return res.status(400).json({
      success: false,
      error: "Viewer address required."
    });
  }

  res.json({
    success: true,
    mode: "demo",
    message: `View access granted for ${ticker || "asset"} to ${viewer.slice(0, 6)}...${viewer.slice(-4)}.`,
    hookAddress: hookAddress || SCHRODINGER_HOOK,
    owner,
    viewer,
    assetIndex,
    ticker,
    pair: pair || "eBTC / eUSD",
    strategy: strategy || "Dark Pool JIT Rebalancing",
    txHash: "demo-grant-view-access"
  });
});

app.post("/api/mock-rebalance", (req, res) => {
  const {
    owner,
    hookAddress,
    pair,
    strategy,
    rebalanceThresholdBps,
    volatilityBps
  } = req.body;

  res.json({
    success: true,
    mode: "demo",
    message: "Mock Dark Pool JIT rebalance triggered.",
    hookAddress: hookAddress || SCHRODINGER_HOOK,
    owner,
    pair: pair || "eBTC / eUSD",
    strategy: strategy || "Dark Pool JIT Rebalancing",
    rebalanceThresholdBps,
    volatilityBps,
    beforeSwap: true,
    afterSwap: true,
    rebalance: {
      driftBefore: "880 BPS",
      threshold: `${rebalanceThresholdBps || "150"} BPS`,
      volatility: `${volatilityBps || "400"} BPS`,
      action: "Rebalanced eBTC / eUSD exposure",
      driftAfter: "82 BPS",
      marketVisibility: "Strategy state remains encrypted"
    },
    txHash: "demo-mock-rebalance"
  });
});

app.listen(PORT, () => {
  console.log(`Coffhee backend running on http://localhost:${PORT}`);
});
