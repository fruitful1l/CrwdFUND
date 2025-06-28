import "@stdlib/ownable";
import "./crwd_child.tact";
import "./jetton/minter";
import "./utils";
import "./messages";


inline fun setMetadata(
    name: String,
    description: String,
    symbol: String,
    image: String,
): Cell {
    let metadata = composeJettonMetadata(name, description, symbol, image);
    return metadata;
}



contract Crwd with Ownable {
    owner:Address;
    id: Int = 0;
    id_mint: map<Int, Address> = emptyMap();
    id_proj: map<Int, Address> = emptyMap();
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
                self.id,
            ),
            value: ton("0.5"),
        }); 
        
        

        deploy(DeployParameters {
            init: initOf JettonMinterSharded(
                100000000,
                myAddress(),
                setMetadata(
                    msg.tokenName,
                    msg.projectName,
                    "NANA",
                    msg.tokenSymbolLink, // Replace with actual image URL

                ),
                true, // mintable
                self.id,
            ),
            value: ton("0.5"),
        });
        self.id_mint.set(self.id, contractAddress(initOf JettonMinterSharded(
                100000000,
                myAddress(),
                setMetadata(
                    msg.tokenName,
                    msg.projectName,
                    "NANA",
                    msg.tokenSymbolLink, // Replace with actual image URL

                ),
                true, // mintable
                self.id,
            )));
        self.id_proj.set(self.id, contractAddress(initOf CrwdChld(
                sender(),
                msg.projectName,
                msg.tokenName,
                msg.tokenSymbolLink,
                msg.fundingGoal,
                msg.duration,
                self.id,
            )));


        self.id += 1;
    }

    receive(msg: Invest) {
        let projectAddress = self.id_proj.get(msg.project);
        require(projectAddress != null, "Project not found");
        dump(self.id_mint.get(msg.project)!!);


        send(SendParameters {
            to: projectAddress!!,
            value: ton("0.1"), // Adjust the amount as needed
            mode: SendRemainingValue | SendBounceIfActionFail,
        });
        
        send(SendParameters {
            to: self.id_mint.get(msg.project)!!,
            value: ton("0.2"), // Adjust the amount in future
            mode: SendRemainingValue | SendBounceIfActionFail,
            body: Mint {
                queryId: 0,
                receiver: sender(),
                mintMessage: JettonTransferInternal {
                    queryId: 0,
                    amount: 100, // Adjust the amount in future, ref to value
                    sender: myAddress(),
                    responseDestination: sender(),
                    forwardTonAmount: ton("0.10"),
                    forwardPayload: beginCell().storeUint(0, 1).endCell().beginParse()

                },

            }.toCell(),
        })
    }   

    

    get fun Minters(): map<Int, Address> {
        return(self.id_mint);
    }

    get fun Projects(): map<Int, Address> {
        return(self.id_proj);
    }

}
