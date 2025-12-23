import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { HelloWorld } from '../build/HelloWorld/HelloWorld_HelloWorld';
import { Add, Deposit, Reward } from '../build/HelloWorld/HelloWorld_HelloWorld'; // Import all message types
import '@ton/test-utils';
import { Dictionary } from '@ton/core';

describe('HelloWorld', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let helloWorld: SandboxContract<HelloWorld>;

    let player: SandboxContract<TreasuryContract>; // Additional test wallet for the player

    const initialCounter = 0n;
    const initialRatePerTon = 100n; // Rate: 1 TON = 100 score
    const NANO = 1000000000n;
    const emptyScores = Dictionary.empty(Dictionary.Keys.Address(), Dictionary.Values.BigInt(257));
    const emptyHeart = Dictionary.empty(Dictionary.Keys.Address(), Dictionary.Values.BigInt(257));
    const emptyLaser = Dictionary.empty(Dictionary.Keys.Address(), Dictionary.Values.BigInt(257));

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        deployer = await blockchain.treasury('deployer');

        player = await blockchain.treasury('player');

        helloWorld = blockchain.openContract(await HelloWorld.fromInit(0n, initialCounter, deployer.address, initialRatePerTon, emptyScores, emptyHeart, emptyLaser));

        const deployResult = await helloWorld.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            null,
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: helloWorld.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and helloWorld are ready to use
    });

    it('should increase counter', async () => {
        const increaseTimes = 3;
        for (let i = 0; i < increaseTimes; i++) {
            console.log(`increase ${i + 1}/${increaseTimes}`);

            const increaser = await blockchain.treasury('increaser' + i);

            const counterBefore = await helloWorld.getCounter();

            console.log('counter before increasing', counterBefore);

            const increaseBy = BigInt(Math.floor(Math.random() * 100));

            console.log('increasing by', increaseBy);

            const increaseResult = await helloWorld.send(
                increaser.getSender(),
                {
                    value: toNano('0.05'),
                },
                {
                    $$type: 'Add',
                    amount: increaseBy,
                }
            );

            expect(increaseResult.transactions).toHaveTransaction({
                from: increaser.address,
                to: helloWorld.address,
                success: true,
            });

            const counterAfter = await helloWorld.getCounter();

            console.log('counter after increasing', counterAfter);

            expect(counterAfter).toBe(counterBefore + increaseBy);
        }
    });



    it('should award score to player for a Deposit', async () => {
        const depositAmount = toNano('1'); // Deposit 1 TON

        // Get initial score before deposit
        const scoreBefore = await helloWorld.getGetScore(player.address);
        expect(scoreBefore).toBe(0n);

        // Player sends a Deposit message
        const depositMessage: Deposit = { $$type: 'Deposit' };
        await helloWorld.send(
            player.getSender(),
            { value: depositAmount },
            depositMessage,
        );

        // Calculate expected score increment
        const expectedScoreInc = (depositAmount * initialRatePerTon) / NANO;

        // Verify the score is updated correctly
        const scoreAfter = await helloWorld.getGetScore(player.address);
        expect(scoreAfter).toBe(scoreBefore + expectedScoreInc);
    });

    /*
    it('should reward a player only by the owner', async () => {
        const rewardAmount = toNano('1'); // 1 TON reward
        
        const rewardMessage: Reward = {
            $$type: 'Reward',
            to: player.address,
            amount: rewardAmount,
        };
        
        // Top up contract balance for the test
        await deployer.send({
            to: helloWorld.address,
            value: toNano('2'),
        });

        const rewardResult = await helloWorld.send(deployer.getSender(), { value: toNano('1') }, rewardMessage);
   
        // Calculate the expected transfer value
        const maxExpectedValue = rewardAmount;

        // Use a custom matcher to handle fees
        const minExpectedValue = rewardAmount - toNano('0.2'); // Adjust fee estimate as needed

        // Verify the transaction was successful and money was sent to the player
        expect(rewardResult.transactions).toHaveTransaction({
            from: helloWorld.address,
            to: player.address,
            value: 1998034400n,// Approximate value after fees
            success: true,
        });
    });
    */

    /*
    it('should fail to reward a player if not called by owner', async () => {
        const rewardAmount = toNano('1');

        const rewardMessage: Reward = {
            $$type: 'Reward',
            to: player.address,
            amount: rewardAmount,
        };
        
        // A non-owner (`player`) tries to send the Reward message
        const result = await helloWorld.send(player.getSender(), { value: toNano('1') }, rewardMessage);
        
        // Check for transaction failure due to onlyOwner() check
        expect(result.transactions).toHaveTransaction({
            from: player.address,
            to: helloWorld.address,
            success: false
        });
    });
    */

    it('should buy hearts and increase inventory', async () => {
        const qty = 2n;
        const pricePer = toNano('0.1');
        const value = pricePer * qty;

        const buyResult = await helloWorld.send(player.getSender(), { value }, { $$type: 'BuyHeart', qty });
        expect(buyResult.transactions).toHaveTransaction({ from: player.address, to: helloWorld.address, success: true });

        const after = await helloWorld.getGetHeart(player.address);
        expect(after).toBe(qty);
    });

    it('should use heart via UseHeart and decrease inventory', async () => {
        // ensure player has exactly 1 heart
        const buy = await helloWorld.send(player.getSender(), { value: toNano('0.1') }, { $$type: 'BuyHeart', qty: 1n });

        expect(buy.transactions).toHaveTransaction({
            from: player.address,
            to: helloWorld.address,
            success: true
        });

        const before = await helloWorld.getGetHeart(player.address);
        expect(before).toBe(1n);

        const useResult = await helloWorld.send(player.getSender(), { value: toNano('0.1') }, { $$type: 'UseHeart', qty: 1n });
        expect(useResult.transactions).toHaveTransaction({ from: player.address, to: helloWorld.address, success: true });

        const after = await helloWorld.getGetHeart(player.address);
        expect(after).toBe(0n);
    });

    it('should fail to buy laser if insufficient funds', async () => {
        // Laser costs 0.2 TON, send less and expect failure
        const res = await helloWorld.send(player.getSender(), { value: toNano('0.05') }, { $$type: 'BuyLaser', qty: 1n });
        expect(res.transactions).toHaveTransaction({ from: player.address, to: helloWorld.address, success: false });
    });

    it('should fail to use heart when none available', async () => {
        // Ensure player has 0 hearts by consuming any that might exist
        const b4 = await helloWorld.getGetHeart(player.address);
        if (b4 > 0n) {
            await helloWorld.send(player.getSender(), { value: toNano('0') }, { $$type: 'UseHeart', qty: b4 });
        }

        const res = await helloWorld.send(player.getSender(), { value: toNano('0') }, { $$type: 'UseHeart', qty: 1n });
        expect(res.transactions).toHaveTransaction({ from: player.address, to: helloWorld.address, success: false });
    });

});
