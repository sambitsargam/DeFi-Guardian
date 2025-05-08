// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IYieldProtocol {
    function deposit(address token, uint256 amount) external;
    function withdraw(address token, uint256 amount) external;
    function getYield(address token) external view returns (uint256);
}

interface IPriceOracle {
    function getLatestPrice(address token) external view returns (uint256);
}

contract DeFiGuardian is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    IPriceOracle public immutable oracle;

    struct Asset {
        uint256 balance;
        uint256 lastPrice;
        uint256 lastUpdate;
        address protocol;
    }

    mapping(address => Asset) public assets;
    address[] public tokens;

    uint256 public volatilityThreshold = 10; // 10%
    uint256 public minRebalanceDelta = 5;    // 5%
    uint256 public staleThreshold = 1 days;

    event TokenAdded(address indexed token, address indexed protocol);
    event Deposited(address indexed token, uint256 amount);
    event Withdrawn(address indexed token, uint256 amount);
    event RiskMitigated(address indexed token, uint256 withdrawn);
    event YieldRebalanced(address indexed fromToken, address indexed toToken, uint256 amount);
    event ThresholdsUpdated(uint256 volatility, uint256 minDelta, uint256 staleSeconds);
    event Paused();
    event Unpaused();

    modifier validToken(address token) {
        require(assets[token].protocol != address(0), "Unsupported token");
        _;
    }

    constructor(address _oracle) {
        require(_oracle != address(0), "Invalid oracle");
        oracle = IPriceOracle(_oracle);
    }

    function addSupportedToken(address token, address protocol) external onlyOwner {
        require(token != address(0) && protocol != address(0), "Invalid addresses");
        require(assets[token].protocol == address(0), "Already supported");

        assets[token].protocol = protocol;
        tokens.push(token);

        emit TokenAdded(token, protocol);
    }

    function deposit(address token, uint256 amount) external onlyOwner nonReentrant whenNotPaused validToken(token) {
        require(amount > 0, "Zero amount");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _safeApprove(token, assets[token].protocol, amount);

        IYieldProtocol(assets[token].protocol).deposit(token, amount);

        assets[token].balance += amount;
        uint256 price = _safeGetPrice(token);
        assets[token].lastPrice = price;
        assets[token].lastUpdate = block.timestamp;

        emit Deposited(token, amount);
    }

    function withdraw(address token, uint256 amount) external onlyOwner nonReentrant whenNotPaused validToken(token) {
        Asset storage a = assets[token];
        require(amount > 0 && a.balance >= amount, "Invalid amount");

        IYieldProtocol(a.protocol).withdraw(token, amount);
        IERC20(token).safeTransfer(owner(), amount);

        a.balance -= amount;

        emit Withdrawn(token, amount);
    }

    function monitorAllRisks() external onlyOwner whenNotPaused {
        uint256 len = tokens.length;
        for (uint256 i = 0; i < len; ) {
            _monitorRisk(tokens[i]);
            unchecked { i++; }
        }
    }

    function monitorRisk(address token) external onlyOwner whenNotPaused {
        _monitorRisk(token);
    }

    function _monitorRisk(address token) internal validToken(token) {
        Asset storage a = assets[token];
        if (a.balance == 0) return;

        uint256 current = _safeGetPrice(token);
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
        IERC20(token).safeTransfer(owner(), amt);

        a.balance = 0;

        emit RiskMitigated(token, amt);
    }

    function optimizeAllYields() external onlyOwner whenNotPaused {
        uint256 len = tokens.length;
        if (len < 2) return;

        address bestToken = tokens[0];
        uint256 bestYield = IYieldProtocol(assets[bestToken].protocol).getYield(bestToken);

        for (uint i = 1; i < len; ) {
            address t = tokens[i];
            uint256 y = IYieldProtocol(assets[t].protocol).getYield(t);
            if (y > bestYield) {
                bestYield = y;
                bestToken = t;
            }
            unchecked { i++; }
        }

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

    function _rebalance(address from, address to) internal nonReentrant validToken(from) validToken(to) {
        Asset storage aFrom = assets[from];
        Asset storage aTo = assets[to];
        uint256 amt = aFrom.balance;
        if (amt == 0) return;

        IYieldProtocol(aFrom.protocol).withdraw(from, amt);
        _safeApprove(from, aTo.protocol, amt);
        IYieldProtocol(aTo.protocol).deposit(to, amt);

        aFrom.balance = 0;
        aFrom.lastUpdate = block.timestamp;
        aTo.balance += amt;

        emit YieldRebalanced(from, to, amt);
    }

    function _percentDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) return type(uint256).max;
        uint256 diff = a > b ? a - b : b - a;
        return diff * 100 / (a > b ? a : b);
    }

    function _safeApprove(address token, address spender, uint256 amount) internal {
        IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    function _safeGetPrice(address token) internal view returns (uint256 price) {
        price = oracle.getLatestPrice(token);
        require(price > 0, "Invalid oracle price");
    }

    function setThresholds(uint256 _volatility, uint256 _minDelta, uint256 _staleSeconds) external onlyOwner {
        require(_volatility < 100 && _minDelta < 100, "Unrealistic threshold");
        volatilityThreshold = _volatility;
        minRebalanceDelta = _minDelta;
        staleThreshold = _staleSeconds;
        emit ThresholdsUpdated(_volatility, _minDelta, _staleSeconds);
    }

    function getAllTokens() external view returns (address[] memory) {
        return tokens;
    }

    function getAssetStatus(address token) external view returns (uint256, uint256, uint256, address) {
        Asset storage a = assets[token];
        return (a.balance, a.lastPrice, a.lastUpdate, a.protocol);
    }

    function emergencyWithdraw(address token) external onlyOwner nonReentrant whenPaused validToken(token) {
        Asset storage a = assets[token];
        uint256 amt = a.balance;
        require(amt > 0, "No funds");

        IYieldProtocol(a.protocol).withdraw(token, amt);
        IERC20(token).safeTransfer(owner(), amt);

        a.balance = 0;
    }

    function pause() external onlyOwner {
        _pause();
        emit Paused();
    }

    function unpause() external onlyOwner {
        _unpause();
        emit Unpaused();
    }
}
