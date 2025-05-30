module suibiz::user {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::table::{Self, Table};
    use sui::transfer;

    public struct UserProfile has key, store {
        id: UID,
        name: vector<u8>,
        username: vector<u8>,
        bio: vector<u8>,
        avatar_url: vector<u8>,
        business_address: vector<u8>,
        owner: address,
    }

    public struct ProfileRegistry has key, store {  // Added 'store' ability
        id: UID,
        address_to_profile: Table<address, ID>,
    }

    public fun init_registry(ctx: &mut TxContext) {
        let registry = ProfileRegistry {
            id: object::new(ctx),
            address_to_profile: table::new(ctx),
        };
        transfer::public_transfer(registry, tx_context::sender(ctx));
    }

   public fun create_user_profile(
    registry: &mut ProfileRegistry,
    name: vector<u8>,
    username: vector<u8>,
    bio: vector<u8>,
    avatar_url: vector<u8>,
    business_address: vector<u8>,
    ctx: &mut TxContext
) {
    let sender = tx_context::sender(ctx);
    let profile = UserProfile {
        id: object::new(ctx),
        name,
        username,
        bio,
        avatar_url,
        business_address,
        owner: sender,
    };
    let profile_id = object::id(&profile);
    table::add(&mut registry.address_to_profile, sender, profile_id);

    transfer::public_transfer(profile, sender); // ✅ transfer instead of return
}


    public fun get_profile_id(
        registry: &ProfileRegistry,
        user: address
    ): ID {
        *table::borrow(&registry.address_to_profile, user)
    }
}