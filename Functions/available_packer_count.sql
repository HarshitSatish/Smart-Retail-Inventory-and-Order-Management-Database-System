use supermarket;

drop function if exists available_packer_count;
delimiter //
create function available_packer_count(
    p_store_id  int
)
returns int
deterministic
reads sql data
begin
    declare v_count int default 0;

    select count(*) into v_count from store_staff_packer sp
		join store_staff ss on ss.emp_id = sp.emp_id
		where ss.store_id = p_store_id
			and sp.availability_status = 'yes';
    return v_count;
end //
delimiter ;
