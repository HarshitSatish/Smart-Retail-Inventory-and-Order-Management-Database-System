use supermarket;

drop function if exists packer_order_count;
delimiter //
create function packer_order_count(
    p_packer_id   int,
    p_start_date  date,
    p_end_date    date
)
returns int
deterministic
reads sql data
begin
    -- variable declarations
    declare v_order_count int default 0;
    -- count all orders assigned to this packer in date range
    select count(*) into v_order_count from order_assignment oa
		join customer_order co on co.order_id = oa.order_id
		where oa.packer_id = p_packer_id
			and co.order_date between p_start_date and p_end_date;
    return v_order_count;

end //
delimiter ;