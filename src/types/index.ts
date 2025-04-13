export interface RiskMetric {
  name: string;
  value: number;
  threshold: number;
  status: 'low' | 'medium' | 'high';
}

export interface YieldOpportunity {
  protocol: string;
  apy: number;
  tvl: number;
  risk: number;
  recommended: boolean;
}

export interface PortfolioAsset {
  name: string;
  allocation: number;
  value: number;
  risk: number;
}

export interface MarketData {
  timestamp: number;
  price: number;
  volume: number;
}

export interface LendingOpportunity {
  protocol: string;
  asset: string;
  apy: number;
  tvl: number;
  utilization: number;
  color: string;
}