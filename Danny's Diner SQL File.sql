CREATE Database dannys_diner;
Use dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
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
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

Select * From sales;

Select * From menu;

Select * From members;

-- 1)What is the total amount each customer spent at the restaurant?
Select 
	s.Customer_id, sum(m.price) As Total_Amount_Spent
From 
	sales s
	Join menu m on s.product_id = m.product_id
Group By 
	s.Customer_id;

-- 2)How many days has each customer visited the restaurant?
Select 
	Customer_id, Count(distinct(order_date)) As No_of_days_visited
From 
	sales
Group By
	customer_id;

-- 3)What was the first item from the menu purchased by each customer?
select Customer_id, product_name
From
	(Select 
		s.Customer_id, m.product_name, 
		ROW_NUMBER() over (partition by customer_id order by order_date) as rnk
	From 
		sales s 
		join menu m on s.product_id=m.product_id) x
Where
	rnk=1;

-- 4)What is the most purchased item on the menu and how many times was it purchased by all customers?
Select 
	Top 1
	m.Product_name, Count(s.product_id) as most_purchased_item_count
From 
	sales s
	join menu m on s.product_id=m.product_id
Group By 
	m.product_name
Order By
	most_purchased_item_count Desc;

-- 5)Which item was the most popular for each customer?
Select 
	customer_id, product_name
From 
	(Select 
		s.customer_id, m.product_name,
		DENSE_RANK() over (partition by customer_id order by count(s.product_id) desc) as rnk
	From
		sales s 
		join menu m on s.product_id=m.product_id
	Group By
		s.customer_id, m.product_name) x 
Where 
	rnk=1;

-- 6)Which item was purchased first by the customer after they became a member?
With Cte as (
	Select 
		s.customer_id, s.order_date, m.product_name as After_membership_first_purchased_item, 
		RANK() over (partition by s.customer_id order by order_date asc) As rnk
	From
		sales s 
		join menu m on s.product_id=m.product_id
		join members me on s.customer_id=me.customer_id
	Where 
		s.order_date >= me.join_date)
Select 
	customer_id, After_membership_first_purchased_item
From 
	Cte
Where 
	rnk=1;

-- 7)Which item was purchased just before the customer became a member?
With Cte1 as (
	Select 
		s.customer_id, s.order_date, m.product_name as item_purchased_just_before_the_customer_became_a_member, 
		RANK() over (partition by s.customer_id order by order_date desc) As rnk
	From
		sales s 
		join menu m on s.product_id=m.product_id
		join members me on s.customer_id=me.customer_id
	Where 
		s.order_date < me.join_date)
Select 
	customer_id, item_purchased_just_before_the_customer_became_a_member
From 
	Cte1
Where 
	rnk=1;

-- 8)What is the total items and amount spent for each member before they became a member?
Select 
	s.customer_id, Count(s.product_id) As Total_item,
	Sum(m.price) As Total_amount_spent_before_membership
From
	sales s 
	join menu m on s.product_id=m.product_id
	join members me on s.customer_id=me.customer_id
Where 
	s.order_date < me.join_date
Group By 
	s.customer_id;

-- 9)If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
With points as(
	Select product_id,
	Case
		When product_id = 1 then price*20
		Else price*10
		End as point
	From menu)
SELECT 
    s.customer_id,
    SUM(p.point) AS Total_points
FROM 
    sales s
    JOIN points p ON s.product_id = p.product_id
GROUP BY
    s.customer_id;

-- 10)In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
--  	not just sushi - how many points do customer A and B have at the end of January?
WITH dates_cte AS (
  SELECT 
    customer_id, 
    join_date, 
    DATEADD(DAY, 6, join_date) AS valid_date, 
    DATEADD(DAY, -1, EOMONTH('2021-01-31')) AS last_date
  FROM members
)
SELECT 
    s.customer_id, 
    SUM(CASE 
            WHEN m.product_name = 'sushi' THEN 20 * m.price
            WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 20 * m.price
            ELSE 10 * m.price 
        END) AS points
FROM 
    sales s
    JOIN menu m ON s.product_id = m.product_id
    JOIN dates_cte d ON s.customer_id = d.customer_id
GROUP BY 
    s.customer_id;


