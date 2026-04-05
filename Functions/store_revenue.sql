use supermarket;

drop function if exists store_revenue;
delimiter //
create function store_revenue(
    p_store_id    int,
    p_start_date  date,
    p_end_date    date
)
returns decimal(10,2)
deterministic
reads sql data
begin
    -- variable declarations
    declare v_revenue decimal(10,2) default 0.00;
    -- sum all successful payments for confirmed orders in date range
    select coalesce(sum(p.total_amount), 0.00) into v_revenue from customer_order co
		join order_confirmation oc on oc.order_id  = co.order_id
		join payment p on p.payment_id  = oc.payment_id
			where co.store_id = p_store_id
				and co.order_status = 'Confirmed'
				and p.payment_status = 'Success'
				and co.order_date between p_start_date and p_end_date;
    return v_revenue;
end //
delimiter ;