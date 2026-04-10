use supermarket;

drop trigger if exists before_inventory_update;
delimiter //
create trigger before_inventory_update
before update on inventory
for each row
begin
    -- 1: block negative quantity
    if new.quantity_available < 0 then
        signal sqlstate '45000'
            set message_text = 'inventory quantity cannot be negative';
    end if;

    -- 2: block negative reorder level
    if new.reorder_level < 0 then
        signal sqlstate '45000'
            set message_text = 'reorder level cannot be negative';
    end if;

    -- 3: auto set last_updated to today on every update
    set new.last_updated = curdate();

end //
delimiter ;