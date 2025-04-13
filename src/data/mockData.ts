import { RiskMetric, YieldOpportunity, PortfolioAsset, MarketData, LendingOpportunity } from '../types';

export const riskMetrics: RiskMetric[] = [
  { name: 'Portfolio VaR', value: 0.15, threshold: 0.2, status: 'medium' },
  { name: 'Volatility', value: 0.25, threshold: 0.3, status: 'medium' },
  { name: 'Liquidity Risk', value: 0.1, threshold: 0.15, status: 'low' },
  { name: 'Smart Contract Risk', value: 0.05, threshold: 0.1, status: 'low' },
];

export const yieldOpportunities: YieldOpportunity[] = [
  { protocol: 'Aave', apy: 4.5, tvl: 1000000, risk: 0.1, recommended: true },
  { protocol: 'Compound', apy: 3.8, tvl: 800000, risk: 0.08, recommended: true },
  { protocol: 'Curve', apy: 6.2, tvl: 500000, risk: 0.15, recommended: false },
  { protocol: 'Yearn', apy: 8.5, tvl: 300000, risk: 0.2, recommended: false },
];

export const portfolioAssets: PortfolioAsset[] = [
  { name: 'ETH', allocation: 40, value: 400000, risk: 0.12 },
  { name: 'USDC', allocation: 30, value: 300000, risk: 0.05 },
  { name: 'WBTC', allocation: 20, value: 200000, risk: 0.15 },
  { name: 'DAI', allocation: 10, value: 100000, risk: 0.04 },
];

export const marketData: MarketData[] = Array.from({ length: 30 }, (_, i) => ({
  timestamp: Date.now() - (29 - i) * 24 * 60 * 60 * 1000,
  price: 1800 + Math.random() * 400,
  volume: 1000000 + Math.random() * 500000,
}));

export const lendingOpportunities: LendingOpportunity[] = [
  { protocol: 'Aave', asset: 'ETH', apy: 3.8, tvl: 2500000, utilization: 65, color: 'from-purple-500 to-pink-500' },
  { protocol: 'Compound', asset: 'USDC', apy: 4.2, tvl: 1800000, utilization: 72, color: 'from-blue-500 to-teal-500' },
  { protocol: 'Maker', asset: 'DAI', apy: 3.5, tvl: 1200000, utilization: 58, color: 'from-yellow-500 to-orange-500' },
  { protocol: 'Benqi', asset: 'AVAX', apy: 5.1, tvl: 800000, utilization: 81, color: 'from-red-500 to-pink-500' },
  { protocol: 'Trader Joe', asset: 'BTC.b', apy: 2.9, tvl: 1500000, utilization: 45, color: 'from-green-500 to-emerald-500' },
  { protocol: 'Geist', asset: 'FTM', apy: 6.2, tvl: 600000, utilization: 88, color: 'from-indigo-500 to-purple-500' },
];