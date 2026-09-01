--1
select * from products
where price > 1000;

--2
select * from products
order by price desc;

--3
update products
set price = price * 1.10
where name like = '%Dell%';

--4
delete from products
where name like '%Macbook%';delete from products
where name like '%Macbook%';

--5
delete from products
where not exists (
    select 1
    from orders_products
    where orders_products.product_id = products.id
);

--6
select * from orders
where order_date >= CURRENT_DATE - INTERVAL '30 days';

--7
select users.name from orders
join users on orders.user_id = users.id;

--8
select users.name, orders.id as order_id, orders.order_date
from users
left join orders on orders.user_id = users.id;

--9
select id, name, email
from users
where exists (
    select 1
    from orders
    where orders.user_id = users.id
);

--10
select p.id, p.name
from products p
where not exists (
    select 1
    from orders_products op
    where op.product_id = p.id
);

--11
select id, name, email
from users
where not exists (
    select 1
    from orders
    where orders.user_id = users.id
);

--12
select * from products
where price > (select avg(price) from products)
order by price desc;

--13
select users.id, users.name, count(orders.id) as total_pedidos
from users
left join orders on orders.user_id = users.id
group by users.id, users.name
order by total_pedidos desc;

--14
select p.id, p.name, sum(op.quantity) as total_vendido
from products p
join orders_products op on op.product_id = p.id
group by p.id, p.name
order by total_vendido desc
limit 3;

--15
select 
    u.id,
    u.name,
    u.email,
    count(distinct o.id) as quantidade_pedidos,
    coalesce(sum(op.quantity * op.unit_price), 0) as valor_total_comprado
from users u
left join orders o on o.user_id = u.id
left join orders_products op on op.order_id = o.id
group by u.id, u.name, u.email
order by valor_total_comprado desc;