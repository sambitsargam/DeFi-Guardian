import React from 'react';
import { AlertTriangle, TrendingUp, DollarSign, Shield } from 'lucide-react';
import { RiskMetric } from '../types';
import { riskMetrics } from '../data/mockData';

const RiskDashboard: React.FC = () => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'low':
        return 'bg-green-100 text-green-800';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800';
      case 'high':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getIcon = (name: string) => {
    switch (name) {
      case 'Portfolio VaR':
        return <AlertTriangle className="w-6 h-6" />;
      case 'Volatility':
        return <TrendingUp className="w-6 h-6" />;
      case 'Liquidity Risk':
        return <DollarSign className="w-6 h-6" />;
      case 'Smart Contract Risk':
        return <Shield className="w-6 h-6" />;
      default:
        return null;
    }
  };

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      {riskMetrics.map((metric: RiskMetric) => (
        <div key={metric.name} className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="text-gray-500">{getIcon(metric.name)}</div>
            <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(metric.status)}`}>
              {metric.status.toUpperCase()}
            </span>
          </div>
          <h3 className="text-lg font-medium text-gray-900">{metric.name}</h3>
          <div className="mt-2 flex items-baseline">
            <p className="text-2xl font-semibold text-gray-900">
              {(metric.value * 100).toFixed(1)}%
            </p>
            <p className="ml-2 text-sm text-gray-500">
              / {(metric.threshold * 100).toFixed(1)}% threshold
            </p>
          </div>
        </div>
      ))}
    </div>
  );
};

export default RiskDashboard;