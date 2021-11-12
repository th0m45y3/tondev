pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "shopInitDebot.sol";

contract ListDebot is ShopInitDebot {
    
    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "ShopList DeBot — ListDebot";
        version = "0.0.1";
        publisher = "th0m45y3";
        key = "Shopping list manager";
        author = "th0m45y3";
        support = address.makeAddrStd(0, 0x6745547f71326dc4f990003d70f308ecbbbd0867b1b379df3913097d4e2cc246);
        hello = "Hi, i'm a ShopList DeBot. I can show your ShowList and delete purchs!";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }
    
    function menu() internal override {
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "You spent {} coins for {} purchs and have {} unpaid (total: {})",
                    m_summ.paidSum,
                    m_summ.paidCount,
                    m_summ.unpaidCount,
                    m_summ.paidCount + m_summ.unpaidCount
            ),
            sep,
            [
                MenuItem("Show ShopList","",tvm.functionId(showpurchs)),
                MenuItem("Delete purchase","",tvm.functionId(deletePurchase))
            ]
        );
    }

    function showpurchs() public {
        optional(uint) none; 
        Terminal.print(0, "after index=index");
        IShopList(m_address).getPurchSumm{
            abiVer: 2,
            extMsg: true,
            sign: false, 
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showShopList),
            onErrorId: tvm.functionId(onError)
        }();
        
    }
    
    function showShopList( Purchase[] purchs ) public {
        uint32 i;
        if (purchs.length > 0 ) {
            Terminal.print(0, "Your ShopList:");
            for (i = 0; i < purchs.length; i++) {
                Purchase purch = purchs[i];
                string completed;
                if (purch.isPaid) {
                    completed = '✓';
                } else {
                    completed = '-';
                }
                Terminal.print(0, format("{} {}  \"{}\"  at {} for {}", purch.id, completed, purch.name, purch.createdAt, purch.price));
            }
        } else {
            Terminal.print(0, "Your ShopList is empty");
        }
        menu();
    } 

    function deletePurchase(uint32 index) public { //uint32?
        index = index;
        if (m_summ.paidCount + m_summ.unpaidCount > 0) {
            Terminal.input(tvm.functionId(deleteSelectedPurchase), "Enter purchase number:", false);
        } else {
            Terminal.print(0, "Your ShopList is empty");
            menu();
        }
    }

    function deleteSelectedPurchase(string value) public view {
        (uint num,) = stoi(value);
        optional(uint) pubkey = 0;
        IShopList(m_address).deletePurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(num); //uint32?
    }
}
