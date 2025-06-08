#[allow(lint(coin_field))]
module suibiz::marketplace;

use sui::coin::{Coin, split, value};
use sui::sui::SUI;
use sui::event;
use std::string;
use std::string::String;
use sui::kiosk::{Self as kiosk, Kiosk, KioskOwnerCap};
use sui::tx_context::{sender};
use sui::vec_map::{Self, VecMap};


    public struct Store has key, store {
        id: UID,
        kiosk_id: ID,
        name: String,
        owner: address,
        metadata_uri: String
    }

    // Registry that tracks all stores
    public struct StoreRegistry has key {
        id: UID,
        stores: VecMap<ID, ID> // Map of kiosk_id to store_id
    }

    // Initialize the registry (call once)
    public entry fun init_registry(ctx: &mut TxContext) {
        transfer::share_object(StoreRegistry {
            id: object::new(ctx),
            stores: vec_map::empty()
        });
    }

    // Create a new store with a kiosk
    public entry fun create_store(
        registry: &mut StoreRegistry,
        name: String,
        metadata_uri: String,
        ctx: &mut TxContext
    ) {
        // Create kiosk
        let (kiosk, cap) = kiosk::new(ctx);
        let kiosk_id = object::id(&kiosk);

        let store_owner = sender(ctx);

        
        // Create store object
        let store = Store {
            id: object::new(ctx),
            kiosk_id: kiosk_id,
            name,
            owner: store_owner,
            metadata_uri
            
        };
        let store_id = object::id(&store);
        
        // Add to kiosk and store registry
        vec_map::insert(
            &mut registry.stores, 
            kiosk_id, 
            store_id
        );
        
        // Share kiosk and transfer assets
        transfer::public_share_object(kiosk);
        transfer::public_transfer(cap, sender(ctx));
        transfer::public_transfer(store, sender(ctx));
    }

    // Get store by kiosk ID (view function)
    public fun get_store(registry: &StoreRegistry, kiosk_id: ID): Option<ID> {
        if (vec_map::contains(&registry.stores, &kiosk_id)) {
            option::some(*vec_map::get(&registry.stores, &kiosk_id))
        } else {
            option::none()
        }
    }

    public struct ProductCreatedEvent has copy, drop {
        product_type_id: ID,
        creator: address,
        kiosk_id: ID
    }


 ///  Product


 public struct ProductType has key, store {
        id: UID,
        metadata_uri: String,  // Points to off-chain JSON
        price: u64,            
        total_units: u64,      
        sold_units: u64,   
        creator: address, 
        kiosk_id: ID,      
        available_items: vector<ID>
    }

 /// Represents each unique product unit (NFT)
 public struct ProductItem has key, store {
        id: UID,
        product_type: ID,
        owner: address,
        status: u8,
    }


   public struct Order has key, store {
    id: UID,
    product_type: ID,
    items: vector<ID>,
    owner: address,
    seller: address,
    status: String,
    escrow_id: ID
}

public struct Escrow has key, store {
    id: UID,
    amount: u64,
    payment: Coin<SUI>,
    seller: address,
    buyer: address,
    released: bool
}

    public struct OrderCreatedEvent has copy, drop {
        order_id: ID,
        creator: address,
        seller: address,
    }


const EORDER_NOT_PAID: u64 = 10;
// const EORDER_ALREADY_COMPLETED: u64 = 11;
const EINVALID_OWNER: u64 = 12;
const EESCROW_ALREADY_RELEASED: u64 = 13;
const EESCROW_AMOUNT_MISMATCH: u64 = 5;
// const EESCROW_PAYMENT_MISMATCH: u64 = 6;


/// Create product type & mint initial items
    public entry fun create_product_type(
        metadata_uri: String,
        price: u64,
        initial_quantity: u64,
        kiosk: &mut Kiosk,
        kiosk_cap: &KioskOwnerCap,
        ctx: &mut TxContext
    ) {
        let sender_addr = sender(ctx);

        // Create the product type
        let mut product_type = ProductType {
            id: object::new(ctx),
            metadata_uri,
            price,
            total_units: initial_quantity,
            sold_units: 0,
            creator: sender_addr,
            kiosk_id: object::id(kiosk),
            available_items: vector::empty()
        };

        

        // Mint items and place into kiosk
        let mut i = 0;
        while (i < initial_quantity) {
            let item = ProductItem {
                id: object::new(ctx),
                product_type: object::id(&product_type),
                owner: sender_addr,
                status: 0
            };
            let item_id = object::id(&item);
        
        vector::push_back(&mut product_type.available_items, item_id);

            kiosk::place(kiosk, kiosk_cap, item);
            i = i + 1;
        };



            event::emit(ProductCreatedEvent {
                product_type_id: object::id(&product_type),
                creator: sender(ctx),
                kiosk_id: object::id(kiosk)
            });

                    transfer::share_object(product_type);

    }


