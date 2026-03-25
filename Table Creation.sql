Create database supermarket;

use supermarket;

create table store_details(
	store_id int primary key auto_increment,
    store_name varchar(64) not null,
    Phone varchar(10) not null unique,
    email varchar(65) not null unique,
    Check (phone REGEXP '^[0-9]{10}$')
);

create table store_address(
	Street varchar(124) not null,
    City varchar(64) not null,
    State varchar(64) not null,
    Country varchar(64) default"USA" ,
    zip_code varchar(10) not null,
    store_id int not null,
    primary key(store_id, street),
    Foreign key (store_id)
		references store_details(store_id)
        on update cascade
        on delete cascade
);

create table store_staff(
	emp_id int primary key auto_increment,
	username varchar(64) not null,
    password varchar(64) not null,
    store_id int not null,
    Foreign key (store_id)
		references store_details(store_id)
        on update cascade
        on delete cascade
);

Create table store_manager(
	emp_id int primary key not null,
    foreign key (emp_id)
		references store_staff(emp_id)
        on update cascade
        on delete cascade
);

create table store_staff_packer(
	emp_id int primary key not null,
    Availability_status enum("yes","no") not null,
    foreign key (emp_id)
		references store_staff(emp_id)
        on update cascade
        on delete cascade
);

create table inventory(
	inventory_id int auto_increment primary key,
    quantity_available int not null,
    reorder_level int not null,
    last_updated date not null
);

create table category(
	category_id int auto_increment primary key,
    category_name varchar(64) not null,
    category_description varchar(64) not null
);

create table product(
	product_id int primary key,
    product_name varchar(64) not null,
    product_barcode varchar(12) unique not null,
    product_description varchar(64) not null,
    category_id int not null,
    foreign key (category_id)
		references category(category_id)
        on update cascade
        on delete cascade,
    check (product_barcode regexp '^(0-9){12)$')
);

create table stores(
	store_id int not null,
    inventory_id int not null,
    product_id int not null,
    primary key (store_id, inventory_id, product_id),
    foreign key (store_id)
		references store_details(store_id)
        on update cascade
        on delete cascade,
	foreign key (inventory_id)
		references inventory(inventory_id)
        on update cascade
        on delete cascade,
	foreign key(product_id)
		references product(product_id)
        on update cascade
        on delete cascade
);

create table product_images(
	product_id int not null,
    image_url varchar(64) not null,
    image_description varchar(64) not null,
    primary key (product_id, image_url),
    foreign key (product_id)
		references product(product_id)
        on update cascade
        on delete cascade
);

create table product_price(
	price_id int auto_increment primary key,
    Market_price decimal(10,2) not null,
    Current_retial_price decimal(10,2) not null,
    Discounted_price decimal(10,2),
    is_discounted enum("yes","no") not null,
    last_update_date date not null,
    product_id int not null,
    foreign key (product_id)
		references product(product_id)
        on update cascade
        on delete cascade
);

create table customer(
	customer_id int auto_increment primary key,
    name varchar(64) not null,
    email varchar(64) unique not null,
    password varchar(64) not null,
    Date_of_birth date not null
);

create table customer_address(
	Street varchar(124) not null,
    City varchar(64) not null,
    State varchar(64) not null,
    Country varchar(64) default"USA" ,
    zip_code varchar(10) not null,
    customer_id int not null,
    primary key(customer_id, street),
    Foreign key (customer_id)
		references customer(customer_id)
        on update cascade
        on delete cascade
);

create table card_details(
	card_id int auto_increment primary key,
    card_name varchar(64) not null,
    last_4_digits varchar(4) unique not null,
    exp_date date not null,
    customer_id int not null,
    foreign key (customer_id)
		references customer(customer_id)
        on update cascade
        on delete cascade
);

create table customer_order(
	order_id int auto_increment primary key,
    order_type enum("Pickup","Delivery") not null,
    order_time datetime not null,
    order_date date not null,
    order_status enum("Confirmed","Cancelled","Failed"),
    customer_id int not null,
    store_id int not null,
    Foreign key (customer_id)
		references customer(customer_id)
        on update cascade
        on delete cascade,
	Foreign key (store_id)
		references store_details(store_id)
        on update cascade
        on delete cascade
);

create table order_items(
	quantity int not null,
    price_at_purchase decimal(10,2) not null,
    order_id int not null,
    product_id int not null,
    primary key(order_id, product_id),
    foreign key (order_id)
		references customer_order(order_id)
        on update cascade
        on delete cascade,
	foreign key(product_id)
		references product(product_id)
        on update cascade
        on delete cascade
);


create table order_assignment(
	Assignment_id int auto_increment primary key,
    Assignment_status enum("confirmed","packing","Ready for delivery","Ready for pickup","out for delivery","delivered"),
    manager_id int not null,
    packer_id int not null,
    order_id int not null,
    Foreign key (manager_id)
		references store_manager(emp_id)
        on update cascade
        on delete cascade,
	Foreign key (packer_id)
		references store_staff_packer(emp_id)
        on update cascade
        on delete cascade,
	Foreign key (order_id)
		references customer_order(order_id)
        on update cascade
        on delete cascade
);

Create table payment(
	payment_id int auto_increment primary key,
    payment_method enum("debit card","credit card","paypal","apple pay","google pay"),
    payment_status enum("Success","Failed"),
    total_amount decimal(10,2) not null,
    payment_date date not null,
    card_id int,
    
    Foreign key (card_id)
		references card_details(card_id)
        on update cascade
        on delete cascade
);

create table delivery_details(
	delivery_id int auto_increment primary key,
    delivery_status enum("delivered","not delivered"),
    delivery_date date not null
);

create table delivery_address(
	Street varchar(124) not null,
    City varchar(64) not null,
    State varchar(64) not null,
    Country varchar(64) default"USA" ,
    zip_code varchar(10) not null,
    delivery_id int not null,
    primary key(delivery_id, street),
    foreign key (delivery_id)
		references delivery_details(delivery_id)
        on update cascade
        on delete cascade
);

create table order_confirmation(
	order_id int not null,
    payment_id int not null,
    delivery_id int,
    confirmation_status enum("confirmed","not confirmed"),
    foreign key (order_id)
		references customer_order(order_id)
        on update cascade
        on delete cascade,
	foreign key (payment_id)
		references payment(payment_id)
        on update cascade
        on delete cascade,
	foreign key (delivery_id)
		references delivery_details(delivery_id)
        on update cascade
        on delete cascade
);






