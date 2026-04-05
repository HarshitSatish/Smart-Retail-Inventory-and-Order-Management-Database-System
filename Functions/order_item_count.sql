use supermarket;

drop function if exists order_item_count;

delimiter //
create function order_item_count(
    p_order_id  int
)
returns int
deterministic
reads sql data
begin
    declare v_count int default 0;

    select coalesce(sum(quantity), 0) into v_count from order_items
		where order_id = p_order_id;

    return v_count;
end //
delimiter ;
