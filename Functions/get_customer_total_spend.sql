use supermarket;

drop function if exists customer_total_spend //
delimiter //
create function customer_total_spend(
    p_customer_id  int
)
returns decimal(10,2)
deterministic
reads sql data
begin
    declare v_total_spend decimal(10,2) default 0.00;
    -- sum all successful payments for confirmed orders
    select coalesce(sum(p.total_amount), 0.00) into v_total_spend from customer_order co
		join order_confirmation oc on oc.order_id   = co.order_id
		join payment p on p.payment_id = oc.payment_id
		where co.customer_id = p_customer_id
			  and co.order_status  = 'Confirmed'
			  and p.payment_status = 'Success';
    return v_total_spend;
end //
delimiter ;