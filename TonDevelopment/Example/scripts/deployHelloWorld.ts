import { toNano, Address, Dictionary } from '@ton/core';
import { HelloWorld } from '../build/HelloWorld/HelloWorld_HelloWorld';
import { NetworkProvider } from '@ton/blueprint';


export async function run(provider: NetworkProvider) {
    // Generate random ID for the contract
    const id = BigInt(Math.floor(Math.random() * 10000));
    
    // Initial counter value
    const initialCounter = 0n;
    
    // Owner address - the deployer will be the owner
    const ownerAddress: Address = provider.sender().address!;
    
    // Rate: 1 TON = 100 score
    const ratePerTon = 100n;
    
    // Initialize empty scores map
    const emptyScores = Dictionary.empty(
        Dictionary.Keys.Address(), 
        Dictionary.Values.BigInt(257)
    );

    const helloWorld = provider.open(await HelloWorld.fromInit(id, initialCounter, ownerAddress, ratePerTon, emptyScores));

    await helloWorld.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        null,
    );

    await provider.waitForDeploy(helloWorld.address);

    console.log('ID', await helloWorld.getId());
    console.log('Contract Address:', helloWorld.address.toString());
    console.log('Owner:', (await helloWorld.getGetOwner()).toString());
    console.log('Rate:', await helloWorld.getGetRate());
    console.log('Balance:', await helloWorld.getGetBalance());
}
