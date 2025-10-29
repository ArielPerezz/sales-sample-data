
create view cruce_clientes as(
select	order_number,
		quantity,
        unit_price,
		order_line_number,
        sales,
        status,
        qtr_id,
        month_id,
        year_id,
        product_code,
        deal_size,
        order_Date,
        c.customer_id,
        name,
        address_line_1,
        address_line_2,city,
        state,
        postal_code,
        country,
        territory,
        last_name,
        first_name
from	orders o
left join
customers c
on o.customer_id = c.customer_id
);

/*
Cuantas unidades se vendieron y cuantos ingresos por ventas hubo en cada pais? Que porecentaje representa del total?
*/
select	country,
		sum(sales) as total_sales,
		sum(sales) / sum(sum(sales)) over() * 100 as 'sales_%',
        sum(quantity) total_units_sold,
        sum(quantity) / sum(sum(quantity)) over() * 100 as 'units_%',
        row_number() over(order by sum(sales) desc) as num
from	cruce_clientes
group by	country
order by	total_sales desc;
/*
Vemos que por lejos el pais al que mas vendemos en cantidades y montos es Estados Unidos.
Este país representa el 36% de nuestras ventas.
*/

/*
Dividamos ahora por pais y ciudad
*/

select	city,
		country,
		sum(sales) as total_sales,
		sum(sales) / sum(sum(sales)) over() * 100 as 'sales_%',
        sum(quantity) total_units_sold,
        sum(quantity) / sum(sum(quantity)) over() * 100 as 'units_%',
        row_number() over(order by sum(sales) desc) as num
from	cruce_clientes
group by	country,
			city
order by	total_sales desc;

/*
Añadiendo la variable de ciudades se ve algo interesante, la ciudad a la que mas se vende es Madrid, no es una ciudad de Estados Unidos.
Madrid representa el 10% de las ventas del período analizado, por lo que puede ser una buena idea reforzar los canales de comercialización que se tiene con esta ciudad en particular.
*/


/*
Veamos ahora que paises y ciudades crecieron mas en cuanto a montos vendidos, comparando el primer del que se tienen datos de ventas, contra el último mes con datos de ventas.
*/
with tabla_Aux as(
	select	country,
			year_id,
			month_id,
			sum(sales) as total_sales
	from	cruce_clientes
	group by	country,
				year_id,
				month_id
	order by	country,
				year_id,
				month_id),
tabla_datos as(
	select	distinct country,
			first_value(year_id) over(partition by country order by year_id, month_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as primer_año,
			first_value(month_id) over(partition by country order by year_id, month_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as primer_mes,
			first_value(total_sales) over(partition by country order by year_id, month_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as primer_valor,
			last_value(year_id) over(partition by country order by year_id, month_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as ult_año,
			last_value(month_id) over(partition by country order by year_id, month_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as ult_mes,
			last_value(total_sales) over(partition by country order by year_id, month_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as ult_valor
	from	tabla_aux
	order by	country)
select	*,
		(ult_valor / primer_valor - 1) * 100 as variacion
from	tabla_datos
order by	(ult_valor / primer_valor - 1) * 100 desc;

/*
El pais que mas incrementó las ventas comparando su primer mes con su último mes con ventas fue Estados Unidos.
En segundo lugar con un incremento casi igual esta Bélgica.
El país que mas bajó sus ventas con esta métrica es Japón.
*/

/*
Veamos ahora el cálculo con las ciudades.
*/

with tabla_Aux as(
	select	city,
			country,
			year_id,
			month_id,
			sum(sales) as total_sales
	from	cruce_clientes
	group by	city,
				year_id,
				month_id
	order by	city,
				country,
				year_id,
				month_id),
tabla_datos as(
	select	distinct city,
			country,
			first_value(year_id) over(partition by city order by year_id, month_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as primer_año,
			first_value(month_id) over(partition by city order by year_id, month_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as primer_mes,
			first_value(total_sales) over(partition by city order by year_id, month_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as primer_valor,
			last_value(year_id) over(partition by city order by year_id, month_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as ult_año,
			last_value(month_id) over(partition by city order by year_id, month_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as ult_mes,
			last_value(total_sales) over(partition by city order by year_id, month_id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as ult_valor
	from	tabla_aux
	order by	city)
select	*,
		(ult_valor / primer_valor - 1) * 100 as variacion
from	tabla_datos
order by	(ult_valor / primer_valor - 1) * 100 desc;

/*
Nos encontramos con que las 4 ciudades que mas incrementaron sus ventas son ciudades europeas, seguidas por un grupo de 6 de Estados Unidos.
La ciudad que mas bajó esta ubicada en Japon.
*/


/*
Lo siguiente que podemos revisar son los 10 clientes que mas compraron, y de que país son.
*/
select	name,
		country,
        sum(sales) as total_sales
from	cruce_clientes
group by	name,
			country
order by sum(sales) desc
limit 10;

/*Revisemos ahora quienes son los clientes que compraron mas unidades de productos*/

select	name,
		country,
        sum(quantity) as total_units
from	cruce_clientes
group by	name,
			country
order by sum(quantity) desc
limit 10;


/* Los 10 con el mayor monto de compra promedio*/
select	*
from	cruce_clientes;

with tabla_aux as(
	select order_number,
			name,
            country,
            sum(sales) as total_sales
	from	cruce_clientes
	group by	order_number,
				name,
                country)
select	name,
		country,
		avg(total_sales) as avg_sale
from	tabla_aux
group by	name,
			country
order by	avg(total_sales) desc
limit 10;

/* Los 10 con el mayor monto promedio de unidades en cada compra*/
select	*
from	cruce_clientes;

with tabla_aux as(
	select order_number,
			name,
            country,
            sum(quantity) as total_sales
	from	cruce_clientes
	group by	order_number,
				name,
                country)
select	name,
		country,
		avg(total_sales) as avg_units
from	tabla_aux
group by	name,
			country
order by	avg(total_sales) desc
limit 10;


/*Tendiendo esta información podemos saber que tipo de clientes tenemos y con cuale puede ser mas efectivo por ejemplo,
ofrecer un descuento porcentual u ofrecer que por cada x número de unidades compradas se pueden llevar una unidad más.
*/
