
pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

contract queque {
    string[] st;

    constructor() public {
        require(tvm.pubkey() != 0, 101);
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();

    }

    function add(string newValue) public {
        st.push(newValue);
        tvm.accept();
    }

    function get() public returns (string) {
        require(!st.empty(), 200, 'queque is empty');
        tvm.accept();
        string element = st[0];
        for (uint i = 0; i < st.length - 1; i++) {
            st[i] = st[i+1];
        }
        st.pop();
        return element;
        }
}
