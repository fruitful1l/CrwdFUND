import "@stdlib/ownable";
import "../messages";
import "../crwd_child";
import "./messages";
import "./crwd_child";





contract Crwd with Ownable() {
    owner:Address;
    receive() {
        cashback(sender());
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
    }



}
