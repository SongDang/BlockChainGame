import { mnemonicToWalletKey } from "@ton/crypto"
import { WalletContractV5R1 } from "@ton/ton";

async function main() {
  const mnemonic = "";
  const key = await mnemonicToWalletKey(mnemonic.split(" "));
  const wallet = WalletContractV5R1.create({ publicKey: key.publicKey, workchain: 0 });

  console.log("Address:", wallet.address.toString({ testOnly: true }));
  console.log("workchain:", wallet.address.workChain);
}
main();
