Create database supermarket;

use supermarket;

create table store_details(
	store_id int primary key,
    store_name varchar(64) not null,
    store_address varchar(64) not null,
    Phone varchar(10) not null unique,
    email varchar(65) not null unique,
    Check (phone REGEXP '^[0-9]{10}$')
);

create table store_staff_manager(
	emp_id int primary key,
	username varchar(64) not null,
    password varchar(64) not null,
    store_id int not null,
    Foreign key (store_id)
		references store(store_id)
        on update cascade
        on delete cascade
);

create table store_staff_packer(
	emp_id int primary key,
    username varchar(64) not null,
    password varchar(64) not null,
    Availability_status enum("yes","no") not null,
    store_id int not null,
    foreign key (store_id)
		references store(store_id)
        on update cascade
        on delete cascade
);

create table inventory(
	inventory_id int primary key,
    quantity_available int not null,
    reorder_level int not null,
    last_updated date not null
);

create table category(
	category_id int primary key,
    category_name varchar(64) not null,
    category_description varchar(64) not null
);

create table product(
	product_id int primary key,
    product_name varchar(64) not null,
    product_barcode varchar(9) unique not null,
    product_description varchar(64) not null,
    category_id int not null,
    foreign key (category_id)
		references category(category_id)
        on update cascade
        on delete cascade,
    check (product_barcode regexp ('^(A-Z)(a-z)(0-9){9)$'))
);

create table stores(
	store_id int not null,
    inventory_id int not null,
    product_id int not null,
    primary key (store_id, inventory_id, product_id),
    foreign key (store_id)
		references store_detail(store_id)
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
	price_id int primary key,
    Market_price int not null,
    Current_retial_price int not null,
    Discounted_price int,
    is_discounted enum("yes","no") not null,
    last_update_date date not null,
    product_id int not null,
    foreign key (product_id)
		references product(product_id)
        on update cascade
        on delete cascade
);



