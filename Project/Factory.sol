// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Control} from './Control.sol';
import {TransferStationControl} from './TransferStationControl.sol';
import {ConsigneeControl} from './ConsigneeControl.sol';

/// @title 工厂合约
/// @author q1ngying wizzyang
/// @notice this project was refactored by wizzyang, implementing the RBAC
/// @notice 每一个发货地只需要部署一个工厂合约，这样后续发货时只需要调用 start 函数即可
/// @notice 每次调用 start 函数时都会触发 Start 事件，事件记录了三个合约的地址和该工厂合约一共部署的 Control 合约数量


contract Factory {
    uint256 controlNumber;
    address immutable owner;
    mapping(uint => address) controls;

    /**
     * @notice 当每发货一次时，即掉用 start 函数时触发该事件
     * @param controlAddress control 合约的地址
     * @param transferStationControlAddress transferStationControl 合约的地址
     * @param consigneeControlAddress consigneeControl 合约地址
     * @param startTimestamp 发货时间戳
     * @param controlNumber 该商户一共发货的数量
     */
    event Start(
    address indexed controlAddress, 
    address indexed transferStationControlAddress, 
    address indexed consigneeControlAddress,
    uint256 startTimestamp,
    uint256 controlNumber);

    /**
     * @notice 仅需要在第一次发货时部署该合约，后续只需调用 start 函数即可
     */
    constructor() {
        controlNumber = 0;
        owner = tx.origin;
    }

    /**
     * @dev 该修饰符判断交易的发送者是否为合约的部署者 
     */
    modifier isOwner {
        require(tx.origin == owner,'Factory: You are not the owner!');
        _;
    }

    /**
     * @notice 调用该函数来生成 Control 合约
     * @param _origin 发货地代号
     * @param _consignee 收货人账户地址
     * @param _destination 收货地地址代号
     * @param _logisticsType 货物类型
     * @param _insurance 是否购买物流保险
     * @param _version 订单版本
     * @param _nextProcessor 下一站的操作员
     * @param _cargoInfo 货物信息的哈希值
     */
    function start(
        bytes2 _origin,
        address _consignee, 
        bytes2  _destination, 
        uint8 _logisticsType, 
        bool _insurance, 
        uint16 _version, 
        address _nextProcessor,
        uint256 _cargoInfo
    ) public isOwner {
        Control control =  new Control(
            tx.origin,
            _origin, 
            _consignee, 
            _destination, 
            _logisticsType, 
            _insurance, 
            _version, 
            _nextProcessor,
            _cargoInfo
            );
        TransferStationControl transferStationControl = new TransferStationControl(address(control));
        ConsigneeControl consigneeControl = new ConsigneeControl(address(control));
        controlNumber++;
        emit Start(address(control), address(transferStationControl), address(consigneeControl), block.timestamp, controlNumber);
    }
}