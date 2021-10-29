pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

import "GameObject.sol";
import "Station.sol" as st;

abstract contract Unit is GameObject{
    address base;
    uint16 attackPower;
    

    function attack(address target) public onlyOwner {
        require(target != base, 400, "A unit can not attack it's base station");
        require(target != address(this), 400, "A unit can not attack itself");
        GameObject(target).recieveAttack(attackPower);
    }

    function giveAttackPower(uint16 newPower) public onlyOwner{
        attackPower = newPower;
    }

    function baseDestroying() external tvmacc{
        require(msg.sender == base, 403, "Unit does not belong to this base station");
        dying(base);
    }

    function dying(address newHolder) override internal tvmacc{
        st.Station(base).deleteUnit(this);
        selfDestruct(newHolder);
    }
}