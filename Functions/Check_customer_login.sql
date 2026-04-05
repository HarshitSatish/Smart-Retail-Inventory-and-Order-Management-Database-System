use supermarket;

drop function if exists check_customer_login;

delimiter //
create function check_customer_login(
    p_email     varchar(64),
    p_password  varchar(64)
)
returns int
deterministic
reads sql data
begin
    -- variable declarations
    declare v_customer_id int default null;
    -- fetch customer_id if credentials match
    select customer_id into v_customer_id from customer
		where email = p_email
			  and password = p_password
		limit  1;
    return v_customer_id;
end //
delimiter ;