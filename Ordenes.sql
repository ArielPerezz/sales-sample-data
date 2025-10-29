/*
Como evolucionaron las cantidades y montos vendidos en el período de análisis?
*/
select	year_id as año,
		month_id as mes,
        sum(sales) as monto_vendido,
        sum(quantity) as unidades_vendidas
from	orders
group by	año, mes
order by	año, mes;

/*
Cuales fueron los 6 meses donde se registro un mayor monto por ventas ?
*/
select	year_id as año,
		month_id as mes,
        sum(sales) as monto_vendido
from	orders
group by	año,mes
order by	monto_vendido desc
limit 6;

/*
Y los 6 meses con menos ventas?
*/

select	year_id as año,
		month_id as mes,
        sum(sales) as monto_vendido
from	orders
group by	año,mes
order by	monto_vendido
limit 6;

/*
Vemos que de los 6 meses con mas ventas, 5 son en el segundo semestre del año, 4 en el último trimestre.
Y 5 de los 6 meses con menos ventas ocurren en la primera mitad del año.
Este pico de ventas de fin de año se puede aprovechar con promociones previas o un marketing mas intenso.
*/
with tabla_Aux as(
	select	year_id as año,
		month_id as mes,
        sum(sales) as monto_vendido
from	orders
group by	año,mes)
select	mes,
		avg(monto_vendido) as ventas_prom
from tabla_aux
group by mes
order by avg(monto_vendido) desc;

/*
Comrobamos esta misma estacionalidad de otra manera, mirando para cade mes cuanto suman en promedio sus ventas para los distintos años.
Los meses con mas ventas estan al final del año.
*/

/*
Comparar las ventas de cada mes con las ventas del mes anterior, para ver donde aumentan o donde disminuyen.
Tambien comparo las ventas de todos los meses, con las ventas del primer mes, para ver la variacion acumulada.
*/
with	tabla_aux as(
	select	year_id as año,
			month_id as mes,
			sum(sales) as monto_vendido
	from	orders
	group by	año,mes
	order by	año,mes)
select	año,
		mes,
        monto_vendido,
        (monto_vendido - lag(monto_vendido) over(order by año,mes)) /lag(monto_vendido) over(order by año,mes) * 100 as variacion_mensual,
        (monto_vendido - first_value(monto_vendido) over(order by año,mes)) /first_value(monto_vendido) over(order by año,mes) * 100 as variacion_acumulada
from	tabla_aux
order by	año,mes;

/*
Podemos ver que el mes con ventas mas bajas es el primero de nuestra base, todos los aumentos o disminuciones que se dan son por encima de ese nivel inicial
*/


/*
Revisemos ahora el monto promedio por unidad vendida para cada mes, para ver que explica este aumento en los montos vendidos.
*/
with	tabla_aux as(
	select	year_id as año,
			month_id as mes,
			sum(sales) / sum(quantity) as monto_promedio
	from	orders
	group by	año,mes
	order by	año,mes)
select	año,
		mes,
        monto_promedio,
        (monto_promedio - lag(monto_promedio) over(order by año,mes)) /lag(monto_promedio) over(order by año,mes) * 100 as variacion_mensual,
        (monto_promedio - first_value(monto_promedio) over(order by año,mes)) /first_value(monto_promedio) over(order by año,mes) * 100 as variacion_acumulada
from	tabla_aux
order by	año,mes;

/*
Viendo el monto promedio por unidad para cada mes, ningun mes queda por debajo del primero, pero tampoco ningun mes lo supera por mas de 15%.
*/

/*
Veamos que pasa con la cantidad de unidades vendidas
*/
with	tabla_aux as(
	select	year_id as año,
			month_id as mes,
			sum(quantity) as uds_vendidas
	from	orders
	group by	año,mes
	order by	año,mes)
select	año,
		mes,
        uds_vendidas,
        (uds_vendidas - lag(uds_vendidas) over(order by año,mes)) /lag(uds_vendidas) over(order by año,mes) * 100 as variacion_mensual,
        (uds_vendidas - first_value(uds_vendidas) over(order by año,mes)) /first_value(uds_vendidas) over(order by año,mes) * 100 as variacion_acumulada
from	tabla_aux
order by	año,mes;

/*
Aca podemos ver una diferencia mayor, de nuevo el mes con menos ventas es el primero, y se nota un mayor aumento en esta variable, que en los montos
promedio de unidad vendida por mes.
Entonces podemos deicr que aumentaron los ingresos por ventas no porque estemos vendiendo mas caro, sino porque estamos vendiendo mas cantidad.
*/
