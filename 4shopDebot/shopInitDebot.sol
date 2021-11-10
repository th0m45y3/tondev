pragma ton-solidity ^0.47.0;
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
    address m_address;               // Contract address
    PurchaseSummary m_summ;        // Statistics of incompleted and completed purchases
    uint32 m_purchId;                 // Purchase id for update
    bool m_purchPaid;
    uint m_masterPubKey;          // User pubkey
    address m_msigAddress;           // User wallet address
    uint32 INITIAL_BALANCE =  200000000;  // Initial HasConstructorWithPubKey contract balance

    function setTodoCode(TvmCell code, TvmCell data) public {
        require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        m_stateInit = tvm.buildStateInit(code, data);
    }

    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Operation failed. sdkError {}, exitCode {}", sdkError, exitCode));
        menu();
    }

    function onSuccess() public view {
        getPurchSumm(tvm.functionId(setSummary));
    }

    function start() public override {
        Terminal.input(tvm.functionId(savePublicKey),"Please enter your public key without prefix '0:'",false);
    }

    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "ShopList DeBot";
        version = "0.0.1";
        publisher = "TON Labs";
        key = "Shopping list manager";
        author = "th0m45y3";
        support = address.makeAddrStd(0, 0x66e01d6df5a8d7677d9ab2daf7f258f1e2a7fe73da5320300395f99e01dc3b5f);
        hello = "Hi, i'm a ShopList DeBot.";
        language = "en";
        dabi = m_debotAbi.get();
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


    function waitBeforeDeploy() public  {
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
        optional(uint) none;
        TvmCell deployMsg = tvm.buildExtMsg({
            abiVer: 2,
            dest: m_address,
            callbackId: tvm.functionId(onSuccess),
            onErrorId:  tvm.functionId(onErrorRepeatDeploy),    // Just repeat if something went wrong
            time: 0,
            expire: 0,
            sign: true,
            pubkey: none,
            stateInit: image,
            call: {HasConstructorWithPubKey, m_masterPubKey}
        });
        tvm.sendrawmsg(deployMsg, 1);
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

    function menu() internal virtual; 
    
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
