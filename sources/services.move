module suibiz::services;


use std::string::String;
use sui::event;
use sui::tx_context::{sender};
use sui::table::{Self, Table};

// metadata_uri has (name, description, image, status)

public struct Service has key, store {
    id: UID,
    owner: address,
    metadata_uri: String
}


 public struct ServiceCreated has copy, drop, store {
    service_id: ID,
    creator: address,
}


public struct ServiceRegistry has key {
    id: UID,
    address_to_service: Table<address, ID>,
}

public entry fun init_registry(ctx: &mut TxContext) {
    let registry = ServiceRegistry {
        id: object::new(ctx),
        address_to_service: table::new(ctx),
    };
    transfer::share_object(registry);
}

public entry fun create_service(
    registry: &mut ServiceRegistry,
    metadata_uri: String,
    ctx: &mut TxContext
) {
    let sender = sender(ctx);

    let service = Service {
        id: object::new(ctx),
        owner: sender,
        metadata_uri
    };

  

    let service_id = object::id(&service);

    table::add(&mut registry.address_to_service, sender, service_id);

    transfer::public_transfer(service, sender);

    event::emit(ServiceCreated {
        service_id,
        creator: sender
    });

}

public entry fun update_service(
    service: &mut Service,
    new_metadata_uri: String,
    ctx: &mut TxContext
) {
    let sender = sender(ctx);

    // Only the owner can update
    assert!(service.owner == sender, 0);

    service.metadata_uri = new_metadata_uri;
}

