pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "shopInitDebot.sol";

contract ListDebot is ShopInitDebot {
    
    function menu() internal override {
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "You spent {} for {} purchases and have {} unpaid (total: {})",
                    m_summ.paidSum,
                    m_summ.paidCount,
                    m_summ.unpaidCount,
                    m_summ.paidCount + m_summ.unpaidCount
            ),
            sep,
            [
                MenuItem("Show ShopList","",tvm.functionId(showPurshases)),
                MenuItem("Delete purchase","",tvm.functionId(deletePurchase))
            ]
        );
    }
    
    function showShopList( Purchase[] purchases ) public {
        uint32 i;
        if (purchases.length > 0 ) {
            Terminal.print(0, "Your ShopList:");
            for (i = 0; i < purchases.length; i++) {
                Purchase purch = purchases[i];
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
    
    function showPurshases(uint32 index) public view {
        //index = index;
        optional(uint) none;
        IShopList(m_address).getPurchases{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showShopList),
            onErrorId: 0
        }();
    }

    function deletePurchase(uint32 index) public {
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
            }(uint32(num));
    }
}
