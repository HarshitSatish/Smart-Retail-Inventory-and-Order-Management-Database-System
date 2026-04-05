use supermarket;

drop procedure if exists register_customer;
delimiter //
create procedure register_customer(
	in p_first_name varchar(64),
    in p_last_name varchar(64),
    in p_email varchar(64),
    in p_password varchar(64),
    in p_dob varchar(64),
    
    in p_street varchar(64),
    in p_city varchar(64),
    in p_state varchar(64),
    in p_country varchar(64),
    in p_pincode varchar(64),
    
    in p_card_fname varchar(64),
    in p_card_lname varchar(64),
    in p_last_4_digits varchar(64),
    in p_exp_date date
)
begin
	declare v_email_count int default 0;
    declare v_customer_id int;
    
    declare exit handler for sqlexception
    begin
		rollback;
        Select "Registration failed"  as message;
	end ;
    
    select count(*) into v_email_count from customer
		where email_id = p_email;
	if v_email_count > 0 then
		signal sqlstate "45000"
			set message_text = "User already exists";
	end if ;
    
    start transaction;
    insert into customer(first_name, last_name, email, password, date_of_birth) 
			values (p_first_name, p_last_name, p_email, p_password, p_dob);
	
    set v_customer_id = last_insert_id();
    
    insert into customer_address(street, city, state,country, zip_code, customer_id)
			values (p_street,p_city, p_state, p_country, p_zipcode, v_customer_id);
	
    if p_last_4_digits is not null then
        insert into card_details (first_name, last_name,last_4_digits, exp_date, customer_id)
			values (p_card_fname, p_card_lname,p_last_4_digits, p_exp_date, v_customer_id);
    end if;

    commit;
    select 'account created successfully' as message, v_customer_id as customer_id;
    
end //
delimiter ;