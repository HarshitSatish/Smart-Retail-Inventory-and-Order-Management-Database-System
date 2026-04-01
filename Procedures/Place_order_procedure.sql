use supermarket;
DELIMITER //

DROP PROCEDURE IF EXISTS place_order //

CREATE PROCEDURE place_order(
    IN p_customer_id      INT,
    IN p_store_id         INT,
    IN p_order_type       ENUM('Pickup', 'Delivery'),
    IN p_payment_method   ENUM('debit card','credit card','paypal','apple pay','google pay'),
    IN p_card_id          INT,    -- NULL if paypal / apple pay / google pay
    IN p_items            TEXT   -- format: "product_id:quantity,product_id:quantity"
)
BEGIN
    -- ----------------------------------------------------------------
    -- Variable declarations
    -- ----------------------------------------------------------------
    DECLARE done          INT           DEFAULT 0;
    DECLARE v_product_id  INT;
    DECLARE v_quantity    INT;
    DECLARE v_price       DECIMAL(10,2);
    DECLARE v_stock       INT;
    DECLARE v_inv_id      INT;
    DECLARE v_total       DECIMAL(10,2) DEFAULT 0;
    DECLARE v_order_id    INT;
    DECLARE v_payment_id  INT;

    -- String parsing variables
    DECLARE v_remaining   TEXT;
    DECLARE v_item        TEXT;
    DECLARE v_comma_pos   INT;
    DECLARE v_colon_pos   INT;

    -- Cursor reads from the internal temp table
    DECLARE item_cursor CURSOR FOR
        SELECT product_id, quantity FROM temp_order_items;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Exit handler: any SQL exception triggers full rollback
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Clean up temp table if it exists before rolling back
        DROP TEMPORARY TABLE IF EXISTS temp_order_items;
        ROLLBACK;
        SELECT 'ORDER FAILED — transaction rolled back' AS message;
    END;

    -- ----------------------------------------------------------------
    -- Step 1: Parse input string into internal temp table
    -- "1:2,5:1,36:3"  →  rows (1,2), (5,1), (36,3)
    -- ----------------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS temp_order_items;

    CREATE TEMPORARY TABLE temp_order_items (
        product_id INT NOT NULL,
        quantity   INT NOT NULL
    );

    SET v_remaining = p_items;

    parse_loop: LOOP
        IF v_remaining = '' OR v_remaining IS NULL THEN
            LEAVE parse_loop;
        END IF;

        -- Isolate one token (everything before the next comma)
        SET v_comma_pos = LOCATE(',', v_remaining);

        IF v_comma_pos = 0 THEN
            SET v_item      = v_remaining;
            SET v_remaining = '';
        ELSE
            SET v_item      = SUBSTRING(v_remaining, 1, v_comma_pos - 1);
            SET v_remaining = SUBSTRING(v_remaining, v_comma_pos + 1);
        END IF;

        -- Split token by colon  →  product_id : quantity
        SET v_colon_pos  = LOCATE(':', v_item);
        SET v_product_id = CAST(SUBSTRING(v_item, 1, v_colon_pos - 1) AS UNSIGNED);
        SET v_quantity   = CAST(SUBSTRING(v_item, v_colon_pos + 1)    AS UNSIGNED);

        INSERT INTO temp_order_items VALUES (v_product_id, v_quantity);

    END LOOP parse_loop;

    -- ----------------------------------------------------------------
    -- Step 2: Begin transaction
    -- ----------------------------------------------------------------
    START TRANSACTION;

    -- Step 3: Create the order record
    INSERT INTO customer_order (
        order_type, order_time, order_date,
        order_status, customer_id, store_id
    )
    VALUES (
        p_order_type, CURTIME(), CURDATE(),
        'Confirmed', p_customer_id, p_store_id
    );

    SET v_order_id = LAST_INSERT_ID();

    -- ----------------------------------------------------------------
    -- Step 4: Process each item via cursor
    -- ----------------------------------------------------------------
    OPEN item_cursor;

    read_loop: LOOP
        FETCH item_cursor INTO v_product_id, v_quantity;

        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Get inventory_id and lock the row for this store + product
        SELECT i.inventory_id, i.quantity_available
        INTO   v_inv_id, v_stock
        FROM   inventory i
        JOIN   stores s ON s.inventory_id = i.inventory_id
        WHERE  s.store_id   = p_store_id
          AND  s.product_id = v_product_id
        LIMIT 1
        FOR UPDATE;

        -- Check sufficient stock
        IF v_stock < v_quantity THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Insufficient stock for one or more products';
        END IF;

        -- Get current price (discounted if applicable)
        SELECT CASE
                   WHEN is_discounted = 'yes' THEN discounted_price
                   ELSE current_retail_price
               END
        INTO   v_price
        FROM   product_price
        WHERE  product_id = v_product_id
        ORDER BY last_update_date DESC
        LIMIT 1;

        -- Insert order item
        INSERT INTO order_items (quantity, price_at_purchase, order_id, product_id)
        VALUES (v_quantity, v_price, v_order_id, v_product_id);

        -- Decrement inventory
        UPDATE inventory
        SET    quantity_available = quantity_available - v_quantity,
               last_updated       = CURDATE()
        WHERE  inventory_id = v_inv_id;

        -- Accumulate total
        SET v_total = v_total + (v_price * v_quantity);

    END LOOP read_loop;

    CLOSE item_cursor;

    -- ----------------------------------------------------------------
    -- Step 5: Insert payment record
    -- ----------------------------------------------------------------
    INSERT INTO payment (
        payment_method, payment_status,
        total_amount, payment_date, card_id
    )
    VALUES (
        p_payment_method, 'Success',
        v_total, CURDATE(), p_card_id
    );

    SET v_payment_id = LAST_INSERT_ID();

    -- ----------------------------------------------------------------
    -- Step 6: Insert order confirmation
    -- ----------------------------------------------------------------
    INSERT INTO order_confirmation (
        order_id, payment_id, delivery_id, confirmation_status
    )
    VALUES (
        v_order_id, v_payment_id, NULL, 'confirmed'
    );

    -- ----------------------------------------------------------------
    -- Step 7: Clean up and commit
    -- ----------------------------------------------------------------
    DROP TEMPORARY TABLE IF EXISTS temp_order_items;

    COMMIT;

    -- Success output
    SELECT
        'ORDER PLACED SUCCESSFULLY' AS message,
        v_order_id                  AS order_id,
        v_payment_id                AS payment_id,
        v_total                     AS total_amount;

END //

DELIMITER ;