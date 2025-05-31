module suibiz::user {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
   use sui::table::{Self, Table, new, add, contains, borrow};
    use sui::transfer;
    use sui::event;
    use std::option::{Self, Option};


    public struct UserProfile has key, store {
        id: UID,
        name: vector<u8>,
        username: vector<u8>,
        bio: vector<u8>,
        avatar_url: vector<u8>,
        business_address: vector<u8>,
        owner: address,
    }

    public struct ProfileIdEvent has copy, drop, store {
        id: ID,
    }

    public struct ProfileRegistry has key {
        id: UID,
        address_to_profile: Table<address, ID>,
    }

    public fun init_registry(ctx: &mut TxContext) {
        let registry = ProfileRegistry {
            id: object::new(ctx),
            address_to_profile: table::new(ctx),
        };
        transfer::share_object(registry);
    }

    public entry fun create_profile(
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
        transfer::transfer(profile, sender);
        event::emit(ProfileIdEvent { id: profile_id });
    }

    // public fun get_profile_id(
    //     registry: &ProfileRegistry,
    //     user: address
    // ): ID {
    //     *table::borrow(&registry.address_to_profile, user)
    // }

   public fun get_profile_id_by_owner(
        registry: &ProfileRegistry,
        owner: address
    ): Option<ID> {
        if (!contains(&registry.address_to_profile, owner)) {
            return option::none<ID>();
        };
        option::some(*borrow(&registry.address_to_profile, owner))
    }

}