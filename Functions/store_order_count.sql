use supermarket;

drop function if exists store_order_count;
delimiter //
create function store_order_count(
    p_store_id    int,
    p_start_date  date,
    p_end_date    date
)
returns int
deterministic
reads sql data
begin
    declare v_count int default 0;

    select count(*) into v_count from customer_order
		where store_id = p_store_id
			and order_date between p_start_date and p_end_date;
    return v_count;
end //
delimiter ;