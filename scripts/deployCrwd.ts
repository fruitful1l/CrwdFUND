import { toNano } from '@ton/core';
import { Crwd } from '../build/Crwd/Crwd_Crwd';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const crwd = provider.open(await Crwd.fromInit());

    await crwd.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        null,
    );

    await provider.waitForDeploy(crwd.address);

    // run methods on `crwd`
}
