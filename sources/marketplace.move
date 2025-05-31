module suibiz::marketplace {
    use sui::tx_context::TxContext;
    use sui::event;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use std::string::String;
    use sui::object::UID;
    use sui::transfer;

    public struct Product has key, store {
        id: UID,
        product_id: String,
        owner: address,
        price: u64,
        is_listed: bool,
        collection: String,
        name: String,
        description: String,
        quantity: u64,
        image_url: String
    }

    public struct PurchasedProduct has key, store {
        id: UID,
        original_product_id: String,
        owner: address,
        purchased_quantity: u64,
        unit_price: u64,
        collection: String,
        name: String,
        description: String,
        image_url: String
    }

    public struct Marketplace has key {
        id: UID,
        fee_percentage: u64,
        fee_recipient: address,
        products_count: u64
    }

    public struct MARKETPLACE has drop {}


    public struct ProductListed has copy, drop {
        product_id: String,
        owner: address,
        price: u64,
        collection: String,
        quantity: u64,
        name: String,
        description: String,
        image_url: String
    }

    public struct ProductPurchased has copy, drop {
        product_id: String,
        buyer: address,
        seller: address,
        quantity: u64,
        unit_price: u64,
        total_price: u64
    }

    const MAX_FEE_PERCENTAGE: u64 = 10;

    public entry fun create_and_init_marketplace(
    ctx: &mut TxContext
) {
    let fee_percentage = 2;
    let fee_recipient = tx_context::sender(ctx);
    
    assert!(fee_percentage <= MAX_FEE_PERCENTAGE, 0);
    
    let marketplace = Marketplace {
        id: object::new(ctx),
        fee_percentage,
        fee_recipient,
        products_count: 0
    };

    transfer::share_object(marketplace);
}


    public entry fun list_product( 
        marketplace: &mut Marketplace,
        product_id: String,
        price: u64,
        collection: String,
        name: String,
        description: String,
        image_url: String,
        quantity: u64,
        ctx: &mut TxContext
    ) {
        assert!(price > 0, 1);
        assert!(quantity > 0, 2);

        let product = Product {
            id: object::new(ctx),
            product_id: copy product_id,
            owner: tx_context::sender(ctx),
            price,
            name: copy name,
            description: copy description,
            image_url: copy image_url,
            quantity,
            is_listed: true,
            collection: copy collection
        };

        marketplace.products_count = marketplace.products_count + 1;
        transfer::transfer(product, tx_context::sender(ctx));

        event::emit(ProductListed {
            product_id,
            owner: tx_context::sender(ctx),
            price,
            collection,
            quantity,
            name,
            description,
            image_url
        });
    }

    public entry fun purchase_product(
        marketplace: &mut Marketplace,
        product: &mut Product,
        quantity_to_purchase: u64,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(product.is_listed, 3);
        assert!(quantity_to_purchase > 0, 4);
        assert!(product.quantity >= quantity_to_purchase, 5);
        
        let total_price = product.price * quantity_to_purchase;
        assert!(coin::value(&payment) >= total_price, 6);

        let buyer = tx_context::sender(ctx);
        let seller = product.owner;
        let fee_amount = total_price * marketplace.fee_percentage / 100;
        let seller_amount = total_price - fee_amount;

        // Split payment into seller and fee portions
        let mut payment_balance = coin::into_balance(payment);
        let fee_balance = balance::split(&mut payment_balance, fee_amount);
        let seller_coin = coin::from_balance(payment_balance, ctx);
        let fee_coin = coin::from_balance(fee_balance, ctx);
        
        transfer::public_transfer(seller_coin, seller);
        transfer::public_transfer(fee_coin, marketplace.fee_recipient);

        product.quantity = product.quantity - quantity_to_purchase;
        
        let purchased_product = PurchasedProduct {
            id: object::new(ctx),
            original_product_id: product.product_id,
            owner: buyer,
            purchased_quantity: quantity_to_purchase,
            unit_price: product.price,
            collection: product.collection,
            name: product.name,
            description: product.description,
            image_url: product.image_url
        };

        transfer::transfer(purchased_product, buyer);

        event::emit(ProductPurchased {
            product_id: product.product_id,
            buyer,
            seller,
            quantity: quantity_to_purchase,
            unit_price: product.price,
            total_price
        });

        if (product.quantity == 0) {
            product.is_listed = false;
        }
    }


    public entry fun update_price(
        product: &mut Product,
        new_price: u64,
        _ctx: &mut TxContext
    ) {
        assert!(product.is_listed, 7);
        assert!(new_price > 0, 8);
        product.price = new_price;
    }

    public entry fun delist_product(
        product: &mut Product,
        _ctx: &mut TxContext
    ) {
        product.is_listed = false;
    }

    public entry fun add_quantity(
        product: &mut Product,
        additional_quantity: u64,
        _ctx: &mut TxContext
    ) {
        assert!(additional_quantity > 0, 9);
        product.quantity = product.quantity + additional_quantity;
        if (!product.is_listed) {
            product.is_listed = true;
        }
    }
}