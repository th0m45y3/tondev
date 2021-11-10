pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "shopInitDebot.sol";

contract FillInDebot is ShopInitDebot {

    function menu() internal override{
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
                MenuItem("Create new purchase","",tvm.functionId(createPurchs))
            ]
        );
    }

    function createPurchs(/*uint32 index*/) public {
        //index;
        Terminal.input(tvm.functionId(createNamedPurchase), "Enter one-line name:", false);
    }

    function createNamedPurchase(string name) public view {
        optional(uint) pubkey = 0;
        IShopList(m_address).createPurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(name);
    }
}