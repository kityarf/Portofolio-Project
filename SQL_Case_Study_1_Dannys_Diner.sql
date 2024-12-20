-- Database
CREATE SCHEMA dannys_diner;
USE dannys_diner;

CREATE TABLE menu (
  product_id INT NOT NULL,
  product_name VARCHAR(5),
  price INT,
  PRIMARY KEY (product_id)
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
CREATE TABLE members (
  customer_id VARCHAR(1) NOT NULL,
  join_date DATE,
  PRIMARY KEY (customer_id)
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

CREATE TABLE sales (
  customer_id VARCHAR(1) NOT NULL,
  order_date DATE,
  product_id INTEGER NOT NULL
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');

-- QUESTION
-- 1. What is the total amount each customer spent at the restaurant?
SELECT
customer_id,
SUM(price) as total_spend
FROM sales as S
INNER JOIN menu as M on S.product_id = M.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT
customer_id, 
COUNT(DISTINCT order_date) as days_visit
FROM sales 
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH ranked_items AS (
	SELECT
	customer_id,
	order_date,
	product_name,
	RANK() OVER(PARTITION BY customer_id ORDER BY order_date ASC) as rank,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date ASC) as row_num
    FROM sales as S
    INNER JOIN menu as M on S.product_id = M.product_id
    )
SELECT
customer_id,
product_name
FROM ranked_items
WHERE row_num = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
product_name,
COUNT(order_date) as purchased
FROM sales as S
INNER JOIN menu as M on S.product_id = M.product_id 
GROUP BY product_name
ORDER BY COUNT(order_date) DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH ranked_items AS (
	SELECT
    	s.customer_id,
    	m.product_name,
    	COUNT(*) AS orders,
    	RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rank
    FROM sales s
    JOIN menu m on s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT
customer_id, product_name, orders
FROM ranked_items
WHERE rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH ranked_items AS (
	SELECT
		S.customer_id,
		order_date,
		join_date,
		product_name,
		RANK() OVER(PARTITION BY S.customer_id ORDER BY order_date) AS rank,
		ROW_NUMBER() OVER(PARTITION BY S.customer_id ORDER BY order_date) AS row_num
	FROM sales as S
	INNER JOIN members as MEM on MEM.customer_id = S.customer_id
	INNER JOIN menu as M on S.product_id = M.product_id
	WHERE order_date >= join_date
)
SELECT customer_id, product_name
FROM ranked_items
WHERE rank = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH ranked_items AS (
	SELECT
		S.customer_id,
		order_date,
		join_date,
		product_name,
		RANK() OVER(PARTITION BY S.customer_id ORDER BY order_date DESC) AS rank,
		ROW_NUMBER() OVER(PARTITION BY S.customer_id ORDER BY order_date DESC) AS row_num
	FROM sales as S
	INNER JOIN members as MEM on MEM.customer_id = S.customer_id
	INNER JOIN menu as M on S.product_id = M.product_id
	WHERE order_date < join_date
)
SELECT customer_id,  order_date, product_name
FROM ranked_items
WHERE rank = 1

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT S.customer_id,
COUNT(product_name) as total_items,
SUM(price) as amount_spent
FROM sales as S
INNER JOIN members as MEM on MEM.customer_id = S.customer_id
INNER JOIN menu as M on S.product_id = M.product_id
WHERE order_date < join_date
GROUP BY S.customer_id

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points #multiplier - how many points would each customer have?
SELECT
customer_id,
SUM(CASE
    WHEN product_name='sushi' THEN price*10*2
    ELSE price*10
END) as points
FROM menu as M
INNER JOIN sales as S on S.product_id = M.product_id
GROUP BY customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
S.customer_id,
SUM(CASE 
	WHEN order_date BETWEEN MEM.join_date AND MEM.join_date+INTERVAL 6 DAY
    THEN price*10*2
    WHEN product_name='sushi' THEN price*10*2
    ELSE price*10
END) as points
FROM menu as M
INNER JOIN sales as S on S.product_id = M.product_id
INNER JOIN members as MEM on MEM.customer_id = S.customer_id
WHERE S.order_date <= '2021-01-31'
GROUP BY S.customer_id
  
-- Join All The Things
SELECT
S.customer_id, 
order_date, 
product_name,
price, 
CASE
WHEN join_date IS NULL THEN 'N'
WHEN order_date < join_date THEN 'N'
ELSE 'Y'
END as member
FROM sales as S
INNER JOIN menu as M on M.product_id = S.product_id
LEFT JOIN members as MEM on MEM.customer_id = S.customer_id
ORDER BY S.customer_id,
order_date,
price DESC

-- Rank All The Things
WITH ranked AS(
	SELECT
		S.customer_id, 
		order_date, 
		product_name,
		price, 
	CASE
		WHEN join_date IS NULL THEN 'N'
		WHEN order_date < join_date THEN 'N'
		ELSE 'Y'
	END as member
	FROM sales as S
	INNER JOIN menu as M on M.product_id = S.product_id
	LEFT JOIN members as MEM on MEM.customer_id = S.customer_id
	ORDER BY S.customer_id,
	order_date,
	price DESC
)
SELECT *,
CASE
	WHEN member = 'N' THEN NULL
    ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
    END as rank
    FROM ranked
