use supermarket;

drop function if exists low_stock_count;
delimiter //
create function low_stock_count(
    p_store_id  int
)
returns int
deterministic
reads sql data
begin
    declare v_count int default 0;

    select count(*) into v_count from inventory i
		join stores s on s.inventory_id = i.inventory_id
		where s.store_id = p_store_id
			and i.quantity_available < i.reorder_level;
    return v_count;
end //
delimiter ;