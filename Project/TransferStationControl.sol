// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IControl {
    function arriveNewTransaferStation(bytes2, address, bytes2) external;
    function arriveDestination(bytes2) external;
}

contract TransferStationControl {
    IControl immutable Control;

    constructor(address _Control) {
        Control = IControl(_Control);
    }

     /**
     * @notice 到达新的中转站函数
     * @param _transferStationCode 到达的中转站代号
     * @param _nextProcessor 下一站的操作员
     * @param _nextTransferStationCode 下一站的中转站代号
     */
    function arriveNewTransaferStation(bytes2 _transferStationCode, address _nextProcessor, bytes2 _nextTransferStationCode) external {
        Control.arriveNewTransaferStation(_transferStationCode, _nextProcessor, _nextTransferStationCode);
    }
     
    /**
     * @notice 到达收获地点时调用该函数
     * @param _transferStationCode 当前的中转站代码 
     */
    function arriveDestination(bytes2 _transferStationCode) external {
        Control.arriveDestination(_transferStationCode);
    }
}