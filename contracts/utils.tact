//  SPDX-License-Identifier: MIT
//  Copyright © 2025 TON Studio

asm fun checkEitherForwardPayload(forwardPayload: Slice) {
    LDDICT // Throws 9 if Either bit = 1 and ref is not present
    SWAP
    ISNULL
    <{
        DROP
    }> PUSHCONT
    <{
        ENDS // Also throws 9 if slice is not empty
    }> PUSHCONT
    IFELSE
}

asm fun emptyAddress(): Address { b{00} PUSHSLICE }

inline fun makeTakeWalletAddressMsg(targetJettonWallet: BasechainAddress, msg: ProvideWalletAddress): Cell {
    return beginCell()
        .storeUint(TakeWalletAddress.opcode(), 32)
        .storeUint(msg.queryId, 64)
        .storeBasechainAddress(targetJettonWallet)
        .storeMaybeRef(msg.includeAddress ? beginCell().storeAddress(msg.ownerAddress).endCell() : null)
        .endCell();
}

struct SliceBitsAndRefs {
    bits: Int;
    refs: Int;
}

asm fun calculateSliceBitsAndRefs(slice: Slice): SliceBitsAndRefs {
    SBITREFS
}

/// Composes Jetton metadata in a Cell.
fun composeJettonMetadata(
    // Name of the Jetton, like "Best Jetton"
    name: String,

    // Description of the Jetton, like "A very descriptive description describing the Jetton descriptively"
    description: String,

    // Symbol of the Jetton, like "USDT"
    symbol: String,

    // Image URL of the Jetton, like "https://example.com/image.png"
    image: String,


): Cell {
    let dict: map<Int as uint256, Cell> = emptyMap();
    dict.set(sha256("name"), name.asMetadataCell());
    dict.set(sha256("description"), description.asMetadataCell());
    dict.set(sha256("symbol"), symbol.asMetadataCell());
    dict.set(sha256("image"), image.asMetadataCell());

    return beginCell()
        .storeUint(0, 8)
        .storeMaybeRef(dict.asCell()!!) 
        .endCell();
}

inline extends fun asMetadataCell(self: String): Cell {
    return beginTailString().concat(self).toCell();
}