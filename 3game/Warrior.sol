pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

import "GameObject.sol";
import "Station.sol";
import "Unit.sol";

contract Warrior is Unit{
    string weapon = "sword";
    
    constructor(Station Base) public tvmacc{
        base = address(Base);
        Base.addUnit(address(this));
    }

    function changeWeapon(string newW) public onlyOwner{
        weapon = newW;
    }

}