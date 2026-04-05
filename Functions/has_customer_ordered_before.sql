use supermarket;

drop function if exists has_customer_ordered_before;
delimiter //
create function has_customer_ordered_before(
    p_customer_id  int
)
returns tinyint
deterministic
reads sql data
begin
    declare v_count int default 0;

    select count(*) into v_count from customer_order
		where customer_id = p_customer_id
				and order_status  = 'Confirmed';
    if v_count > 0 then
        return 1;
    else
        return 0;
    end if;

end //
delimiter ;

