pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../Debot.sol";
import "../Terminal.sol";
import "../Menu.sol";
import "../AddressInput.sol";
import "../ConfirmInput.sol";
import "../Upgradable.sol";
import "../Sdk.sol";
import "includes.sol";

abstract contract ShopInitDebot is Debot, Upgradable {
    TvmCell m_stateInit;             // Contract code
    address public m_address;               // Contract address
    PurchaseSummary m_summ;        // Statistics of incompleted and completed purchases
    uint32 m_purchId;                 // Purchase id for update
    bool m_purchPaid;
    uint m_masterPubKey;          // User pubkey
    address m_msigAddress;           // User wallet address
    uint32 INITIAL_BALANCE =  200000000;  // Initial contract balance
    bytes internal m_icon;

    function setTodoCode(TvmCell code, TvmCell data) public {
        require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        m_stateInit = tvm.buildStateInit(code, data);
    }

    // function setIcon(bytes _icon) public {
    //     require(msg.pubkey() == tvm.pubkey(), 100);
    //     tvm.accept();
    //     m_icon = _icon;
    // }

    function getDebotInfo() functionID(0xDEB) public view virtual override returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    );

    function menu() internal virtual; 

    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Operation failed. sdkError {}, exitCode {}", sdkError, exitCode));
        menu();
    }

    function onSuccess() public view{
        getPurchSumm(tvm.functionId(setSummary));
    }

    function start() public override {
        Terminal.input(tvm.functionId(savePublicKey),"Please enter your public key without prefix '0:'",false);
    }

    function getRequiredInterfaces() public view override returns (uint[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID, ConfirmInput.ID ];
    }

    function savePublicKey(string value) public {
        Terminal.print(0, "Converting to string");
        (uint res, bool status) = stoi("0x"+value);
        Terminal.print(0, "Checking account status");
        if (status) {
            m_masterPubKey = res;

            Terminal.print(0, "Checking if you already have a ShopList ...");
            TvmCell deployState = tvm.insertPubkey(m_stateInit, m_masterPubKey);
            m_address = address.makeAddrStd(0, tvm.hash(deployState));
            Terminal.print(0, format( "Info: your ShopList contract address is {}", m_address));
            Sdk.getAccountType(tvm.functionId(checkStatus), m_address);

        } else {
            Terminal.input(tvm.functionId(savePublicKey),"Wrong public key. Try again!\nPlease enter your public key",false);
        }
    }

    function checkStatus(int8 acc_type) public {
        if (acc_type == 1) {            // acc is active and  contract is already deployed
            getPurchSumm(tvm.functionId(setSummary));

        } else if (acc_type == -1) {   // acc is inactive
            Terminal.print(0, "You don't have a ShopList yet, so a new contract with an initial balance of 0.2 tokens will be deployed");
            AddressInput.get(tvm.functionId(creditAccount),"Select a wallet for payment. You need to sign two transactions");

        } else if (acc_type == 0) {    // acc is uninitialized
            Terminal.print(0, format(
                "Deploying new contract. If an error occurs, check if your ShopList contract has enough tokens on its balance"
            ));
            deploy();

        } else if (acc_type == 2) {     // acc is frozen
            Terminal.print(0, format("Can not continue: account {} is frozen", m_address));
        }
    }

    function creditAccount(address value) public {
        m_msigAddress = value;
        optional(uint) pubkey = 0;
        TvmCell empty;
        Transactable(m_msigAddress).sendTransaction{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(waitBeforeDeploy),
            onErrorId: tvm.functionId(onErrorRepeatCredit)  // Just repeat if something went wrong
        }(m_address, INITIAL_BALANCE, false, 3, empty);
    }

    function onErrorRepeatCredit(uint32 sdkError, uint32 exitCode) public {
        sdkError;
        exitCode;
        creditAccount(m_msigAddress);
    }

    function waitBeforeDeploy() public {
        Sdk.getAccountType(tvm.functionId(checkAccForDeploy), m_address);
    }

    function checkAccForDeploy(int8 acc_type) public {
        if (acc_type ==  0) {
            deploy();
        } else {
            waitBeforeDeploy();
        }
    }

    function deploy() private view { 
        TvmCell image = tvm.insertPubkey(m_stateInit, m_masterPubKey);
        optional(uint256) none;
        TvmCell deployMsg = tvm.buildExtMsg({
            abiVer: 2,
            dest: m_address,
            callbackId: 0,
            onErrorId:  tvm.functionId(onErrorRepeatDeploy),    
            time: 0,
            expire: 0,
            sign: true,
            pubkey: none,
            stateInit: image,
            call: {HasConstructorWithPubKey, m_masterPubKey}
        });
        tvm.sendrawmsg(deployMsg, 1);
        onSuccess();
    }

    function onErrorRepeatDeploy(uint32 sdkError, uint32 exitCode) public view {
        sdkError;
        exitCode;
        deploy();
    }

    function setSummary(PurchaseSummary summ) public {
        m_summ = summ;
        menu();
    }

//no    
    function getPurchSumm(uint32 answerId) private view { 
        optional(uint) none;
        IShopList(m_address).getPurchSumm{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: answerId,
            onErrorId: 0
        }();
    }

    function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }
}
