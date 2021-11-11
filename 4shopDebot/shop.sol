pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "includes.sol";

contract ShopList is IShopList{
    uint m_count;
    mapping(uint => Purchase) m_purchases;
    uint m_ownerPubkey;

    modifier onlyOwner() {
        require(msg.pubkey() == m_ownerPubkey, 178);
        _;
    }

    modifier tvmacc() {
        tvm.accept();
        _;
    }

    // modifier onlyOwnerAndAccept() {
    //     tvm.accept();
    //     require(msg.pubkey() == m_ownerPubkey, 101);
    //     _;
    // }

    constructor( uint pubkey) public tvmacc{
        require(pubkey != 0, 120);
        m_ownerPubkey = pubkey;
    }

    function createPurchase(string value) external override tvmacc{
        m_count++;
        m_purchases[m_count] = Purchase(m_count, value, now, false, 0);
    }

    function updatePurchase(uint id, bool isPaid, uint price) external override tvmacc{
        //debot need to catch the exist error !!!!!!!!!
        require(m_purchases.exists(id), 102);
        optional(Purchase) purch = m_purchases.fetch(id);
        require(purch.hasValue(), 102);
        m_purchases[id].isPaid = isPaid;
        m_purchases[id].price = price;
    }

    function deletePurchase(uint id) external override tvmacc{
        //debot need to catch the exist error !!!!!!!!!
        require(m_purchases.exists(id), 102);
        delete m_purchases[id];
    }

    function getPurchases() external override tvmacc returns (Purchase[] purchases) {
        string name;
        uint createdAt;
        bool isPaid;
        uint price;

        for((uint id, Purchase purch) : m_purchases) {
            name = purch.name;
            isPaid = purch.isPaid;
            createdAt = purch.createdAt;
            price = purch.price;
            purchases.push(Purchase(id, name, createdAt, isPaid, price));
       }
    }

    function getPurchSumm() external override tvmacc returns (PurchaseSummary purchSumm) {
        uint paidCount;
        uint unpaidCount;
        uint paidSum;

        for((, Purchase purch) : m_purchases) {
            if  (purch.isPaid) {
                paidCount ++;
                paidSum += purch.price;
            } else {
                unpaidCount ++;
            }
        }
        purchSumm = PurchaseSummary( paidCount, unpaidCount, paidSum);
    }
}

