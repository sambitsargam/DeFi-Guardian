import React from 'react';
import { TrendingUp, DollarSign } from 'lucide-react';
import { lendingOpportunities } from '../data/mockData';

const LendingMarkets: React.FC = () => {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {lendingOpportunities.map((opportunity) => (
        <div
          key={`${opportunity.protocol}-${opportunity.asset}`}
          className="relative overflow-hidden rounded-xl shadow-lg group"
        >
          <div className={`absolute inset-0 bg-gradient-to-r ${opportunity.color} opacity-90`} />
          <div className="relative p-6">
            <div className="flex justify-between items-start">
              <div>
                <h3 className="text-xl font-bold text-white mb-1">
                  {opportunity.asset}
                </h3>
                <p className="text-white/80 text-sm">
                  on {opportunity.protocol}
                </p>
              </div>
              <div className="flex items-center space-x-1 bg-white/20 rounded-full px-3 py-1">
                <TrendingUp className="w-4 h-4 text-white" />
                <span className="text-white font-medium">{opportunity.apy.toFixed(1)}% APY</span>
              </div>
            </div>

            <div className="mt-6 space-y-4">
              <div>
                <div className="flex justify-between text-sm text-white/80 mb-1">
                  <span>Utilization</span>
                  <span>{opportunity.utilization}%</span>
                </div>
                <div className="w-full bg-white/20 rounded-full h-2">
                  <div
                    className="bg-white rounded-full h-2"
                    style={{ width: `${opportunity.utilization}%` }}
                  />
                </div>
              </div>

              <div className="flex items-center space-x-2 text-white">
                <DollarSign className="w-5 h-5" />
                <span className="font-medium">
                  ${(opportunity.tvl / 1000000).toFixed(2)}M TVL
                </span>
              </div>
            </div>

            <button className="mt-6 w-full bg-white/20 hover:bg-white/30 text-white font-medium py-2 px-4 rounded-lg transition-colors">
              Lend {opportunity.asset}
            </button>
          </div>
        </div>
      ))}
    </div>
  );
};

export default LendingMarkets;