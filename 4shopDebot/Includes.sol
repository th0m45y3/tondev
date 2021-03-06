pragma ton-solidity ^0.47.0;

struct Purchase {
    uint id;
    string name;
    uint createdAt;
    bool isPaid;
    uint price;
}

struct PurchaseSummary {
    uint paidCount;
    uint unpaidCount;
    uint paidSum;
}

interface IShopList {
   function createPurchase(string name) external;
   function updatePurchase(uint id, bool isPaid, uint price) external;
   function deletePurchase(uint id) external;
   function getPurchases() external returns (Purchase[] purchases);
   function getPurchSumm() external returns (PurchaseSummary purchSumm);
}

interface Transactable {
   function sendTransaction(address dest, 
      uint128 value, 
      bool bounce, 
      uint8 flags, 
      TvmCell payload
      )
      external;
}

abstract contract HasConstructorWithPubKey {
   constructor(uint pubkey) public {}
}
