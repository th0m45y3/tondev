pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

import "GameObject.sol";
import "Station.sol";
import "Unit.sol";

contract Archer is Unit{
    string weapon = "bow";
    
    constructor(Station Base) public tvmacc{
        base = address(Base);
        Base.addUnit(address(this));
    }

    function changeWeapon(string newW) public onlyOwner{
        weapon = newW;
    }

}