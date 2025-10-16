// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../RBAC/RBAC.sol";

/// @notice This Project just for present RBAC
/// @author wizzyang
/// @dev Log -> Events  Auth -> Wallet
contract Logistics is RBAC{
    // Variables
    enum Status{
        None,
        Ready,
        Transit,
        ToBeSigned,
        Signed
    }

    Status public status;

    address public immutable admin;
    address public immutable shipper;
    address public immutable consignee;
    address[] public path;
    uint256 public index = 0; // 当前位置
    

    // Modifiers
    modifier inStatus(Status _status){
        require(status == _status, "Wrong Status.");
        _;
    }

    modifier inCargo(address _addr) {
        require(path[index] == _addr, "The cargo not in your hand.");
        _;
    }

    // Events
    event move(uint256 indexed no, address _from, address _to, uint256 _timestamp, Status _status);

    // Functions
    constructor(address _shipper, address _consignee){
        status = Status.None;

        shipper = _shipper;
        consignee = _consignee;
        admin = msg.sender;

        grantRole(SHIPPER_ROLE, _shipper);
        grantRole(CONSIGNEE_ROLE, _consignee);
    }

    // SHIPPER_ROLE     // 发货人
    // TRANSFER_ROLE    // 中转站
    // CONSIGNEE_ROLE   // 收货人
    // GRANTEE_ROLE     // 被授权者

    function setPath(address[] memory transferPath) public onlyRole(DEFAULT_ADMIN_ROLE) inStatus(Status.None){
        path.push(shipper);
        for (uint i = 0; i < transferPath.length; i ++ ) {
            path.push(transferPath[i]);
            grantRole(TRANSFER_ROLE, transferPath[i]);
        }
        path.push(consignee);
        
        status = Status.Ready;
        
    }
    
    function startShip() public onlyRole(SHIPPER_ROLE) inStatus(Status.Ready) {
        status = Status.Transit;
        emit move(index, path[index], path[index + 1], block.timestamp, status);
        index ++;
    }

    function transferShip() public onlyRole(TRANSFER_ROLE) inStatus(Status.Transit) inCargo(msg.sender){
        emit move(index, path[index], path[index + 1], block.timestamp, status);
        index ++;
        if (index == path.length) 
            status = Status.ToBeSigned;
    }

    function signShip() public onlyRole(CONSIGNEE_ROLE) inStatus(Status.ToBeSigned){
        emit move(index, path[index], path[index + 1], block.timestamp, status);
        index ++;
        status = Status.Signed;
    }

    

}