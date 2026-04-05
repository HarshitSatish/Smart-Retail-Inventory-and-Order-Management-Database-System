use supermarket;

drop function if exists check_manager_login;
drop function if exists check_packer_login;
delimiter //
create function check_manager_login(
    p_username  varchar(64),
    p_password  varchar(64)
)
returns int
deterministic
reads sql data
begin
    declare v_emp_id int default null;
    select ss.emp_id into v_emp_id from store_staff ss
		join store_manager sm 
			on sm.emp_id = ss.emp_id
		where ss.username = p_username
				and ss.password = p_password
		limit  1;
    return v_emp_id;
end //

create function check_packer_login(
    p_username  varchar(64),
    p_password  varchar(64)
)
returns int
deterministic
reads sql data
begin
    declare v_emp_id int default null;

    select ss.emp_id into v_emp_id from store_staff ss
		join store_staff_packer sp on sp.emp_id = ss.emp_id
		where ss.username = p_username
				and ss.password = p_password
		limit  1;
    return v_emp_id;

end //
delimiter ;