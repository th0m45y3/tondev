pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "shopInitDebot.sol";

contract FillInDebot is ShopInitDebot {    
    bytes m_icon;

    function setIcon(bytes icon) public {
        require(msg.pubkey() == tvm.pubkey(), 100);
        tvm.accept();
        m_icon = icon;
    }


    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "ShopList DeBot — FillInDebot";
        version = "0.0.1";
        publisher = "th0m45y3";
        key = "Shopping list manager";
        author = "th0m45y3";
        support = address.makeAddrStd(0, 0x6745547f71326dc4f990003d70f308ecbbbd0867b1b379df3913097d4e2cc246);
        hello = "Hi, i'm a ShopList DeBot. I can create new purchases for your ShopList!";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

    function menu() internal override{
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "You spent {} coins for {} purchases and have {} unpaid (total: {})",
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

    function createPurchs(uint32 index) public {
        index = index;
        Terminal.input(tvm.functionId(createNamedPurchase), "Enter one-line name:", false);
    }

    function createNamedPurchase(string value) public view {
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
            }(value);
    }
}