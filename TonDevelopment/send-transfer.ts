import { getHttpEndpoint } from "@orbs-network/ton-access";
import { mnemonicToWalletKey } from "@ton/crypto";
import { internal, TonClient, WalletContractV5R1 } from "@ton/ton";

function sleep(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
    const mnemonic = "";
    const key = await mnemonicToWalletKey(mnemonic.split(" "));
    const wallet = WalletContractV5R1.create({ publicKey: key.publicKey, workchain: 0 });
     
    const endpoint = await getHttpEndpoint({ network: "testnet" });
    const client = new TonClient({ endpoint });

    if(!await client.isContractDeployed(wallet.address)){
        return console.log("Wallet is not deployed");
    }

    const walletContract = client.open(wallet);
    const seqno = await walletContract.getSeqno();

    await walletContract.sendTransfer({
        secretKey: key.secretKey,
        seqno: seqno,
        messages: [
            internal({
                to: "",
                value: "0.01",
                body: "Hello",
                bounce: false,
            })
        ],
        sendMode: 0,
    });
    
    let currentSeqno = seqno;
    while(currentSeqno === seqno){
        console.log("Waiting for transaction to be confirmed...");
        sleep(1500);
        currentSeqno = await walletContract.getSeqno();
    }

    console.log("Transaction confirmed!");
}

main();