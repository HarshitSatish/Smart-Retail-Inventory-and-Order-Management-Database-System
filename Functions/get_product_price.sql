use supermarket;

drop function if exists get_product_price;
delimiter //
create function get_product_price(
    p_product_id  int
)
returns decimal(10,2)
deterministic
reads sql data
begin
    declare v_price decimal(10,2) default null;
    select case
               when is_discounted = 'yes' then discounted_price
               else current_retail_price
           end
		into v_price
		from product_price
			where product_id = p_product_id
		order by last_update_date desc
		limit  1;
    return v_price;

end //
delimiter ;