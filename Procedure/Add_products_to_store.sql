use supermarket;

drop procedure if exists add_product_to_store;

delimiter //
create procedure add_product_to_store(
    in p_store_id       int,
    in p_product_id     int,
    in p_product_name   varchar(64),
    in p_barcode        varchar(12),
    in p_description    varchar(64),
    in p_category_id    int,        
    in p_market_price   decimal(10,2),
    in p_retail_price   decimal(10,2),
    in p_quantity       int,
    in p_reorder_level  int
)
begin
    -- variable declarations
    declare v_store_count       int default 0;
    declare v_product_count     int default 0;
    declare v_inventory_id      int;
    declare v_existing_inv_id   int default null;

    declare exit handler for sqlexception
    begin
        rollback;
        select 'failed — transaction rolled back' as message;
    end;
    -- 1: does the store exist?
    select count(*) into v_store_count from store_details
		where store_id = p_store_id;

    if v_store_count = 0 then
        signal sqlstate '45000'
            set message_text = 'store not found';
    end if;

    -- 2: if existing product, does it exist in product table?
    if p_product_id is not null then select count(*) into v_product_count from product
        where product_id = p_product_id;

        if v_product_count = 0 then
            signal sqlstate '45000'
                set message_text = 'product not found';
        end if;
    end if;

    -- 3: if new product, ensure required fields are provided
    if p_product_id is null and (
	p_product_name  is null or
        p_barcode       is null or
        p_description   is null or
        p_category_id   is null or
        p_market_price  is null or
        p_retail_price  is null
    ) then
        signal sqlstate '45000'
            set message_text = 'missing required fields for new product';
    end if;

    start transaction;

    -- 1: if new product, insert into product and product_price
    if p_product_id is null then
        insert into product ( product_name, product_barcode, product_description, category_id)
			values (p_product_name, p_barcode, p_description, p_category_id);

        set p_product_id = last_insert_id();

        insert into product_price (market_price, current_retail_price, discounted_price, is_discounted, last_update_date, product_id)
			values( p_market_price, p_retail_price, null, 'no', curdate(), p_product_id);
    end if;

    -- 2: check if product already exists in this store
    select i.inventory_id into v_existing_inv_id from inventory i
		join stores s 
			on s.inventory_id = i.inventory_id
		where s.store_id = p_store_id and s.product_id = p_product_id
    limit 1;

    -- 3: if product exists in store → update inventory quantity if not → insert inventory + stores mapping
    if v_existing_inv_id is not null then
        update inventory
				set quantity_available = quantity_available + p_quantity, last_updated = curdate()
				where inventory_id = v_existing_inv_id;

        select 'inventory quantity updated successfully' as message,
                p_product_id                            as product_id,
                p_store_id                              as store_id;
    else
        insert into inventory ( quantity_available, reorder_level, last_updated)
			values( p_quantity, p_reorder_level, curdate());

        set v_inventory_id = last_insert_id();

        insert into stores (store_id, inventory_id, product_id)
			values (p_store_id, v_inventory_id, p_product_id);

        select 'product added to store successfully' as message,
                p_product_id                         as product_id,
                p_store_id                           as store_id;
    end if;

    commit;

end //

delimiter ;