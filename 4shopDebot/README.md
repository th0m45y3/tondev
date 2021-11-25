<h1 align="left">ShopList DeBots</h1>
<p align="left">A DeBot batch to manage shopping list</p>

# Table of Content
- [Table of Content](#table-of-content)
- [Description](#description)
- [Requirements](#requirements)
- [How to try DeBot](#how-to-try-debot)
- How to Run
  - [wallet deploy](#wallet-deploy)
  - [deploy bots](#deploy-bots)
  - [run bots](#run-bots)
  - [hard links](#hard-links)

# Description

- [`shop`](https://github.com/th0m45y3/tondev/blob/main/4shopDebot/shop.sol) - main contract with all ShopList functions implemented.
- [`includes`](https://github.com/th0m45y3/tondev/blob/main/4shopDebot/Includes.sol) - structs, interfaces, and abstract contract (to access constructor in shop.sol).
- [`shopInitDebot`](https://github.com/th0m45y3/tondev/blob/main/4shopDebot/shopInitDebot.sol) - abstract DeBot for initialization shopDeBots. Includes general list methods: setTodoCode, deploy, save public key, etc. Uses several basic DeBot interfaces: Terminal, AddressInput, AmountInput, ConfirmInput in [`workFolder`](https://github.com/th0m45y3/tondev/tree/main/4shopDebot/workFolder).
- [`fillInDebot`](https://github.com/th0m45y3/tondev/blob/main/4shopDebot/fillInDebot.sol) - DeBot for adding new purchases into the ShopList.
- [`shoppingDebot`](https://github.com/th0m45y3/tondev/blob/main/4shopDebot/shoppingDebot.sol)[corrections needed] - used to mark purchases as paid and to update the price.
- [`listDebot`](https://github.com/th0m45y3/tondev/blob/main/4shopDebot/listDebot.sol)[corrections needed] - shows the ShopList and removes purchases.



# Requirements

### tonos-cli
To run and debug debots install [`tonos-cli`](https://github.com/tonlabs/tonos-cli):

Note: minimal required version >= 0.11.4.

Install using `tondev`:

```bash
tondev tonos-cli install
```

and set 0.47.0 tondev compiler:

```bash
tondev sol set --compiler 0.47.0
```

### jQuery
To deploy debots using [`deployNet.sh`](https://github.com/th0m45y3/tondev/blob/main/4shopDebot/deployNet.sh) install jQuery:

```bash
chocolatey install jq
```
or go to https://stedolan.github.io/jq/download/.



# How to try DeBot

All DeBots alreadt deployed to net.ton.dev](http://net.ton.dev) and can be called through any DeBot browser that supports it.

To try it out in TON Surf, go to https://beta.ton.surf/ or https://web.ton.surf/:

[`fillInDebot`](https://web.ton.surf/debot?address=0%3Ab5d665f5c7e3193f375aef0ef3628de465a00240963d91b06234f5883b871e93&net=devnet&restart=true)
[`shoppingDebot`](https://web.ton.surf/debot?address=0%3A70c1aaad47c70a10654bbe764460a8acb2705fc4ada1ee2943ae100116c34603&net=devnet&restart=true)
[`listDebot`](https://web.ton.surf/debot?address=0%3A8e3c9622fd069133e51c7b49b643e2a44ad2242e38dcb90ee434161816b46923&net=devnet&restart=true)



# How to deploy and run DeBots

### wallet deploy
Deploy and top up of [`wallet`](https://github.com/th0m45y3/tondev/blob/main/4shopDebot/workFolder/wallet.sol) contract is required:

```bash
tonos-cli genaddr wallet.tvc wallet.abi.json --setkey wallet.keys.json

tonos-cli --url https://net.ton.dev deploy wallet.tvc "{}" --sign wallet.keys.json --abi wallet.abi.json
```

### deploy bots
DeBots can be deployed using [`deployNet.sh`](https://github.com/th0m45y3/tondev/blob/main/4shopDebot/deployNet.sh):

```bash
./deployNet.sh fillInDebot.sol shop

./deployNet.sh shoppingDebot.sol shop

./deployNet.sh listDebot.sol shop
```

### run bots
To run DeBots open the link: `https://uri.ton.surf/debot?address=<address>&net=devnet`

### hard links
Tip: you can do a hard links copies of .sol files in the [`workFolder`](https://github.com/th0m45y3/tondev/tree/main/4shopDebot/workFolder) and run ./deploy commands right after saving changes in .sol files in the [`main folder`](https://github.com/th0m45y3/tondev/tree/main/4shopDebot) folder.

```bash
cp -fl shop.sol includes.sol shopInitDebot.sol fillInDebot.sol shoppingDebot.sol listDebot.sol ../
```
