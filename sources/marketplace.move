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
        collection: String
    }

    public struct Marketplace has key {
        id: UID,
        fee_percentage: u64,
        fee_recipient: address,
        products_count: u64
    }

    public struct MARKETPLACE has drop {}

    // ========== Events ==========

    public struct ProductListed has copy, drop {
        product_id: String,
        owner: address,
        price: u64,
        collection: String
    }

    public struct ProductPurchased has copy, drop {
        product_id: String,
        buyer: address,
        seller: address,
        price: u64
    }



    const MAX_FEE_PERCENTAGE: u64 = 10;


    fun init(
        _witness: MARKETPLACE,
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

    // ========== Core Functions ==========

    public entry fun list_product( 
        marketplace: &mut Marketplace,
        product_id: String,
        price: u64,
        collection: String,
        ctx: &mut TxContext
    ) {
        assert!(price > 0, 1);

        let product = Product {
            id: object::new(ctx),
            product_id,
            owner: tx_context::sender(ctx),
            price,
            is_listed: true,
            collection
        };

        marketplace.products_count = marketplace.products_count + 1;
        transfer::transfer(product, tx_context::sender(ctx));

        event::emit(ProductListed {
            product_id,
            owner: tx_context::sender(ctx),
            price,
            collection
        });
    }

    public entry fun purchase_product(
        marketplace: &mut Marketplace,
        product: &mut Product,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(product.is_listed, 2);
        assert!(coin::value(&payment) >= product.price, 3);

        let buyer = tx_context::sender(ctx);
        let seller = product.owner;
        let price = product.price;
        let fee_amount = price * marketplace.fee_percentage / 100;
        let seller_amount = price - fee_amount;

        // Split payment into seller and fee portions
        let mut payment_balance = coin::into_balance(payment);
        let fee_balance = balance::split(&mut payment_balance, fee_amount);
        let seller_coin = coin::from_balance(payment_balance, ctx);
        let fee_coin = coin::from_balance(fee_balance, ctx);
        
        transfer::public_transfer(seller_coin, seller);
        transfer::public_transfer(fee_coin, marketplace.fee_recipient);

        // Transfer product ownership
        product.owner = buyer;
        product.is_listed = false;

        event::emit(ProductPurchased {
            product_id: product.product_id,
            buyer,
            seller,
            price
        });
    }

    // ========== Utility Functions ==========

    public entry fun update_price(
        product: &mut Product,
        new_price: u64,
        _ctx: &mut TxContext
    ) {
        assert!(product.is_listed, 4);
        assert!(new_price > 0, 5);
        product.price = new_price;
    }

    public entry fun delist_product(
        product: &mut Product,
        _ctx: &mut TxContext
    ) {
        product.is_listed = false;
    }
}