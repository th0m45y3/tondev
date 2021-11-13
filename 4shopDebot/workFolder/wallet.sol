pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

contract wallet {

    function sendM(address dest, uint128 amount) public {
        dest.transfer(amount, false, 1);
        tvm.accept();
    }
}
