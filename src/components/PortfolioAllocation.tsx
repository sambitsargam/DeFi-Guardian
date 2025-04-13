import React from 'react';
import { portfolioAssets } from '../data/mockData';

const PortfolioAllocation: React.FC = () => {
  const totalValue = portfolioAssets.reduce((sum, asset) => sum + asset.value, 0);

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h3 className="text-lg font-medium text-gray-900 mb-4">Portfolio Allocation</h3>
      <div className="space-y-4">
        {portfolioAssets.map((asset) => (
          <div key={asset.name}>
            <div className="flex justify-between items-center mb-1">
              <span className="text-sm font-medium text-gray-900">{asset.name}</span>
              <span className="text-sm text-gray-500">
                ${asset.value.toLocaleString()} ({asset.allocation}%)
              </span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div
                className="bg-blue-600 h-2 rounded-full"
                style={{ width: `${asset.allocation}%` }}
              />
            </div>
            <div className="mt-1 text-xs text-gray-500">
              Risk Score: {(asset.risk * 100).toFixed(1)}%
            </div>
          </div>
        ))}
      </div>
      <div className="mt-6 pt-6 border-t border-gray-200">
        <div className="flex justify-between items-center">
          <span className="text-sm font-medium text-gray-900">Total Portfolio Value</span>
          <span className="text-lg font-semibold text-gray-900">
            ${totalValue.toLocaleString()}
          </span>
        </div>
      </div>
    </div>
  );
};

export default PortfolioAllocation;