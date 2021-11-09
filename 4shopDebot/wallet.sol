pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

contract wallet {
    constructor() public {
        tvm.accept();
    }
    modifier checkOwnerAndAccept() {
        require(msg.pubkey() == tvm.pubkey(), 100);
        tvm.accept();
        _;
    }

    function sendWithCommission(address dest, uint128 amount) public pure 
        checkOwnerAndAccept {
        dest.transfer(amount, false, 0);
    }

    function sendMoney(address dest, uint128 amount) public {
        dest.transfer(amount, false, 1);
    }

    function sendAndDelete(address dest, uint128 amount) public pure 
        checkOwnerAndAccept {
        dest.transfer(amount, false, 160);
    }
}
