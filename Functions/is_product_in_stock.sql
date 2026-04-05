use supermarket;

drop function if exists is_product_in_stock;
delimiter //
create function is_product_in_stock(
    p_product_id  int,
    p_store_id    int,
    p_quantity    int
)
returns tinyint
deterministic
reads sql data
begin
    declare v_quantity_available int default 0;
    select i.quantity_available into v_quantity_available from inventory i
		join stores s on s.inventory_id = i.inventory_id
		where s.product_id = p_product_id
			  and s.store_id = p_store_id
		limit  1;

    -- return 1 if enough stock, 0 if not
    if v_quantity_available >= p_quantity then
        return 1;
    else
        return 0;
    end if;
end //
delimiter ;