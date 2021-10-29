pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

import "GameObject.sol";
import "Unit.sol";

contract Station is GameObject{
    address[] uArr;
    mapping(address => uint) uMap;

    modifier ownerOrUnit {
        require(tvm.pubkey() != 0, 101);
        require(msg.pubkey() == tvm.pubkey() || uMap.exists(msg.sender) , 102);
        tvm.accept();
        _;
    }

    function addUnit(address newUnit) public ownerOrUnit{
        uMap[newUnit] = uArr.length;
        uArr.push(newUnit);
    }

    function deleteUnit(address corpse) public ownerOrUnit{
        delete uArr[uMap[corpse]];
        delete uMap[corpse];
    }

    function dying(address newHolder) internal override tvmacc{
        for (uint i = 0; i < uArr.length; i++) {
            Unit(uArr[i]).baseDestroying();
            deleteUnit(uArr[i]);
        }
        selfDestruct(newHolder);
    }
}