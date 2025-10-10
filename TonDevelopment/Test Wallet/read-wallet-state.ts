import { getHttpEndpoint }       from "@orbs-network/ton-access";
import { mnemonicToWalletKey }   from "@ton/crypto";
import { TonClient, WalletContractV5R1, fromNano } from "@ton/ton";

async function main() {
    const mnemonic = "";
    const key = await mnemonicToWalletKey(mnemonic.split(" "));
    const wallet = WalletContractV5R1.create({ publicKey: key.publicKey, workchain: 0 });
    
    const endpoint = await getHttpEndpoint({ network: "testnet" });
    const client = new TonClient({ endpoint });

    const balance = await client.getBalance(wallet.address);
    console.log("Balance:", fromNano(balance));

    const walletContract = client.open(wallet);
    const seqno = await walletContract.getSeqno();
    console.log("Seqno:", seqno);
}

main();