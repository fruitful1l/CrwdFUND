import "@stdlib/ownable";
import "../messages";
import "../crwd_child";
import "..jetton/minter.tact";
import "../jetton/wallet.tact";





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
                ownerAddress: = sender();
                projectName: = msg.projectName,
                tokenName = msg.tokenName,
                tokenSymbolLink = msg.tokenSymbolLink,
                fundingGoal = msg.fundingGoal,
                duration = msg.duration,
            ),
            value: ton("0.5"),
        }); 

        deploy(DeployParameters {
            init: initOf (
                ownerAddress: = sender();
                projectName: = msg.projectName,
                tokenName = msg.tokenName,
                tokenSymbolLink = msg.tokenSymbolLink,
                fundingGoal = msg.fundingGoal,
                duration = msg.duration,
            ),
            value: ton("0.5"),
        });
    }



}
