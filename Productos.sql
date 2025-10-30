/*
Con la base normalizada, podemos empezar a hacernos preguntas de análisis.
 Productos:
 Cuales son los productos mas vendidos según ingreso generado?
 Cuales son los mas vendidos por unidades vendidas?
 Cual es el producto mas vendido por año y mes?
 */
 
/*
Primero creo una vista cruzando los datos de orden con productos
*/
create view cruce_prod as(
	select	order_number,
			quantity,
			unit_price,
			order_line_number,
			sales,
			order_date,
			status,
			qtr_id,
			month_id,
			year_id,
			o.product_code,
			deal_size,
			p.product_line
	from	orders o
	left join
	products p
	on o.product_code = p.product_code
);

/*
Cuantos productos tengo?
*/

select count(product_code) from products;

/*
Cuantos meses de datos tengo?
*/
select count(distinct year_id, month_id) from cruce_prod;




/*
De mis 109 productos, cuales son los 10 mas vendidos por monto?
*/
select	sum(sales) as total_sales,
		product_code,
		product_line
from	cruce_prod
group by	product_code,
			product_line
order by	total_sales desc
limit 10;

/*
Y por unidades vendidas?
*/
select	sum(quantity) as sold_units,
		product_code,
		product_line
from	cruce_prod
group by	product_code,
			product_line
order by	sold_units desc
limit 10;

/*
Cual es el producto mas vendido para cada mes?
*/
with aux_table as(
	select	sum(sales) as total_sales,
			product_code,
            product_line,
			year_id as year,
			month_id as month,
			rank() over(partition by year_id, month_id order by sum(sales) desc) as ranking
	from	cruce_prod
	group by	year_id,
				month_id,
				product_code,
                product_line)
select	*
from	aux_table
where ranking=1;

/*
Para cada uno de estos productos, en cuantos meses fueron el mas vendido?
*/
with aux_table as(
	select	sum(sales) as total_sales,
			product_code,
            product_line,
			year_id as year,
			month_id as month,
			rank() over(partition by year_id, month_id order by sum(sales) desc) as ranking
	from	cruce_prod
group by	year_id,
				month_id,
				product_code,
                product_line),
tabla_primeros as(
select	*
from	aux_table
where ranking=1)
select	product_code,
		product_line,
        count(product_code) as cant_meses
from	tabla_primeros
group by	product_code,
			product_line
order by	count(product_code) desc;

/*De los 29 meses de datos que tengo, en 11 el producto que generó mas por ventas es el S18_3232*/

/*
Veamos ahora que tan concentradas estan mis ventas.
Para esto veamos que porcentaje concentran los 5 productos con mas ventas

*/


with tabla_aux as(
	select	product_code,
			sum(sales) as ventas_totales
	from	cruce_prod
	group by	product_code
	order by	ventas_totales desc),
tabla_por_prod as(
	select	product_code,
			ventas_totales,
			sum(ventas_totales) over(order by ventas_totales desc) / sum(ventas_totales) over() * 100 as porc_del_total,
            row_number() over(order by ventas_totales desc) as num
	from	tabla_aux
	order by ventas_totales desc)
select	porc_del_total
from	tabla_por_prod
where	num=5;

/*
Entonces podemos decir que 5 de los 109 productos(un 4.5%) son responsables del 9.7% de las ventas en el período analizado.
*/


/*
podemos ver cuantos productos de los 109 concentran el 50% de mis ingresos por ventas
*/

with tabla_aux as(
	select	product_code,
			sum(sales) as ventas_totales
	from	cruce_prod
	group by	product_code
	order by	ventas_totales desc),
tabla_por_prod as(
	select	product_code,
			ventas_totales,
			sum(ventas_totales) over(order by ventas_totales desc) / sum(ventas_totales) over() * 100 as porc_del_total
	from	tabla_aux
	order by ventas_totales desc),
tabla_final as(
select	product_code,
		ventas_totales,
        porc_del_total,
        case when porc_del_total > 50 and lag(porc_del_total) over(order by ventas_totales desc) < 50 then 1 else 0 end as marcador,
        row_number() over(order by ventas_totales desc) as num_prods
from	tabla_por_prod)
select	num_prods
from	tabla_final
where	marcador = 1;

/*Vemos entonces que el 50% de las ventas totales se concentran en 39 de los 109 productos.
Entonces podemos decir que las ventas no estan excesivamente concentradas en pocos productos.
Esto es algo por un lado bueno porque depender de un solo productos o de pocos productos implica que si un competidor
saca al mercado un producto que compita con el nuestro eso puede afectar de manera sensible las ventas.
Si uno no depende de un solo producto no tiene este problema.
Pero por el otro lado tener ventas poco concentradas implica que puede ser mas dificil decidir sobre que productos enfocar mas recursos(marketing, stock, logística)
*/



/*
Veamos mes a mes cuantos productos tenemos que juntar para llegar al 50% de las ventas de ese mes
*/
            
            
with ventas_por_mes as(
	select	sum(sales) as ventas,
			sum(sales) over(partition by year_id, month_id order by sum(sales) desc) / sum(sales) over(partition by year_id, month_id) as porc_ventas,
			product_code,
            year_id,
            month_id
	from	orders
    group by	product_code,
				year_id,
                month_id
),
tabla_marcador as(
select	*,
		row_number() over(partition by year_id, month_id order by porc_ventas) as num,
        case when porc_ventas > 0.5 and lag(porc_ventas) over() < 0.5 then 1 else 0 end as marcador
from	ventas_por_mes
order by	year_id,
			month_id,
            ventas desc)
select	year_id as año,
		month_id as mes,
        num as cantidad_de_productos
from	tabla_marcador
where	marcador = 1;

/*
Vemos que la cantidad de productos que mes a mes acumulan el 50% de las vantas de ese mes van aumentando con el tiempo.
Para los primeros 8 meses, el 50% esta concentrado en menos de 20 productos.
En 7 de los últimos 8, el 50% se concentra en mas de 30 productos.
Esta tendencia habla de una cartera de ventas que se vuelve cada vez mas uniforme, esto tiene las ventajas y desventajas que ya mencionamos antes:
Ventaja desde el punto de vista del riesgo, al no depender excesivamente de pocos producots para sostener la facturación.
Mayor complejidad operativa, ya que no es evidente que canales de venta, inventarios y campañas optimizar. 
*/
