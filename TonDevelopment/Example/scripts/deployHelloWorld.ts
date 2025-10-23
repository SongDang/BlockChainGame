import { toNano } from '@ton/core';
import { HelloWorld } from '../build/HelloWorld/HelloWorld_HelloWorld';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const helloWorld = provider.open(await HelloWorld.fromInit(BigInt(Math.floor(Math.random() * 10000)), 0n));

    await helloWorld.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        null,
    );

    await provider.waitForDeploy(helloWorld.address);

    console.log('ID', await helloWorld.getId());
}
