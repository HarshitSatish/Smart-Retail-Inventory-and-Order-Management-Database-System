use supermarket;

drop procedure if exists cancel_order;
delimiter //
create procedure cancel_order(
	in p_order_id int
)
begin
	-- variable declaration
	declare v_order_status      varchar(20);
    declare v_store_id          int;
    declare v_assignment_count  int default 0;
    
    -- defining exit hnadlers
    declare exit handler for sqlexception
    begin
		rollback;
        select 'cancel failed' as message;
	end;
    
    -- validation
    -- 1. checking if the order_id exists
    select order_status, store_id
    into   v_order_status, v_store_id
    from   customer_order
    where  order_id = p_order_id;

    if v_order_status is null then
        signal sqlstate '45000'
            set message_text = 'order not found';
    end if;
    
    -- 2. is the order already cancelled or failed
    if v_order_status in ('Cancelled', 'Failed') then
        signal sqlstate '45000'
            set message_text = 'order cannot be cancelled';
    end if;
    
    -- 3: check if the order is assigned to a packer
    select count(*)
    into   v_assignment_count
    from   order_assignment
    where  order_id = p_order_id;

    if v_assignment_count > 0 then
        signal sqlstate '45000'
            set message_text = 'order cannot be cancelled';
    end if;
    
    start transaction;
    -- 1: update order status
    update customer_order
		set order_status = 'Cancelled'
		where order_id = p_order_id;

    -- 2: update order confirmation
    update order_confirmation
		set confirmation_status = 'not confirmed'
		where order_id = p_order_id;

    -- 3: update payment status
    update payment p
		join order_confirmation oc on oc.payment_id = p.payment_id
			set p.payment_status = 'Failed'
			where oc.order_id = p_order_id;

    -- 4: revert inventory order_items → stores → inventory
    update inventory i
		join stores s on s.inventory_id = i.inventory_id
		join order_items o on o.product_id = s.product_id and s.store_id = v_store_id
			set i.quantity_available = i.quantity_available + o.quantity,
					i.last_updated = curdate()
			where  o.order_id = p_order_id;
    commit;
    
    -- success output
    select
        'order cancelled successfully' as message,
        p_order_id as order_id;

end //
delimiter ;
