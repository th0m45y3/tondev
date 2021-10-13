
pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

contract newProj {
    uint32 public product = 1;

    constructor() public {
        require(tvm.pubkey() != 0, 101);
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
    }

    function renderProduct () public view returns (uint32) {
        tvm.accept();
        return product;
    }

    function multiply (uint32 num) public returns (uint32) {
        require(num < 10 && num >= 0, 200, 'the multiplier must be on range [0, 9]');
        tvm.accept();
        product = num * product;
        return product;
    }

}
