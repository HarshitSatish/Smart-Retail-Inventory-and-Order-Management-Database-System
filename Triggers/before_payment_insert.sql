use supermarket; 

drop trigger if exists before_payment_insert;
delimiter //
create trigger before_payment_insert
before insert on payment
for each row
begin
    declare v_card_count  int default 0;

    -- 1: total amount must be greater than zero
    if new.total_amount <= 0 then
        signal sqlstate '45000'
            set message_text = 'payment amount must be greater than zero';
    end if;

    -- 2: if payment method is card based, card_id must be provided
    if new.payment_method in ('debit card', 'credit card') and new.card_id is null then
        signal sqlstate '45000'
            set message_text = 'card_id is required for debit or credit card payments';
    end if;

    -- 3: if card_id is provided, verify it exists
    if new.card_id is not null then
        select count(*)
        into   v_card_count
        from   card_details
        where  card_id = new.card_id;

        if v_card_count = 0 then
            signal sqlstate '45000'
                set message_text = 'card not found';
        end if;

        -- check 4: verify card is not expired
        if (select exp_date from card_details where card_id = new.card_id) < curdate() then
            signal sqlstate '45000'
                set message_text = 'card is expired';
        end if;
    end if;

end //
delimiter ;