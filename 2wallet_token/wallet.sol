
pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

contract wallet {
    modifier checkOwnerAndAccept() {
        require(msg.pubkey() == tvm.pubkey(), 100);
        tvm.accept();
        _;
    }

    function sendWithCommission(address dest, uint128 amount, bool bounce) public pure 
        checkOwnerAndAccept {
        dest.transfer(amount, bounce, 0);
    }

    function sendWithoutCommission(address dest, uint128 amount, bool bounce) public pure 
        checkOwnerAndAccept {
        dest.transfer(amount, bounce, 1);
    }

    function sendAndDelete(address dest, uint128 amount, bool bounce) public pure 
        checkOwnerAndAccept {
        dest.transfer(amount, bounce, 160);
    }
}