const EINSUFFICIENT_PAYMENT: u64 = 0;
const EINSUFFICIENT_STOCK: u64 = 1;

public entry fun purchase_multiple_items(
    product_type: &mut ProductType,
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    quantity: u64,
    payment: &mut Coin<SUI>,
    ctx: &mut TxContext
) {
    let buyer = sender(ctx);
    let total_price = product_type.price * quantity;

    // Check payment
    assert!(value(payment) >= total_price, EINSUFFICIENT_PAYMENT);

    // Check stock
    assert!(
        product_type.total_units - product_type.sold_units >= quantity,
        EINSUFFICIENT_STOCK
    );

    let mut i = 0;
    while (i < quantity) {


         let item_id = vector::pop_back(&mut product_type.available_items);


        let item: ProductItem = kiosk::take(kiosk, kiosk_cap, item_id);
        transfer::public_transfer(item, buyer);
        i = i + 1;
    };

    product_type.sold_units = product_type.sold_units + quantity;

    let seller_share = split(payment, total_price, ctx);
    transfer::public_transfer(seller_share, product_type.creator);
}


public entry fun create_order(
    product_type: &mut ProductType,
    quantity: u64,
    payment: &mut Coin<SUI>,
    ctx: &mut TxContext
) {
    let buyer = sender(ctx);
    let total_price = product_type.price * quantity;

    // Validate payment and stock
    assert!(value(payment) >= total_price, EINSUFFICIENT_PAYMENT);
    assert!(product_type.total_units - product_type.sold_units >= quantity, EINSUFFICIENT_STOCK);

    // Create escrow
    let payment_coin = split(payment, total_price, ctx);
    let escrow = Escrow {
        id: object::new(ctx),
        amount: total_price,
        payment: payment_coin,
        seller: product_type.creator,
        buyer,
        released: false
    };

    // Reserve items
    let mut items = vector::empty();
    let mut i = 0;
    while (i < quantity) {
        let item_id = vector::pop_back(&mut product_type.available_items);
        vector::push_back(&mut items, item_id);
        i = i + 1;
    };

    // Create order 
    let product_type_id = object::id(product_type);
    let order = Order {
        id: object::new(ctx),
        product_type: product_type_id,
        items,
        owner: buyer,
        seller: product_type.creator,
        status: string::utf8(b"paid"),
        escrow_id: object::id(&escrow)
    };

    // Update inventory
    product_type.sold_units = product_type.sold_units + quantity;

     event::emit(OrderCreatedEvent {
        order_id: object::id(&order),
        creator: buyer,
        seller: product_type.creator
    });

     transfer::share_object(escrow);
      transfer::share_object(order);

   
}

public entry fun mark_received(
    order: &mut Order,
    ctx: &mut TxContext
) {
    assert!(sender(ctx) == order.owner, EINVALID_OWNER);
    assert!(string::utf8(b"paid") == order.status, EORDER_NOT_PAID);
    
    order.status = string::utf8(b"received");
}

public entry fun release_items_and_funds(
    order: &mut Order,
    escrow: &mut Escrow,
    kiosk: &mut Kiosk,
    kiosk_cap: &KioskOwnerCap,
    ctx: &mut TxContext
) {
   // Validate
    
    let buyer = order.owner;
    let seller = order.seller;
    assert!(sender(ctx) == seller, EINVALID_OWNER);
    assert!(string::utf8(b"received") == order.status, EORDER_NOT_PAID);
    assert!(!escrow.released, EESCROW_ALREADY_RELEASED);
    assert!(order.escrow_id == object::id(escrow), 0);

    // Transfer items

    let mut items_copy = vector::empty();
    let mut i = 0;
    while (i < vector::length(&order.items)) {
        let item_id = *vector::borrow(&order.items, i);
        vector::push_back(&mut items_copy, item_id);
        i = i + 1;
    };

    // Process items
    while (!vector::is_empty(&items_copy)) {
        let item_id = vector::pop_back(&mut items_copy);
        let item: ProductItem = kiosk::take(kiosk, kiosk_cap, item_id);
        transfer::public_transfer(item, buyer);
    };

    // Handle payment
    let payment = &mut escrow.payment;
    let payment_value = value(payment);
    assert!(payment_value == escrow.amount, EESCROW_AMOUNT_MISMATCH);
    
    // Split payment to transfer exact amount
    let payment_to_transfer = split(payment, escrow.amount, ctx);
    transfer::public_transfer(payment_to_transfer, seller);

    // Update metadata
    // let timestamp = tx_context::epoch(ctx);
    // escrow.released_at = timestamp;
    // order.is_completed = true;
    // order.completed_at = timestamp;

    escrow.released = true;

    order.status = string::utf8(b"completed");


    // event::emit(OrderCompletedEvent {
    //     order_id: object::id(order),
    //     escrow_id: object::id(escrow),
    //     seller,
    //     buyer,
    //     amount: escrow.amount,
    //     timestamp
    // });

}


