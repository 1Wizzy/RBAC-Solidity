// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title RoleBasedToken
 * @dev 一个基于角色的ERC20代币，具有铸币、暂停和黑名单功能
 */
contract RoleBasedToken is ERC20, AccessControl {
    // 定义角色
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BLACKLISTER_ROLE = keccak256("BLACKLISTER_ROLE");
    
    // 合约状态
    bool public paused;
    mapping(address => bool) public blacklisted;
    
    // 事件
    event TokensPaused(address operator);
    event TokensUnpaused(address operator);
    event AddedToBlacklist(address indexed account, address operator);
    event RemovedFromBlacklist(address indexed account, address operator);
    
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // 设置合约部署者为默认管理员
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
        // 初始也授予部署者所有其他角色
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(BLACKLISTER_ROLE, msg.sender);
        
        // 设置角色管理关系：让MINTER_ROLE由DEFAULT_ADMIN_ROLE管理
        // 默认情况下，所有角色都由DEFAULT_ADMIN_ROLE管理，所以这一步可选
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
    }
    
    /**
     * @dev 铸造新代币，只有拥有MINTER_ROLE的地址可以调用
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(!paused, "Token is paused");
        require(!blacklisted[to], "Recipient is blacklisted");
        _mint(to, amount);
    }
    
    /**
     * @dev 暂停所有代币转移，只有拥有PAUSER_ROLE的地址可以调用
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        paused = true;
        emit TokensPaused(msg.sender);
    }
    
    /**
     * @dev 恢复代币转移，只有拥有PAUSER_ROLE的地址可以调用
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        paused = false;
        emit TokensUnpaused(msg.sender);
    }
    
    /**
     * @dev 将地址添加到黑名单，只有拥有BLACKLISTER_ROLE的地址可以调用
     */
    function blacklist(address account) external onlyRole(BLACKLISTER_ROLE) {
        blacklisted[account] = true;
        emit AddedToBlacklist(account, msg.sender);
    }
    
    /**
     * @dev 将地址从黑名单中移除，只有拥有BLACKLISTER_ROLE的地址可以调用
     */
    function unblacklist(address account) external onlyRole(BLACKLISTER_ROLE) {
        blacklisted[account] = false;
        emit RemovedFromBlacklist(account, msg.sender);
    }
    
    /**
     * @dev 重写transfer函数以支持暂停和黑名单功能
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(!paused, "Token transfers are paused");
        require(!blacklisted[msg.sender], "Sender is blacklisted");
        require(!blacklisted[to], "Recipient is blacklisted");
        return super.transfer(to, amount);
    }
    
    /**
     * @dev 重写transferFrom函数以支持暂停和黑名单功能
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(!paused, "Token transfers are paused");
        require(!blacklisted[from], "Sender is blacklisted");
        require(!blacklisted[to], "Recipient is blacklisted");
        return super.transferFrom(from, to, amount);
    }
    
    /**
     * @dev 管理员可以添加新的铸币者
     */
    function addMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, minter);
    }
    
    /**
     * @dev 实现ERC165接口，用于接口识别
     */
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC20) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}