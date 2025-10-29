/*
Creo el modelo, y las tablas que voy a utilizar.
Mis datos vienen todos en un solo csv, entonces lo importo con Import Wizard a una talba temporal, que despues voy a normalizar separandola en distintas tablas.
*/

create database sales_data_sample;
create table datos_temp(
	order_number int,
    quantity_ordered int,
    unit_price decimal(10,2),
    order_line_number int,
    sales decimal(10,2),
    orderdate varchar(30),
    status varchar(20),
    qtr int,
    month int,
    year int,
    product_line varchar(30),
    msrp int,
    product_code varchar(20),
    customer_name varchar(50),
    phone varchar(20),
    address_line_1 text,
    address_line_2 text,
    city varchar(20),
    state varchar(20),
    postal_code varchar(20),
    country varchar(20),
    territory varchar(10),
    last_name varchar(30),
    first_name varchar(30),
    deal_size varchar(20)
);

create table products(
	product_code varchar(20) primary key,
    product_line varchar(30)
);

create table customers(
	customer_id int auto_increment primary key,
	name varchar(50),
    phone varchar(20),
    address_line_1 text,
    address_line_2 text,
    city varchar(20),
    state varchar(20),
    postal_code varchar(20),
    country varchar(20),
    territory varchar(10),
    last_name varchar(30),
    first_name varchar(30)
);

create table orders(
	order_number int,
    quantity int,
    unit_price decimal(10,2),
    order_line_number int,
    sales decimal(10,2),
    order_date varchar(30),
    status varchar(20),
    qtr_id int,
    month_id int,
    year_id int,
    product_code varchar(20),
    customer_id int,
    customer_name varchar(50),
    deal_size varchar(20),
    foreign key (product_code) references products(product_code)
);
/*
Copio los datos de mi tabla temporal en mis tablas normalizadas.
*/
insert into customers(
	name,
    phone,
    address_line_1,
    address_line_2,
    city,
    state,
    postal_code,
    country,
    territory,
    last_name,
    first_name)
select distinct customer_name,
    phone,
    address_line_1,
    address_line_2,
    city,
    state,
    postal_code,
    country,
    territory,
    last_name,
    first_name
from datos_temp;

insert into products(
	product_code,
    product_line)
select	distinct
	product_code,
    product_line
from datos_temp;

insert into orders(
	order_number,
    quantity,
    unit_price,
    order_line_number,
    sales,
    order_date,
    status,
    qtr_id,
    month_id,
    year_id,
    customer_name,
    product_code,
    deal_size)
select order_number,
    quantity_ordered,
    unit_price,
    order_line_number,
    sales,
    orderdate,
    status,
    qtr,
    month,
    year,
    customer_name,
    product_code,
    deal_size
from datos_temp;

select	*
from	orders;
/*
La tabla original no tinee un customerID, entonces lo agrego a la tabla customers, y luego hago un join para llevar ese ID a la tabal de orders.
*/

update orders o
join
customers c on o.customer_name = c.name
set o.customer_id = c.customer_id;
select * from orders;
alter table orders drop column customer_name;



/*
La tabla original agrega una hora en la columna fecha de orden, pero siempre indica las 00:00, entonces voy a descartar esa parte en una nueva columna.
Despues voy a pasar esa columna a fecha y descartar la columna de fechas anterior.
*/
alter table orders add column new_order_date varchar(30);
update orders
set new_order_date = substring_index(order_date,' ',1);
update orders set new_order_Date = str_to_date(new_order_Date, '%m/%d/%Y');
alter table orders drop column order_date;
alter table orders change new_order_Date order_date date;



/*
Con la columna de customerID ya creada en ambas tablas, establezco la relación entre ellas.
*/
alter table orders
add constraint fk_customer
foreign key (customer_id) references customers(customer_id);
