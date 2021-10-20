
pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

contract token {
    
    struct Album {
        string name;
        string author;
        uint year;
        uint price;
    }

    Album[] albumArr; 
    mapping (uint=>uint) albumToOwner;

    modifier checkOwnerAndAccept() {
        require(msg.pubkey() == tvm.pubkey(), 100);
        tvm.accept();
        _;
    }

    modifier checkAlbumOwnerAndAccept(uint albumId) {
        require(msg.pubkey() == albumToOwner[albumId], 101);
        tvm.accept();
        _;
    }

    function uniquenessCheck(string newName) private view returns(bool){
        for (uint i = 0; i < albumArr.length; i++) {
            if (newName == albumArr[i].name) {
                return false;
            }
        }
        return true;
    }

    function createAlbum(string name, string author, uint year) 
    public checkOwnerAndAccept {
        require(uniquenessCheck(name), 101, "The album already exists");
        albumArr.push(Album(name,author, year, 0));
        uint keyAsLastNum = albumArr.length - 1;
        albumToOwner[keyAsLastNum] = msg.pubkey();
    }

    function getAlbumOwner(uint albumId) public view returns(uint) {
        tvm.accept();
        return albumToOwner[albumId];
    }

    function getAlbumInfo(uint albumId) public view 
    returns(string albumName, string albumAuthor, uint albumYear, uint albumPrice) {
        tvm.accept();
        albumName = albumArr[albumId].name;
        albumAuthor = albumArr[albumId].author;
        albumYear = albumArr[albumId].year;
        albumPrice = albumArr[albumId].price;
    }

    function setPrice(uint albumId, uint newPrice) public 
    checkAlbumOwnerAndAccept(albumId) {
        require(newPrice > 0, 200, "Price must be greater than 0");
        albumArr[albumId].price = newPrice;
    }

}
