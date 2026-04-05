use supermarket;

drop procedure if exists apply_discount //


delimiter //
create procedure apply_discount(
    in p_product_id       int,
    in p_store_id         int,
    in p_discounted_price decimal(10,2)
)
begin
    -- variable declarations
    declare v_retail_price  decimal(10,2);
    declare v_store_count   int default 0;

    -- exit handler
    declare exit handler for sqlexception
    begin
        rollback;
        select 'discount failed — transaction rolled back' as message;
    end;

    -- 1: does the product exist in this store?
    select count(*) into v_store_count from stores
		where product_id = p_product_id and store_id = p_store_id;

    if v_store_count = 0 then
        signal sqlstate '45000'
            set message_text = 'product not found in this store';
    end if;

    -- 2: get current retail price and validate discount
    select current_retail_price into v_retail_price from product_price
		where product_id = p_product_id
		order by last_update_date desc
		limit 1;

    if p_discounted_price >= v_retail_price then
        signal sqlstate '45000'
            set message_text = 'discounted price must be less than current retail price';
    end if;

    if p_discounted_price <= 0 then
        signal sqlstate '45000'
            set message_text = 'discounted price must be greater than zero';
    end if;

    start transaction;
    -- 1: update product_price
    update product_price
		set discounted_price  = p_discounted_price,
            is_discounted     = 'yes',
            last_update_date  = curdate()
		where product_id = p_product_id;

    commit;

    -- success output
    select
        'discount applied successfully'  as message,
        p_product_id                     as product_id,
        p_store_id                       as store_id,
        v_retail_price                   as original_price,
        p_discounted_price               as discounted_price,
        round((v_retail_price - p_discounted_price) / v_retail_price * 100, 2) as discount_percentage;

end //
delimiter ;