// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IYieldProtocol {
    function deposit(address token, uint256 amount) external;
    function withdraw(address token, uint256 amount) external;
    function getYield(address token) external view returns (uint256);
}

interface IPriceOracle {
    function getLatestPrice(address token) external view returns (uint256);
}

contract DeFiGuardian is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IPriceOracle public immutable oracle;

    struct Asset {
        uint256 balance;
        uint256 lastPrice;
        uint256 lastUpdate;
        address protocol;
    }

    // token => asset data
    mapping(address => Asset) public assets;
    // supported tokens list
    address[] public tokens;

    // thresholds
    uint256 public volatilityThreshold = 10;      // 10%
    uint256 public minRebalanceDelta = 5;         // 5%
    uint256 public staleThreshold = 1 days;

    // events
    event TokenAdded(address indexed token, address indexed protocol);
    event Deposited(address indexed token, uint256 amount);
    event Withdrawn(address indexed token, uint256 amount);
    event RiskMitigated(address indexed token, uint256 withdrawn);
    event YieldRebalanced(address indexed fromToken, address indexed toToken, uint256 amount);
    event ThresholdsUpdated(uint256 volatility, uint256 minDelta, uint256 staleSeconds);

    constructor(address _oracle) {
        require(_oracle != address(0), "Invalid oracle");
        oracle = IPriceOracle(_oracle);
    }

    /// @notice Adds a supported token with its yield protocol
    function addSupportedToken(address token, address protocol) external onlyOwner {
        require(token != address(0) && protocol != address(0), "Invalid addresses");
        require(assets[token].protocol == address(0), "Already supported");

        assets[token].protocol = protocol;
        tokens.push(token);

        emit TokenAdded(token, protocol);
    }

    /// @notice Deposit tokens into yield protocol
    function deposit(address token, uint256 amount) external onlyOwner nonReentrant {
        Asset storage a = assets[token];
        require(a.protocol != address(0), "Unsupported token");
        require(amount > 0, "Zero amount");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).safeApprove(a.protocol, 0);
        IERC20(token).safeApprove(a.protocol, amount);

        IYieldProtocol(a.protocol).deposit(token, amount);

        a.balance += amount;
        a.lastPrice = oracle.getLatestPrice(token);
        a.lastUpdate = block.timestamp;

        emit Deposited(token, amount);
    }

    /// @notice Withdraw tokens back to owner
    function withdraw(address token, uint256 amount) external onlyOwner nonReentrant {
        Asset storage a = assets[token];
        require(a.protocol != address(0), "Unsupported token");
        require(amount > 0 && a.balance >= amount, "Invalid amount");

        IYieldProtocol(a.protocol).withdraw(token, amount);
        IERC20(token).safeTransfer(owner(), amount);

        a.balance -= amount;

        emit Withdrawn(token, amount);
    }

    /// @notice Perform risk checks on all tokens
    function monitorAllRisks() external onlyOwner {
        uint256 len = tokens.length;
        for (uint256 i = 0; i < len; ) {
            _monitorRisk(tokens[i]);
            unchecked { i++; }
        }
    }

    /// @notice Check and mitigate risk for a single token
    function monitorRisk(address token) external onlyOwner {
        _monitorRisk(token);
    }

    function _monitorRisk(address token) internal {
        Asset storage a = assets[token];
        if (a.protocol == address(0) || a.balance == 0) return;

        uint256 current = oracle.getLatestPrice(token);
        uint256 diff = _percentDiff(a.lastPrice, current);
        if (diff > volatilityThreshold || block.timestamp - a.lastUpdate > staleThreshold) {
            _mitigate(token);
        }
    }

    function _mitigate(address token) internal {
        Asset storage a = assets[token];
        uint256 amt = a.balance;
        if (amt == 0) return;

        IYieldProtocol(a.protocol).withdraw(token, amt);
        emit RiskMitigated(token, amt);

        a.balance = 0;
    }

    /// @notice Rebalance yields: move funds from lower to highest-yield asset
    function optimizeAllYields() external onlyOwner {
        uint256 len = tokens.length;
        if (len < 2) return;

        // find highest yield token
        address bestToken = tokens[0];
        uint256 bestYield = IYieldProtocol(assets[bestToken].protocol).getYield(bestToken);
        for (uint i = 1; i < len; ) {
            uint256 y = IYieldProtocol(assets[tokens[i]].protocol).getYield(tokens[i]);
            if (y > bestYield) {
                bestYield = y;
                bestToken = tokens[i];
            }
            unchecked { i++; }
        }

        // rebalance others to bestToken if delta > threshold
        for (uint j = 0; j < len; ) {
            address t = tokens[j];
            if (t != bestToken) {
                uint256 y = IYieldProtocol(assets[t].protocol).getYield(t);
                if (bestYield > y + minRebalanceDelta) {
                    _rebalance(t, bestToken);
                }
            }
            unchecked { j++; }
        }
    }

    function _rebalance(address from, address to) internal nonReentrant {
        Asset storage aFrom = assets[from];
        Asset storage aTo = assets[to];
        uint256 amt = aFrom.balance;
        if (amt == 0) return;

        IYieldProtocol(aFrom.protocol).withdraw(from, amt);
        IERC20(from).safeApprove(aTo.protocol, 0);
        IERC20(from).safeApprove(aTo.protocol, amt);
        IYieldProtocol(aTo.protocol).deposit(to, amt);

        aFrom.balance = 0;
        aFrom.lastUpdate = block.timestamp;
        aTo.balance += amt;

        emit YieldRebalanced(from, to, amt);
    }

    /// @dev percent difference between a and b
    function _percentDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) return type(uint256).max;
        uint256 diff = a > b ? a - b : b - a;
        return diff * 100 / (a > b ? a : b);
    }

    /// @notice Update operational thresholds
    function setThresholds(
        uint256 _volatility,
        uint256 _minDelta,
        uint256 _staleSeconds
    ) external onlyOwner {
        volatilityThreshold = _volatility;
        minRebalanceDelta = _minDelta;
        staleThreshold = _staleSeconds;
        emit ThresholdsUpdated(_volatility, _minDelta, _staleSeconds);
    }

    /// @notice List all supported tokens
    function getAllTokens() external view returns (address[] memory) {
        return tokens;
    }

    /// @notice Fetch asset details
    function getAssetStatus(address token)
        external view
        returns (
            uint256 balance,
            uint256 lastPrice,
            uint256 lastUpdate,
            address protocol
        )
    {
        Asset storage a = assets[token];
        return (a.balance, a.lastPrice, a.lastUpdate, a.protocol);
    }

    /// @notice Emergency withdraw all funds for a token
    function emergencyWithdraw(address token) external onlyOwner nonReentrant {
        Asset storage a = assets[token];
        uint256 amt = a.balance;
        require(amt > 0, "No funds");

        IYieldProtocol(a.protocol).withdraw(token, amt);
        IERC20(token).safeTransfer(owner(), amt);

        a.balance = 0;
    }
}
