import React from 'react';
import { Shield } from 'lucide-react';
import RiskDashboard from './components/RiskDashboard';
import YieldOptimizer from './components/YieldOptimizer';
import PortfolioAllocation from './components/PortfolioAllocation';
import LendingMarkets from './components/LendingMarkets';

function App() {
  return (
    <div className="min-h-screen bg-gray-100">
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <Shield className="w-8 h-8 text-blue-600" />
              <span className="ml-2 text-xl font-bold text-gray-900">DeFi Guardian</span>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="space-y-8">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 mb-4">Risk Assessment</h2>
            <RiskDashboard />
          </div>

          <div>
            <h2 className="text-2xl font-bold text-gray-900 mb-4">Lending Markets</h2>
            <LendingMarkets />
          </div>

          <div>
            <h2 className="text-2xl font-bold text-gray-900 mb-4">Portfolio Overview</h2>
            <PortfolioAllocation />
          </div>

          <div>
            <h2 className="text-2xl font-bold text-gray-900 mb-4">Yield Optimization</h2>
            <YieldOptimizer />
          </div>
        </div>
      </main>
    </div>
  );
}

export default App;