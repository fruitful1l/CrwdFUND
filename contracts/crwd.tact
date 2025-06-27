import "@stdlib/ownable";
import "../crwd_child";
import "..jetton/minter.tact";
import "../jetton/wallet.tact";
import "./jetton/minter";
import "./utils";
import "./messages";

inline fun setMetadata(
    name: String,
    description: String,
    symbol: String,
    image: String,
) {
    let metadata = composeJettonMetadata(name, description, symbol, image);
}



contract Crwd with Ownable {
    owner:Address;
    receive() {
        
    }

    init() {
        self.owner = sender();
    }


    receive(msg: DevToMaster) {
        deploy(DeployParameters {
            init: initOf CrwdChld(
                sender(),
                msg.projectName,
                msg.tokenName,
                msg.tokenSymbolLink,
                msg.fundingGoal,
                msg.duration,
            ),
            value: ton("0.5"),
        }); 

        deploy(DeployParameters {
            init: initOf JettonMinterSharded(
                100000000,
                sender(),
                setMetadata(
                    msg.tokenName,
                    "Crowdfunding token for " + msg.projectName,
                    msg.tokenSymbolLink,
                    "https://example.com/image.png", // Replace with actual image URL

                ),
                true, // mintable

            ),
            value: ton("0.5"),
        });
    }



}
