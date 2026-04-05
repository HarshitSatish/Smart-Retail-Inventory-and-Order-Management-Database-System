use supermarket;

drop procedure if exists assign_order;

delimiter //
create procedure assign_order(
    in p_order_id   int,
    in p_manager_id int,
    in p_packer_id  int
)
begin
    -- variable declaration
    declare v_order_status      varchar(20);
    declare v_store_id          int;
    declare v_manager_store_id  int;
    declare v_packer_store_id   int;
    declare v_packer_available  varchar(5);
    declare v_old_packer_id     int default null;
    declare v_count int default 0;

    -- exit handlers
    declare exit handler for sqlexception
    begin
        rollback;
        select 'assignment failed — transaction rolled back' as message;
    end;
    
    -- validation
    -- 1: is the order confirmed and exists 
    select order_status, store_id into v_order_status, v_store_id
		from customer_order
		where order_id = p_order_id;

    if v_order_status is null then
        signal sqlstate '45000'
            set message_text = 'order not found';
    end if;

    if v_order_status != 'Confirmed' then
        signal sqlstate '45000'
            set message_text = 'order cannot be assigned — status is not confirmed';
    end if;

    -- 2: Check if the manager is in the same store
    select count(*) into v_count
		from store_manager
		where emp_id = p_manager_id;

	if v_count = 0 then
		signal sqlstate '45000'
			set message_text = 'employee is not a manager';
	end if;
		select store_id into v_manager_store_id
			from store_staff
			where emp_id = p_manager_id;

    if v_manager_store_id is null or v_manager_store_id != v_store_id then
        signal sqlstate '45000'
            set message_text = 'manager does not belong to the same store as the order';
    end if;

    -- check 3: does the packer belong to the same store as the order?
    select store_id into v_packer_store_id
		from store_staff
		where emp_id = p_packer_id;

    if v_packer_store_id is null or v_packer_store_id != v_store_id then
        signal sqlstate '45000'
            set message_text = 'packer does not belong to the same store as the order';
    end if;

    -- check 4: is the packer available?
    select availability_status
    into   v_packer_available
    from   store_staff_packer
    where  emp_id = p_packer_id;

    if v_packer_available != 'yes' then
        signal sqlstate '45000'
            set message_text = 'packer is not available for assignment';
    end if;
    
    start transaction;
    -- 1: check if assignment already exists, grab old packer id
    select packer_id
    into   v_old_packer_id
    from   order_assignment
    where  order_id = p_order_id
    limit  1;

    -- 2: if assignment exists, delete it and reset old packer availability
    if v_old_packer_id is not null then
        delete from order_assignment
        where  order_id = p_order_id;

        update store_staff_packer
        set    availability_status = 'yes'
        where  emp_id = v_old_packer_id;
    end if;

    -- 3: insert new assignment
    insert into order_assignment (
        assignment_status,
        manager_id,
        packer_id,
        order_id
    )
    values (
        'confirmed',
        p_manager_id,
        p_packer_id,
        p_order_id
    );

    -- 4: set new packer as unavailable
    update store_staff_packer
    set    availability_status = 'no'
    where  emp_id = p_packer_id;

    commit;

    -- success output
    select
        'order assigned successfully'  as message,
        p_order_id                     as order_id,
        p_manager_id                   as manager_id,
        p_packer_id                    as packer_id;

end //
delimiter ;