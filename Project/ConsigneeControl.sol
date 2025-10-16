// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface Control {
    function grantPermission(address user) external;
    function revokePermission(address user) external;
    function getNowTransferStationNum() external view returns(uint8);
    function getNowTransferStationCode() external view returns(bytes2);
    function getTransferStationTimestampByIndex(uint8) external view returns(uint);
    function getTransferStationTimestampByCode(bytes2) external view returns(uint);
    function fromIndexGetCode(uint8) external view returns(bytes2);
    function fromCodeGetIndex(bytes2) external view returns(uint8);
    function signForCargo() external;
}
    /// @title 收货用户通过该合约来进行交互
    /// @author q1ngying 
contract ConsigneeControl {
    Control immutable control;

    /**
     * @param _control 合约地址
     */
    constructor(address _control) {
        control = Control(_control);
    }

    
    /**
     * @dev 授权其他用户时触发该事件
     * @param grantPermissionAccount 授权用户的账户地址
     */
    event GrantPermission(address indexed grantPermissionAccount);

    /**
     * @dev 取消对其他用户授权时触发该事件
     * @param revokePermissionAccount 取消授权用户的账户地址
     */
    event RevokePermission(address indexed revokePermissionAccount);

    /**
     * @notice 为其他用户授权，使其可查看物流状态
     * @param user 授权的用户地址
     */
    function grantPermission(address user) external {
        control.grantPermission(user);
        emit GrantPermission(user);
    }

    /**
     * @notice 取消对其他用户的授权
     * @param user 取消授权的用户地址
     */
    function revokePrimission(address user) external {
        control.revokePermission(user);
        emit RevokePermission(user);
    }

    /**
     * @notice 获取现在的中转站序号
     */
    function getNowTransferStationNum() external view returns(uint8) {
        return control.getNowTransferStationNum();
    }

    /**
     * @notice 获取现在的中转站代号
     */
    function getNowTransferStationCode() external view returns(bytes2) {
        return control.getNowTransferStationCode();
    }

    /**
     * @notice 获取到达对应序号的中转站时间戳
     * @param _number 中转站序号
     */
    function getTransferStationTimestampByIndex(uint8 _number) external view returns(uint) {
        return control.getTransferStationTimestampByIndex(_number);
    }

    /**
     * @notice 获取到达对应代号的中转站时间戳
     * @param _code 中转站代号
     */
    function getTransferStationTimestampByCode(bytes2 _code) external view returns(uint) {
        return control.getTransferStationTimestampByCode(_code);
    }


    /**
     * @notice 从中转站序号获取中转站代号
     * @param _index 中转站代号
     */
    function fromIndexGetCode(uint8 _index) external view returns(bytes2) {
        return control.fromIndexGetCode(_index);
    }

    /**
     * @notice 从中转站代号获取中转站序号
     * @param transferStationCode 中转站代号
     */
    function fromCodeGetIndex(bytes2 transferStationCode) external view returns (uint8) {
        return  control.fromCodeGetIndex(transferStationCode);
    }

    /**
     * @notice 签收函数
     */
    function signForCargo() external {
        control.signForCargo();
    }
}