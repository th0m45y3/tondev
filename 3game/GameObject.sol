pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

import "Interface.sol";

abstract contract GameObject is InterfaceGameObject{
    uint health = 5;
    uint defencePower;

    modifier onlyOwner() {
        require(tvm.pubkey() != 0, 101);
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
        _;
    }

    modifier tvmacc() {tvm.accept();_;}

    function recieveAttack(uint attackPower) external override tvmacc{
        require(isAlive(), 410, "The target is dead.");
        int result = int(attackPower) - int(defencePower);
        if (result <= 0) return;
        if (uint(result) > health) {
            dying(msg.sender);
            return;
        }
        health -= uint(result);        
    }

    function getDefencePower(uint newPower) public onlyOwner{
        defencePower = newPower;
    }

    function isAlive() private view tvmacc 
    returns(bool) {
        if (health > 0) return(true);
        else return(false);
    }

    function getData() public view tvmacc
    returns(uint, uint) {
        return(health, defencePower);
    }

    function dying(address attacker) internal virtual;

    function selfDestruct(address attacker) internal tvmacc
    returns(address){
        attacker.transfer({value: 1, bounce: false, flag: 128 + 32});
        health = 0;
        defencePower = 0;
        return attacker;        
    }
}
