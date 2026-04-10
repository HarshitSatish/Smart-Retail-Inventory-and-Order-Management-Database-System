use supermarket;

-- 1. remove_card removes a card belonging to a specific customer
delimiter //
drop procedure if exists remove_card //

create procedure remove_card(
    in p_customer_id  int,
    in p_card_id      int
)
begin
    declare v_card_count  int default 0;

    -- exit handler
    declare exit handler for sqlexception
    begin
        rollback;
        select 'card removal failed — transaction rolled back' as message;
    end;

    -- 1: does the card exist and belong to this customer?
    select count(*) into v_card_count from card_details
		where card_id = p_card_id and customer_id = p_customer_id;

    if v_card_count = 0 then
        signal sqlstate '45000'
            set message_text = 'card not found for this customer';
    end if;

    -- delete card
    start transaction;

    delete from card_details
		where card_id = p_card_id and customer_id = p_customer_id;

    commit;

    select 'card removed successfully' as message,
            p_card_id as card_id;

end //

-- 2. remove_product_from_store removes a product from a store by deleting stores mapping and its associated inventory record
drop procedure if exists remove_product_from_store //

create procedure remove_product_from_store(
    in p_product_id  int,
    in p_store_id    int
)
begin
    declare v_inventory_id  int default null;

    -- exit handler
    declare exit handler for sqlexception
    begin
        rollback;
        select 'product removal failed — transaction rolled back' as message;
    end;

    -- check 1: does the product exist in this store?
    select s.inventory_id into v_inventory_id from stores s
		where s.product_id = p_product_id and s.store_id = p_store_id
		limit  1;

    if v_inventory_id is null then
        signal sqlstate '45000'
            set message_text = 'product not found in this store';
    end if;

    start transaction;

    -- 1: delete from stores mapping first (child table)
    delete from stores
		where product_id = p_product_id and store_id = p_store_id;

    -- 2: delete inventory record (parent table)
    delete from inventory
		where inventory_id = v_inventory_id;

    commit;

    select 'product removed from store successfully' as message,
            p_product_id as product_id,
            p_store_id as store_id;

end //
delimiter ;