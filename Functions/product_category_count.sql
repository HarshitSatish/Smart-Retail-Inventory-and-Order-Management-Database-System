use supermarket;

drop function if exists category_product_count;

delimiter //
create function category_product_count(
    p_category_id  int
)
returns int
deterministic
reads sql data
begin
    declare v_count int default 0;

    select count(*) into v_count from product
		where category_id = p_category_id;

    return v_count;

end //
delimiter ;