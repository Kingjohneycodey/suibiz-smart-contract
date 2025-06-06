module suibiz::user;
    use std::string::String;
    use sui::table::{Self, Table};
    use sui::event;


    public struct UserProfile has key, store {
        id: UID,
        metadata_uri: String,
        role: String,
        owner: address,
    }

    public struct ProfileIdEvent has copy, drop, store {
        id: ID,
        role: String,
    }

    public struct ProfileInfo has copy, drop, store {
    id: ID,
    role: String,
}

    public struct ProfileRegistry has key {
        id: UID,
        address_to_profile: Table<address, ProfileInfo>,
    }

    public entry fun init_registry(ctx: &mut TxContext) {
        let registry = ProfileRegistry {
            id: object::new(ctx),
            address_to_profile: table::new(ctx),
        };
        transfer::share_object(registry);
    }

    public entry fun create_profile(
        registry: &mut ProfileRegistry,
        metadata_uri: String,
        role: String,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let profile = UserProfile {
            id: object::new(ctx),
            metadata_uri,
            role,
            owner: sender,
        };

        let profile_id = object::id(&profile);
        let info = ProfileInfo { id: profile_id, role };
     table::add(&mut registry.address_to_profile, sender, info);
        transfer::transfer(profile, sender);
        event::emit(ProfileIdEvent { id: profile_id, role });
    }
