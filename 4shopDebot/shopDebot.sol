pragma ton-solidity >= 0.35.0;
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
import "Includes.sol";

contract ShopDebot is Debot, Upgradable {
    TvmCell m_stateInit;             // Contract code
    address m_address;               // Contract address
    PurchaseSummary m_summ;        // Statistics of incompleted and completed purchases
    uint32 m_purchId;                 // Purchase id for update
    bool m_purchPaid;
    uint256 m_masterPubKey;          // User pubkey
    address m_msigAddress;           // User wallet address
    uint32 INITIAL_BALANCE =  200000000;  // Initial HasConstructorWithPubKey contract balance

    function setTodoCode(TvmCell code, TvmCell data) public {
        require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        m_stateInit = tvm.buildStateInit(code, data);
    }

    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Operation failed. sdkError {}, exitCode {}", sdkError, exitCode));
        _menu();
    }

    function onSuccess() public view {
        _getStat(tvm.functionId(setSummary));
    }

    function start() public override {
        Terminal.input(tvm.functionId(savePublicKey),"Please enter your public key without prefix '0:'",false);
    }

    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "HasConstructorWithPubKey DeBot";
        version = "0.0.1";
        publisher = "TON Labs";
        key = "Shopping list manager";
        author = "TON Labs";
        support = address.makeAddrStd(0, 0x66e01d6df5a8d7677d9ab2daf7f258f1e2a7fe73da5320300395f99e01dc3b5f);
        hello = "Hi, i'm a HasConstructorWithPubKey DeBot.";
        language = "en";
        dabi = m_debotAbi.get();
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID, ConfirmInput.ID ];
    }

    function savePublicKey(string value) public {
        Terminal.print(0, "Converting to string");
        (uint res, bool status) = stoi("0x"+value);
        Terminal.print(0, "Checking account status");
        if (status) {
            m_masterPubKey = res;

            Terminal.print(0, "Checking if you already have a HasConstructorWithPubKey ...");
            TvmCell deployState = tvm.insertPubkey(m_stateInit, m_masterPubKey);
            m_address = address.makeAddrStd(0, tvm.hash(deployState));
            Terminal.print(0, format( "Info: your HasConstructorWithPubKey contract address is {}", m_address));
            Sdk.getAccountType(tvm.functionId(checkStatus), m_address);

        } else {
            Terminal.input(tvm.functionId(savePublicKey),"Wrong public key. Try again!\nPlease enter your public key",false);
        }
    }

    function checkStatus(int8 acc_type) public {
        if (acc_type == 1) {            // acc is active and  contract is already deployed
            _getStat(tvm.functionId(setSummary));

        } else if (acc_type == -1) {   // acc is inactive
            Terminal.print(0, "You don't have a HasConstructorWithPubKey yet, so a new contract with an initial balance of 0.2 tokens will be deployed");
            AddressInput.get(tvm.functionId(creditAccount),"Select a wallet for payment. We will ask you to sign two transactions");

        } else if (acc_type == 0) {    // acc is uninitialized
            Terminal.print(0, format(
                "Deploying new contract. If an error occurs, check if your HasConstructorWithPubKey contract has enough tokens on its balance"
            ));
            deploy();

        } else if (acc_type == 2) {     // acc is frozen
            Terminal.print(0, format("Can not continue: account {} is frozen", m_address));
        }
    }

    function creditAccount(address value) public {
        m_msigAddress = value;
        optional(uint256) pubkey = 0;
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
        optional(uint256) none;
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
            call: {AShopList, m_masterPubKey}
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
        _menu();
    }

    function _menu() private {
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "You have {}/{}/{} (paid/unpad/total) purchases and spent {}",
                    m_summ.paidCount,
                    m_summ.unpaidCount,
                    m_summ.paidCount + m_summ.unpaidCount,
                    m_summ.price ///countsum
            ),
            sep,
            [
                MenuItem("Create new Purchase","",tvm.functionId(createPurchs)),
                MenuItem("Show Purchase list","",tvm.functionId(showPurshases)),
                MenuItem("Update Purchase status","",tvm.functionId(updatePurchase)),
                MenuItem("Delete Purchase","",tvm.functionId(deletePurchase))
            ]
        );
    }

    function createPurchs(uint32 index) public {
        index = index;
        Terminal.input(tvm.functionId(createPurchase_), "One line please:", false);
    }

    function createPurchase_(string value) public view {
        optional(uint256) pubkey = 0;
        HasConstructorWithPubKey(m_address).createPurchs{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(value);
    }

    function showPurshases(uint32 index) public view {
        index = index;
        optional(uint256) none;
        HasConstructorWithPubKey(m_address).getPurchases{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showPurshases_),
            onErrorId: 0
        }();
    }

    function showPurshases_( Purchase[] purchases ) public {
        uint32 i;
        if (purchases.length > 0 ) {
            Terminal.print(0, "Your purchases list:");
            for (i = 0; i < purchases.length; i++) {
                Purchase purch = purchases[i];
                string completed;
                if (purch.isDone) {
                    completed = '✓';
                } else {
                    completed = ' ';
                }
                Terminal.print(0, format("{} {}  \"{}\"  at {} for {}", Purchase.id, completed, Purchase.name, Purchase.createdAt, Purchase.price));
            }
        } else {
            Terminal.print(0, "Your purchases list is empty");
        }
        _menu();
    }

    function updatePurchase(uint32 index) public {
        index = index;
        if (m_summ.completeCount + m_summ.incompleteCount > 0) {
            Terminal.input(tvm.functionId(updatePurchase_), "Enter purchase number:", false);
        } else {
            Terminal.print(0, "Sorry, you have no purchases to update");
            _menu();
        }
    }

    function updatePurchase_(string value) public {
        (uint256 num,) = stoi(value);
        m_purchId = uint32(num);
        ConfirmInput.get(tvm.functionId(updatePurchasePayment),"Is this purchase paid?");
    }

    function updatePurchasePayment(bool value) public {
        m_purchPaid = price;
        Terminal.input(tvm.functionId(updatePurchasePrice), "Enter purchase price:", false);
    }

    function updatePurchasePrice(uint price) public view {
        optional(uint256) pubkey = 0;
        HasConstructorWithPubKey(m_address).updatePurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(m_purchId, m_purchPaid, price);
    }

    function deletePurchase(uint32 index) public {
        index = index;
        if (m_summ.completeCount + m_summ.incompleteCount > 0) {
            Terminal.input(tvm.functionId(deletePurchase_), "Enter Purchase number:", false);
        } else {
            Terminal.print(0, "Sorry, you have no Purchases to delete");
            _menu();
        }
    }

    function deletePurchase_(string value) public view {
        (uint256 num,) = stoi(value);
        optional(uint256) pubkey = 0;
        HasConstructorWithPubKey(m_address).deletePurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(uint32(num));
    }

    function _getStat(uint32 answerId) private view {
        optional(uint256) none;
        HasConstructorWithPubKey(m_address).getStat{
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
