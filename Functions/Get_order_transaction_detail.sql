use supermarket;

drop function if exists get_order_transaction_total;

delimiter //
create function get_order_transaction_total(
    p_customer_id  int,
    p_order_id     int
)
returns decimal(10,2)
deterministic
reads sql data
begin
    -- variable declarations
    declare v_total decimal(10,2) default null;
    -- fetch total amount where both order and payment are successful
    select p.total_amount into v_total from customer_order co
		join order_confirmation oc on oc.order_id = co.order_id
		join payment p on p.payment_id = oc.payment_id
		where co.order_id = p_order_id
				and co.customer_id = p_customer_id
				and co.order_status  = 'Confirmed'
				and p.payment_status = 'Success'
		limit 1;

    return v_total;
end //
delimiter ;