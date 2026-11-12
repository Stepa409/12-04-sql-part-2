# Домашнее задание к занятию «SQL. Часть 2» — Степанов Андрей

ТЗ: [SQL. Часть 2, 12-04](https://github.com/netology-code/sdb-homeworks/blob/main/12-04.md).

Решение для **MySQL**, учебная база данных **Sakila**. Выполнены все три основных и оба дополнительных задания. Полный SQL-скрипт: [solution.sql](solution.sql).

Перед выполнением отдельных запросов необходимо выбрать базу:

```sql
USE sakila;
```

Числовые результаты ниже рассчитаны на официальном наборе **Sakila 1.5**. В других редакциях или изменённых копиях базы результаты могут отличаться.

## Задание 1

**Условие.** Одним запросом получить фамилию и имя сотрудника, город магазина и число закреплённых покупателей для магазинов, в которых более 300 покупателей.

**Решение:**

```sql
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
```

`customer.store_id` определяет магазин покупателя, `staff.store_id` — магазин сотрудника. Город определяется через адрес магазина: `store → address → city`. Покупатели подсчитываются отдельно для каждого сотрудника магазина. `HAVING` оставляет только группы, в которых покупателей строго больше 300. Ограничение по активности покупателей не добавляется, поскольку его нет в условии.

**Результат на Sakila 1.5:**

| Магазин | Фамилия | Имя | Город | Количество покупателей |
| --- | --- | --- | --- | --- |
| 1 | Hillyer | Mike | Lethbridge | 326 |

Под условие подходит магазин № 1: сотрудник Mike Hillyer, город Lethbridge, 326 покупателей.

## Задание 2

**Условие.** Получить количество фильмов, продолжительность которых больше средней продолжительности всех фильмов.

**Решение:**

```sql
SELECT COUNT(*) AS `Количество фильмов`
FROM film
WHERE length > (SELECT AVG(length) FROM film);
```

Подзапрос рассчитывает среднюю продолжительность по всей таблице `film`, внешний запрос подсчитывает фильмы со строго большей продолжительностью. `AVG` не учитывает `NULL`; фильмы с неизвестной продолжительностью также не проходят сравнение.

**Результат на Sakila 1.5:**

| Количество фильмов |
| --- |
| 489 |

Средняя продолжительность — 115.272 минуты. Длиннее среднего значения — 489 фильмов.

## Задание 3

**Условие.** Определить месяц с наибольшей суммой платежей и количество аренд за этот месяц.

**Решение:**

```sql
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
```

Вложенная таблица `p` суммирует платежи по календарным месяцам и выбирает месяц с максимальной суммой. Формат `%Y-%m` учитывает и год, и месяц, поэтому месяцы разных лет не объединяются. При одинаковой сумме выбирается более ранний месяц. Количество аренд за выбранный месяц подсчитывается отдельно по `rental.rental_date`; сумма платежей — по `payment.payment_date`. Это сохраняет смысл условия даже при оплате аренды в другом месяце или при нескольких платежах за одну аренду.

**Результат на Sakila 1.5:**

| Месяц | Сумма платежей | Количество аренд |
| --- | --- | --- |
| 2005-07 | 28368.91 | 6709 |

Наибольшая сумма платежей получена в июле 2005 года: 28368.91. За этот календарный месяц оформлено 6709 аренд.

## Задание 4*

**Условие.** Посчитать количество продаж каждого продавца. Вывести «Да» в колонке «Премия», если продаж больше 8000, иначе — «Нет».

**Решение:**

```sql
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
```

Продажей в этом решении считается один обработанный платёж — строка таблицы `payment`. Продавец определяется по `payment.staff_id`. `LEFT JOIN` сохраняет продавцов без продаж, а `COUNT(p.payment_id)` возвращает для них ноль. Условие премирования строгое: при 8000 продаж премия имеет значение «Нет».

**Результат на Sakila 1.5:**

| Продавец | Фамилия | Имя | Количество продаж | Премия |
| --- | --- | --- | --- | --- |
| 1 | Hillyer | Mike | 8054 | Да |
| 2 | Stephens | Jon | 7990 | Нет |

У Mike Hillyer — 8054 продажи и премия «Да»; у Jon Stephens — 7990 продаж и премия «Нет».

## Задание 5*

**Условие.** Найти фильмы, которые ни разу не брали в аренду.

**Решение:**

```sql
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
```

`NOT EXISTS` проверяет отсутствие аренды любого экземпляра фильма через связь `film → inventory → rental`. Достаточно одной аренды хотя бы одного экземпляра, чтобы исключить фильм из результата. Фильмы без экземпляров в `inventory` тоже включаются в ответ. Такой запрос не выдаёт фильм ошибочно, если у него одновременно есть арендованные и неарендованные экземпляры.

**Результат на Sakila 1.5:**

Найдено 42 фильма. Полный список:

| Код фильма | Название фильма |
| --- | --- |
| 14 | ALICE FANTASIA |
| 33 | APOLLO TEEN |
| 36 | ARGONAUTS TOWN |
| 38 | ARK RIDGEMONT |
| 41 | ARSENIC INDEPENDENCE |
| 87 | BOONDOCK BALLROOM |
| 108 | BUTCH PANTHER |
| 128 | CATCH AMISTAD |
| 144 | CHINATOWN GLADIATOR |
| 148 | CHOCOLATE DUCK |
| 171 | COMMANDMENTS EXPRESS |
| 192 | CROSSING DIVORCE |
| 195 | CROWDS TELEMARK |
| 198 | CRYSTAL BREAKING |
| 217 | DAZED PUNK |
| 221 | DELIVERANCE MULHOLLAND |
| 318 | FIREHOUSE VIETNAM |
| 325 | FLOATS GARDEN |
| 332 | FRANKENSTEIN STRANGER |
| 359 | GLADIATOR WESTWARD |
| 386 | GUMP DATE |
| 404 | HATE HANDICAP |
| 419 | HOCUS FRIDA |
| 495 | KENTUCKIAN GIANT |
| 497 | KILL BROTHERHOOD |
| 607 | MUPPET MILE |
| 642 | ORDER BETRAYED |
| 669 | PEARL DESTINY |
| 671 | PERDITION FARGO |
| 701 | PSYCHO SHRUNK |
| 712 | RAIDERS ANTITRUST |
| 713 | RAINBOW SHOCK |
| 742 | ROOF CHAMPION |
| 801 | SISTER FREDDY |
| 802 | SKY MIRACLE |
| 860 | SUICIDES SILENCE |
| 874 | TADPOLE PARK |
| 909 | TREASURE COMMAND |
| 943 | VILLAIN DESPERATE |
| 950 | VOLUME HOUSE |
| 954 | WAKE JAWS |
| 955 | WALLS ARTIST |

## Проверка решения

Для проверки использованы данные из [официального архива Sakila](https://downloads.mysql.com/docs/sakila-db.tar.gz). Загружены 1000 фильмов, 599 покупателей, 4581 экземпляр, 16044 аренды и 16044 платежа.

В этой среде отсутствует сервер MySQL, поэтому логика запросов и приведённые результаты проверены на SQLite 3.54.0 с импортом исходных данных и адаптацией функции `DATE_FORMAT` для формата `%Y-%m`. Суммы платежей дополнительно сверены точной десятичной арифметикой Python `Decimal`. SQL-файл предназначен для MySQL; запуск на сервере MySQL в этой среде не выполнялся.

Дополнительно проверены случаи нескольких сотрудников в одном магазине, ровно 8000 продаж, фильма без экземпляров и фильма с экземпляром без аренд. Число покупателей при добавлении второго сотрудника остаётся 326, при 8000 продаж премия — «Нет», оба вида фильмов без аренд попадают в ответ.

## Источники

- [Условия домашнего задания](https://github.com/netology-code/sdb-homeworks/blob/main/12-04.md).
- [Шаблон оформления](https://github.com/netology-code/sys-pattern-homework).
- [Установка Sakila](https://dev.mysql.com/doc/sakila/en/sakila-installation.html).
- [Платежи и связь с сотрудниками: таблица payment](https://dev.mysql.com/doc/sakila/en/sakila-structure-tables-payment.html).
- [Дата выдачи и записи об арендах: таблица rental](https://dev.mysql.com/doc/sakila/en/sakila-structure-tables-rental.html).
- [MySQL: функции даты и времени](https://dev.mysql.com/doc/refman/8.4/en/date-and-time-functions.html).
