import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { Crwd } from '../build/Crwd/Crwd_Crwd';
import '@ton/test-utils';

describe('Crwd', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let crwd: SandboxContract<Crwd>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        crwd = blockchain.openContract(await Crwd.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await crwd.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            null,
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: crwd.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and crwd are ready to use
    });
});
