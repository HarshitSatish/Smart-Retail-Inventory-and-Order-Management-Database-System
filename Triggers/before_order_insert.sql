use supermarket;

drop trigger if exists before_order_insert;
delimiter //
create trigger before_order_insert
before insert on customer_order
for each row
begin
    declare v_customer_count  int default 0;
    declare v_store_count     int default 0;

    -- 1: does the customer exist?
    select count(*) into v_customer_count from customer
		where customer_id = new.customer_id;

    if v_customer_count = 0 then
        signal sqlstate '45000'
            set message_text = 'customer not found';
    end if;

    -- 2: does the store exist?
    select count(*) into v_store_count from store_details
		where store_id = new.store_id;

    if v_store_count = 0 then
        signal sqlstate '45000'
            set message_text = 'store not found';
    end if;

end //
delimiter ;