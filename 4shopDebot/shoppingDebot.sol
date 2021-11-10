pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "shopInitDebot.sol";

contract ShoppingDebot is ShopInitDebot {

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
                MenuItem("Update purchase status","",tvm.functionId(updatePurch))
            ]
        );
    }

    function updatePurch(uint32 index) public {
        index = index;
        if (m_summ.paidCount + m_summ.unpaidCount > 0) {
            Terminal.input(tvm.functionId(updateSelectedPurch), "Enter purchase number:", false);
        } else {
            Terminal.print(0, "Your ShopList is empty");
            menu();
        }
    }

    function updateSelectedPurch(string value) public {
        (uint num,) = stoi(value);
        m_purchId = uint32(num);
        ConfirmInput.get(tvm.functionId(updatePurchPayment),"Is this purchase paid?");
    }

    function updatePurchPayment(bool value) public {
        m_purchPaid = value;
        Terminal.input(tvm.functionId(updatePurchPrice), "Enter purchase price:", false);
    }

    function updatePurchPrice(uint price) public view {
        optional(uint) pubkey = 0;
        IShopList(m_address).updatePurchase{
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

}
