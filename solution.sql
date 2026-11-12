-- ДЗ «SQL. Часть 2»: задания 1–5.
-- СУБД: MySQL 5.7 / 8.x. База данных: sakila.
-- Запросы только читают данные.

SET NAMES utf8mb4;
USE sakila;

-- Задание 1. Магазины с числом закреплённых покупателей больше 300.
-- Для каждого сотрудника подходящего магазина выводится отдельная строка.
SELECT
    s.store_id AS `Магазин`,
    st.last_name AS `Фамилия`,
    st.first_name AS `Имя`,
    ci.city AS `Город`,
    COUNT(c.customer_id) AS `Количество покупателей`
FROM store AS s
JOIN staff AS st ON st.store_id = s.store_id
JOIN address AS a ON a.address_id = s.address_id
JOIN city AS ci ON ci.city_id = a.city_id
JOIN customer AS c ON c.store_id = s.store_id
GROUP BY s.store_id, st.staff_id, st.last_name, st.first_name, ci.city
HAVING COUNT(c.customer_id) > 300
ORDER BY s.store_id, st.staff_id;

-- Задание 2. Количество фильмов длиннее средней продолжительности.
SELECT COUNT(*) AS `Количество фильмов`
FROM film
WHERE length > (SELECT AVG(length) FROM film);

-- Задание 3. Месяц с максимальной суммой платежей и аренды за этот месяц.
-- Платежи учитываются по payment_date, аренды — по rental_date.
-- Год включён в группировку. При равенстве сумм выбирается ранний месяц.
SELECT
    p.payment_month AS `Месяц`,
    p.total_amount AS `Сумма платежей`,
    (
        SELECT COUNT(*)
        FROM rental AS r
        WHERE DATE_FORMAT(r.rental_date, '%Y-%m') = p.payment_month
    ) AS `Количество аренд`
FROM (
    SELECT
        DATE_FORMAT(payment_date, '%Y-%m') AS payment_month,
        SUM(amount) AS total_amount
    FROM payment
    GROUP BY DATE_FORMAT(payment_date, '%Y-%m')
    ORDER BY total_amount DESC, payment_month
    LIMIT 1
) AS p;

-- Задание 4*. Количество продаж и премия каждого продавца.
-- Продажа трактуется как запись об обработанном платеже в payment.
SELECT
    st.staff_id AS `Продавец`,
    st.last_name AS `Фамилия`,
    st.first_name AS `Имя`,
    COUNT(p.payment_id) AS `Количество продаж`,
    CASE
        WHEN COUNT(p.payment_id) > 8000 THEN 'Да'
        ELSE 'Нет'
    END AS `Премия`
FROM staff AS st
LEFT JOIN payment AS p ON p.staff_id = st.staff_id
GROUP BY st.staff_id, st.last_name, st.first_name
ORDER BY st.staff_id;

-- Задание 5*. Фильмы, ни один экземпляр которых не брали в аренду.
-- Включаются также фильмы без экземпляров в inventory.
SELECT
    f.film_id AS `Код фильма`,
    f.title AS `Название фильма`
FROM film AS f
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory AS i
    JOIN rental AS r ON r.inventory_id = i.inventory_id
    WHERE i.film_id = f.film_id
)
ORDER BY f.title, f.film_id;
