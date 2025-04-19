// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IYieldProtocol {
    function deposit(address token, uint256 amount) external;
    function withdraw(address token, uint256 amount) external;
    function getYield(address token) external view returns (uint256);
    function getTotalDeposits(address token) external view returns (uint256);
}

interface IPriceOracle {
    function getLatestPrice(address token) external view returns (uint256);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract DeFiGuardian {
    address public owner;
    IPriceOracle public oracle;

    struct Asset {
        uint256 amount;
        uint256 lastPrice;
        address protocol;
        uint256 lastUpdate;
    }

    mapping(address => Asset) public assets;
    mapping(address => bool) public supportedTokens;
    address[] public tokenList;

    uint256 public volatilityThreshold = 10; // 10% price movement
    uint256 public minRebalanceYield = 5; // 5% increase required to trigger rebalance
    uint256 public staleThreshold = 1 days; // Time after which asset data is stale

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    event RiskMitigated(address token, uint256 withdrawnAmount);
    event YieldRebalanced(address fromToken, address toToken, uint256 amount);
    event TokenSupported(address token, address protocol);
    event Deposited(address token, uint256 amount);
    event Withdrawn(address token, uint256 amount);

    constructor(address _oracle) {
        owner = msg.sender;
        oracle = IPriceOracle(_oracle);
    }

    function addSupportedToken(address token, address protocol) external onlyOwner {
        require(!supportedTokens[token], "Already supported");
        supportedTokens[token] = true;
        assets[token].protocol = protocol;
        tokenList.push(token);
        emit TokenSupported(token, protocol);
    }

    function deposit(address token, uint256 amount) external onlyOwner {
        require(supportedTokens[token], "Unsupported token");
        Asset storage asset = assets[token];

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(asset.protocol, amount);

        IYieldProtocol(asset.protocol).deposit(token, amount);

        asset.amount += amount;
        asset.lastPrice = oracle.getLatestPrice(token);
        asset.lastUpdate = block.timestamp;

        emit Deposited(token, amount);
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        require(supportedTokens[token], "Unsupported token");
        Asset storage asset = assets[token];
        require(asset.amount >= amount, "Insufficient balance");

        IYieldProtocol(asset.protocol).withdraw(token, amount);
        IERC20(token).transfer(msg.sender, amount);

        asset.amount -= amount;

        emit Withdrawn(token, amount);
    }

    function monitorAllRisks() external onlyOwner {
        for (uint i = 0; i < tokenList.length; i++) {
            address token = tokenList[i];
            if (supportedTokens[token]) {
                monitorRisk(token);
            }
        }
    }

    function monitorRisk(address token) public onlyOwner {
        require(supportedTokens[token], "Unsupported token");
        Asset storage asset = assets[token];

        uint256 currentPrice = oracle.getLatestPrice(token);
        uint256 priceChange = _percentDiff(asset.lastPrice, currentPrice);

        if (priceChange > volatilityThreshold || _isStale(asset.lastUpdate)) {
            _mitigateRisk(token);
        }
    }

    function _mitigateRisk(address token) internal {
        Asset storage asset = assets[token];
        if (asset.amount == 0) return;

        IYieldProtocol(asset.protocol).withdraw(token, asset.amount);
        emit RiskMitigated(token, asset.amount);

        asset.amount = 0;
    }

    function optimizeAllYields() external onlyOwner {
        for (uint i = 0; i < tokenList.length; i++) {
            for (uint j = 0; j < tokenList.length; j++) {
                if (i != j) {
                    optimizeYield(tokenList[i], tokenList[j]);
                }
            }
        }
    }

    function optimizeYield(address fromToken, address toToken) public onlyOwner {
        require(supportedTokens[fromToken] && supportedTokens[toToken], "Unsupported tokens");

        uint256 fromYield = IYieldProtocol(assets[fromToken].protocol).getYield(fromToken);
        uint256 toYield = IYieldProtocol(assets[toToken].protocol).getYield(toToken);

        if (toYield > fromYield + minRebalanceYield) {
            _internalRebalanceYield(fromToken, toToken);
        }
    }

    function _internalRebalanceYield(address fromToken, address toToken) internal {
        Asset storage fromAsset = assets[fromToken];
        Asset storage toAsset = assets[toToken];

        uint256 amount = fromAsset.amount;
        if (amount == 0) return;

        IYieldProtocol(fromAsset.protocol).withdraw(fromToken, amount);
        IERC20(fromToken).approve(toAsset.protocol, amount);
        IYieldProtocol(toAsset.protocol).deposit(toToken, amount);

        emit YieldRebalanced(fromToken, toToken, amount);

        toAsset.amount += amount;
        fromAsset.amount = 0;
        fromAsset.lastUpdate = block.timestamp;
    }

    function _percentDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) return 100;
        if (a > b) {
            return ((a - b) * 100) / a;
        } else {
            return ((b - a) * 100) / b;
        }
    }

    function _isStale(uint256 lastUpdate) internal view returns (bool) {
        return (block.timestamp - lastUpdate) > staleThreshold;
    }

    function setThresholds(uint256 _volatility, uint256 _minRebalanceYield, uint256 _staleThreshold) external onlyOwner {
        volatilityThreshold = _volatility;
        minRebalanceYield = _minRebalanceYield;
        staleThreshold = _staleThreshold;
    }

    function getAllTokens() external view returns (address[] memory) {
        return tokenList;
    }

    function getAssetStatus(address token) external view returns (uint256 amount, uint256 lastPrice, uint256 lastUpdate, address protocol) {
        Asset storage asset = assets[token];
        return (asset.amount, asset.lastPrice, asset.lastUpdate, asset.protocol);
    }

    function emergencyWithdraw(address token) external onlyOwner {
        require(supportedTokens[token], "Unsupported token");
        Asset storage asset = assets[token];

        IYieldProtocol(asset.protocol).withdraw(token, asset.amount);
        IERC20(token).transfer(owner, asset.amount);

        asset.amount = 0;
    }
}
