// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '../RBAC/RBAC.sol';


/// @title 物流信息合约
/// @author q1ngying
contract Control{
    RBAC RBACContract =  new RBAC(address(this));
    /**
     * @dev 各参数含义：
     * transferStationNumber 当前货物所在中转站序号
     * shipper 发货人账户地址
     * origin 发货地址代号
     * consignee 收货人账户地址
     * destination 收货地地址代号
     * logisticsType 货物类型
     * insurance 是否购买物流保险
     * version 订单版本
     * arrive 是否到达最终站
     * processor 当前中转站/在路途中时下一站的操作员
     * cargoInfo 货物信息的哈希值
     */
    uint8 private transferStationNumber; // bytes1 slot0
    address immutable shipper; //bytes20 slot0
    bytes2 immutable origin; // bytes2 slot0
    address immutable consignee; //bytes20 slot1
    bytes2 immutable destination; //byte2 slot1
    uint8 immutable logisticsType; //bytes1 slot1
    bool immutable insurance; //bytes1 slot1
    uint16 immutable version; //bytes2 slot1
    bool arrive;
    address processor; //bytes20 slot2
    uint256 immutable cargoInfo; //bytes32 slot3

    
    
    /**
     * @dev 各参数的含义：
     * transferStationNumberNow-目前的中转站序号，0 为始发站
     * transferStationCode：目前中转站代号
     * processor 该中转站的操作者
     * processingTimestamp 到站时间
     */
    struct TransferStation {
        uint8 transferStationNumberNow;
        bytes2 transferStationCode;
        address processor;
        uint256 processingTimestamp;
    }
    mapping (uint8 => TransferStation) transferStations; // 映射，来存放中转站，0 为发货地。
    mapping (address => bool) permissions; // 映射，存放授权可查看物流状态的 address，安全 bool 未被赋值时默认为 false
    
    /**
     * @param _shipper address 发货人账户地址
     * @param _origin bytes32 发货地代号
     * @param _consignee address 收货人地址
     * @param _destination bytes32 收货地址代号
     * @param _logisticsType uint8 货物类型
     * @param _insurance bool 是否购买物流保险
     * @param _version uint16 订单版本
     * @param _nextProcessor address 下一站的操作者
     * @param _cargoInfo uint256 货物信息的 keccak256 值
     */
    constructor(
        address _shipper,
        bytes2 _origin, 
        address _consignee, 
        bytes2  _destination, 
        uint8 _logisticsType, 
        bool _insurance, 
        uint16 _version, 
        address _nextProcessor,
        uint256 _cargoInfo
        ) {
            transferStationNumber = 0;
            shipper = _shipper;

            // grantRole(SHIPPER_ROLE, _shipper);
            // RBACContract.grantRole(RBACContract.SHIPPER_ROLE, _shipper);
            RBACContract.grantShipper(_shipper);

            origin = _origin;
            consignee = _consignee;

            // grantRole(CONSIGNEE_ROLE, _consignee);
            // RBACContract.grantRole(RBACContract.CONSIGNEE_ROLE, _consignee);
            RBACContract.grantConsignee(_consignee);

            destination = _destination;
            logisticsType = _logisticsType;
            insurance = _insurance;
            version = _version;
            processor = _nextProcessor;

            // grantRole(TRANSFER_ROLE, _nextProcessor);
            // RBACContract.grantRole(RBACContract.TRANSFER_ROLE, _nextProcessor);
            RBACContract.grantTransfer(_nextProcessor);

            cargoInfo = _cargoInfo;
            // permissions[_consignee] = true;

            // grantRole(GRANTEE_ROLE, _consignee);
            // RBACContract.grantRole(RBACContract.GRANTEE_ROLE, _consignee);
            RBACContract.grantGrantee(_consignee);

            arrive = false;
            TransferStation memory transferStation =TransferStation(
                transferStationNumber,
                _origin, 
                tx.origin, 
                block.timestamp
            );
            transferStations[transferStationNumber] = transferStation;
            emit StratTransfer(
                shipper,
                origin,
                consignee,
                destination,
                block.timestamp,
                logisticsType,
                insurance,
                version,
                processor,
                cargoInfo
            );
        }




    /// @dev 判断调用者是否有权将信息上链
    modifier isProcessor() { 
        require(RBACContract.hasTransfer(tx.origin), 'Control: You are not the current processor');
        // require(tx.origin == processor, 'Control: You are not the current processor');
        _;
    }
    
    /// @dev 判断调用者是否为收货人
    modifier isOwner() { 
        require(RBACContract.hasConsignee(tx.origin), 'Control: You are not the consignee!');
        // require(tx.origin == consignee, 'Control: You are not the consignee!');
        _;
    }

    /// @dev 判断调用者是否被授权
    modifier havePermissions() {
        require(RBACContract.hasGrantee(tx.origin), 'Control: You don not have permissions!');
        // require(permissions[tx.origin], 'Control: You don not have permissions!');
        _;
    }

    /// @dev 判断货物是否到达
    modifier isArrive() {
        require(arrive, 'Control: The cargo is not arrive destination');
        _;
    }



    /**
     * @dev 该internal函数用于实现 转移操作者功能
     * @param _nextProcessor 要转移给的目标地址
     */
    function _changeProcessor(address _nextProcessor) internal isProcessor { // 待完善，该函数是一个内部函数，作用：转移操作人权限
        processor = _nextProcessor;
    }

    /**
     * @dev 该internal函数用于实现到达新的中转站操作
     * @param _transferStationCode 到达的中转站地址代号
     * @param _nextProcessor 下一个中转站的操作员地址
     */
    function _arriveTransferStation(
        bytes2 _transferStationCode,
        address _nextProcessor
    ) internal {
        TransferStation memory transferStation =TransferStation(
            transferStationNumber,
            _transferStationCode, 
            tx.origin, 
            block.timestamp
        );
        transferStations[transferStationNumber] = transferStation;
        _changeProcessor(_nextProcessor);
    }

    /**
     * @dev 通过中转站代号获取中转站的序号
     * @dev 如果找不到匹配的 transferStationCode，则返回 255 表示未找到。
     * @param transferStationCode 中转站代号
     */
    function _fromCodeGetIndex(bytes2 transferStationCode) internal view returns (uint8) {
        uint8 num = 255;
        for (uint8 i = 0; i <= transferStationNumber; i++) {
            if (transferStations[i].transferStationCode == transferStationCode) {
                num = i;
            }
        }
        require(num!=255,'Control: Invalid transit station number.');
        return num;
    }



    /**
     * @param shipper 发货人账户地址
     * @param origin 发货地址代号
     * @param consignee 收货人账户地址
     * @param destination 收货地地址代号
     * @param logisticsType 货物类型
     * @param insurance 是否购买物流保险
     * @param version 订单版本
     * @param processor 当前中转站/在路途中时下一站的操作员
     * @param cargoInfo 货物信息的哈希值
     */
    event StratTransfer(
    address indexed shipper, 
    bytes2 origin, 
    address indexed consignee, 
    bytes2 destination, 
    uint indexed startTimestamp,
    uint8 logisticsType,
    bool insurance, 
    uint16 version, 
    address processor,
    uint256 cargoInfo
    );

    /**
     * @dev 到达新的中转站时触发该事件
     * @param transferStationNumber 当前中转站序号
     * @param transferStationCode 当前中转站的代号
     * @param arriveTimestamp 到达时间
     * @param processor 该中转站的操作员
     * @param nextTransferStationCode 下一个中转站的代号
     * @param nextProcessor 下一站中转站的操作员
     */
    event ArriveNewTransaferStation(
        uint8 indexed transferStationNumber,
        bytes2 indexed transferStationCode, 
        uint256 indexed arriveTimestamp,
        address processor, 
        bytes2 nextTransferStationCode,
        address nextProcessor
        ); // 待完善

    /**
     * @dev 到达收获地时触发该合约
     * @param arriveTimestamp 到达时间
     * @param arriveTransferStationNumber 到达最后中转站的序号
     * @param arriveTransferStationCode 到达最后中转站的代号
     * @param processor 最后的操作员
     */
    event ArriveDestination(
        uint8 indexed arriveTransferStationNumber,
        bytes2 indexed arriveTransferStationCode,
        uint indexed arriveTimestamp,
        address processor
    ); 

    /**
     * @dev 签收时触发该事件
     * @param Recipient 签收人
     * @param submissionTime 签收时间
     */
    event SignForCargo(address indexed Recipient, uint indexed submissionTime);

    /**
     * @dev 到达新的中转站函数
     * @param _transferStationCode 到达的中转站代号
     * @param _nextProcessor 下一站的操作员
     * @param _nextTransferStationCode 下一站的中转站代号
     */
    function arriveNewTransaferStation(bytes2 _transferStationCode, address _nextProcessor, bytes2 _nextTransferStationCode) isProcessor external {
        transferStationNumber++;
        _arriveTransferStation(_transferStationCode, _nextProcessor);
        emit ArriveNewTransaferStation(
            transferStationNumber, 
            bytes2(_transferStationCode), 
            block.timestamp, 
            tx.origin, 
            bytes2(_nextTransferStationCode),
            _nextProcessor);
    }
     
    /**
     * @dev 到达收货地点时调用该函数
     * @param _transferStationCode 当前的中转站代码 
     */
    function arriveDestination(bytes2 _transferStationCode) isProcessor external {
        _arriveTransferStation(_transferStationCode, address(0));
        arrive = true;
        emit ArriveDestination(transferStationNumber, transferStations[transferStationNumber].transferStationCode, block.timestamp, tx.origin);
    }

    /**
     * @dev 授权其他用户有查看,签收该包裹
     * @param user 授权用户的合约地址
     */
    function grantPermission(address user) external isOwner {
        // grantRole(GRANTEE_ROLE, user);
        RBACContract.grantGrantee(user);
        // permissions[user] = true;
    }
    
    /**
     * @dev 取消对其他用户的授权
     * @param user 被取消的用户合约地址
     */
    function revokePermission(address user) external isOwner { 
        require(user != consignee,'Control: You can not revoke yourself permission');
        RBACContract.revokeGrantee(user);
        // permissions[user] = false;
    }

    /**
     * @dev 获取现在所在的中转站序号
     */
    function getNowTransferStationNum() external view havePermissions returns(uint8) {
        return transferStationNumber;
    }
    /**
     * @dev 获取货物当前所在的中转站代号
     */
    function getNowTransferStationCode() external view havePermissions returns(bytes2) {
        return transferStations[transferStationNumber].transferStationCode;
    }
    /**
     * @dev 获取到达对应序号中转站的时间
     * @param _number 中转站序号
     */
    function getTransferStationTimestampByIndex(uint8 _number) external view havePermissions returns(uint) {
        return transferStations[_number].processingTimestamp;
    }

    /**
     * @dev 获取到达对应代号的中转站时间戳
     * @param _code 中转站代号
     */
    function getTransferStationTimestampByCode(bytes2 _code) external view returns(uint) {
        return transferStations[_fromCodeGetIndex(_code)].processingTimestamp;
    }

    /**
     * @dev 通过中转站序号获取中转站代号
     * @param _index 中转站序号
     */
    function fromIndexGetCode(uint8 _index) external view havePermissions returns(bytes2) {
        return transferStations[_index].transferStationCode;
    }

    /**
     * @dev 通过中转站代号获取中转站的序号
     * @param transferStationCode 中转站代号
     */
    function fromCodeGetIndex(bytes2 transferStationCode) external view returns (uint8) {
        return  _fromCodeGetIndex(transferStationCode);
    }

    /**
     * @dev 用户签收时使用该函数
     */
    function signForCargo() isArrive havePermissions external {
        emit SignForCargo(tx.origin, block.timestamp);
    }
}