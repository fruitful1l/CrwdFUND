//  SPDX-License-Identifier: MIT
//  Copyright © 2025 TON Studio

import "./wallet";
import "../messages";
import "../constants";
import "../utils.tact";
import "../utils";
import "./shard-utils";
import "./send";

struct JettonMinterState {
    totalSupply: Int as coins;
    mintable: Bool;
    adminAddress: Address;
    jettonContent: Cell;
    jettonWalletCode: Cell;
}

contract JettonMinterSharded(
    totalSupply: Int as coins,
    owner: Address,
    jettonContent: Cell,
    mintable: Bool, // Should be deployed with this flag set to true
    id: Int,
) {
    receive(){
        require(self.owner == sender(), "not owner");
        
    }

    receive(msg: ProvideWalletAddress) {
        let ownerWorkchain: Int = parseStdAddress(msg.ownerAddress.asSlice()).workchain;

        let ownerShard = msg.ownerAddress.getShard();

        let hash = getJettonWalletInit(msg.ownerAddress).hash();

        // If owner is basechain address, we can calculate jettonWallet
        let targetJettonWallet: BasechainAddress = (ownerWorkchain == Basechain)
            ? BasechainAddress { hash: changeShard(hash, ownerShard) }
            : emptyBasechainAddress();

        MessageParameters {
            body: makeTakeWalletAddressMsg(targetJettonWallet, msg),
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
        }.send();
    }

    receive(msg: JettonBurnNotification) {
        let sender = parseStdAddress(sender().asSlice());
        let wallet = getJettonBasechainWalletByOwner(msg.sender);

        // Workchain 0 is basechain
        require(sender.workchain == Basechain && sender.address == wallet.hash!!, "Unauthorized burn");

        self.totalSupply -= msg.amount;

        if (msg.responseDestination != null) {
            MessageParameters {
                to: msg.responseDestination!!,
                body: JettonExcesses { queryId: msg.queryId }.toCell(),
                value: 0,
                bounce: false,
                mode: SendRemainingValue | SendIgnoreErrors, // ignore errors, because supply has already been updated
            }.send();
        }
    }

    // Owner of this contract may be masterchain address,
    // however minting is possible only to basechain addresses
    // it is asserted inside the deploy function
    receive(msg: Mint) {
        require(sender() == self.owner, "Incorrect sender");
        require(self.mintable, "Mint is closed");

        checkEitherForwardPayload(msg.mintMessage.forwardPayload);

        let ctx = context();
        // we don't add compute fees for mint itself and reserve here
        // it's okay since it’s sent only by the admin and excesses will return back
        require(
            ctx.value >
            minTonsForStorage +
            msg.mintMessage.forwardTonAmount +
            ctx.readForwardFee() +
            getForwardFee(walletStateInitCells, walletStateInitBits, false) +
            2 * getComputeFee(gasForTransfer, false),
            "Insufficient gas for mint",
        );

        self.totalSupply += msg.mintMessage.amount;

        let receiverShard = msg.receiver.getShard();

        // basechain destination is calculated inside deploy function
        DeployParameters {
            value: 0, // ignore msg.tonAmount and use SendMode 64 instead
            bounce: true,
            mode: SendRemainingValue | SendBounceIfActionFail,
            body: msg.mintMessage.toCell(),
            init: initOf JettonWalletSharded(msg.receiver, myAddress(), 0),
        }.toShard(receiverShard).send();
    }

    receive(msg: JettonUpdateContent) {
        require(sender() == self.owner, "Incorrect sender");
        self.jettonContent = msg.content;
    }

    receive(msg: ChangeOwner) {
        require(sender() == self.owner, "Incorrect sender");
        self.owner = msg.newOwner;
    }

    receive(msg: CloseMinting) {
        require(sender() == self.owner, "Incorrect sender");
        self.mintable = false;
        cashback(sender());
    }

    receive(msg: ClaimTON) {
        require(sender() == self.owner, "Incorrect sender");
        nativeReserve(minTonsForStorage, ReserveExact | ReserveBounceIfActionFail);

        // we allow bounce here and don't handle it, if claim fails we just accept the TONs back
        MessageParameters {
            bounce: true,
            to: msg.receiver,
            value: 0,
            mode: SendRemainingBalance,
        }.send();
    }

    bounced(msg: bounced<JettonTransferInternal>) {
        self.totalSupply -= msg.amount;
    }

    get fun get_jetton_data(): JettonMinterState {
        return JettonMinterState {
            totalSupply: self.totalSupply,
            mintable: self.mintable,
            adminAddress: self.owner,
            jettonContent: self.jettonContent,
            jettonWalletCode: codeOf JettonWalletSharded,
        };
    }

    get fun get_wallet_address(ownerAddress: Address): Address {
        return getJettonWalletByOwner(ownerAddress);
    }
}

inline fun getJettonWalletInit(address: Address): Cell {
    let init = initOf JettonWalletSharded(address, myAddress(), 0);

    return beginCell().storeShardedStateInit(init).endCell();
}

inline fun getJettonWalletByOwner(jettonWalletOwner: Address): Address {
    let init = getJettonWalletInit(jettonWalletOwner);

    let ownerShard = jettonWalletOwner.getShard();

    let expectedAddr = beginCell()
        .storeUint(4, 3) // addr_std$10, anycast: false
        .storeUint(0, 8) // workchain_id: 0
        .storeUint(changeShard(init.hash(), ownerShard), 256)
        .asSlice();

    return expectedAddr.loadAddress();
}

inline fun getJettonBasechainWalletByOwner(jettonWalletOwner: Address): BasechainAddress {
    let init = getJettonWalletInit(jettonWalletOwner);

    let ownerShard = jettonWalletOwner.getShard();

    return BasechainAddress { hash: changeShard(init.hash(), ownerShard) };
}