-- Solved on MySQL Workbench by Monika Yadav
-- Challenge 1 of 8 Weeks Challenge
-- Danny Dinner


/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
    DISTINCT(s.customer_id) AS Customer_ID,
    SUM(m.price) OVER(PARTITION BY s.customer_id) AS Total_Amount_Spent 
FROM
	sales s
        JOIN
    menu m ON s.product_id = m.product_id;

-- 2. How many days has each customer visited the restaurant?

SELECT 
    s.customer_id AS Customer_ID, 
    COUNT(DISTINCT s.order_date) AS Total_no_of_days_visited
FROM
    sales s
GROUP BY s.customer_id
ORDER BY Total_no_of_days_visited DESC;

-- 3. What was the first item from the menu purchased by each customer?

SELECT 
    s.customer_id AS Customer_ID,
	m.product_name AS First_Ordered_Item
FROM
	(SELECT 
    customer_id,
    order_date,
    product_id,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS rank_of_order
FROM
    sales) as s
        JOIN
    menu m ON s.product_id = m.product_id
WHERE rank_of_order = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
    m.product_name AS Most_purchased_item, 
    s.Total_times_ordered
FROM
    (SELECT DISTINCT
        product_id,
        COUNT(customer_id) OVER(PARTITION BY product_id) Total_times_ordered
    FROM
        sales) AS s
        JOIN
    menu m ON m.product_id = s.product_id
ORDER BY s.Total_times_ordered DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH Most_Popular_Item AS(
SELECT 
        s.customer_id,
            m.product_name,
            COUNT(m.product_name) AS count,
				RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(m.product_name) DESC) AS rank_no
    FROM
        sales s
    JOIN menu m ON s.product_id = m.product_id
    GROUP BY m.product_name , s.customer_id
    ORDER BY s.customer_id , count DESC , m.product_name DESC)
SELECT 
    MPI.customer_id, MPI.product_name, MPI.count
FROM
    Most_Popular_Item AS MPI
WHERE
    MPI.rank_no = 1
ORDER BY MPI.count DESC;


-- 6. Which item was purchased first by the customer after they became a member?

WITH Item_Just_After_Member AS (
SELECT 
        s.customer_id, s.product_id, m.product_name, s.order_date,
        RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank_no
    FROM
        sales s
    JOIN menu m ON m.product_id = s.product_id
    JOIN members mm ON mm.customer_id = s.customer_id
        AND s.order_date >= mm.join_date
    ORDER BY s.customer_id , s.order_date)
SELECT 
    AM.customer_id, 
    AM.product_id, 
    AM.product_name, 
    AM.order_date
FROM
	Item_Just_After_Member AM
WHERE AM.rank_no = 1;


-- 7. Which item was purchased just before the customer became a member?

WITH Item_Just_Before_Member AS (
SELECT 
        s.customer_id, s.product_id, m.product_name, s.order_date,
        RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rank_no
    FROM
        sales s
    JOIN menu m ON m.product_id = s.product_id
    JOIN members mm ON mm.customer_id = s.customer_id
        AND s.order_date < mm.join_date
    ORDER BY s.customer_id , s.order_date)
SELECT 
    BM.customer_id, 
    BM.product_id, 
    BM.product_name, 
    BM.order_date
FROM
	Item_Just_Before_Member BM
WHERE BM.rank_no = 1;


-- 8. What is the total items and amount spent for each member before they became a member?
      
WITH Before_Member AS (
    SELECT 
        s.customer_id, 
        SUM(m.price) OVER(PARTITION BY s.customer_id) as Total_Amount_Spent
    FROM
        sales s
    JOIN menu m ON m.product_id = s.product_id
    JOIN members mm ON mm.customer_id = s.customer_id
        AND s.order_date < mm.join_date
    ORDER BY s.customer_id , s.order_date)
SELECT DISTINCT
    BM.customer_id AS Customer_ID, BM.Total_Amount_Spent
FROM Before_Member BM;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH Points_Calculator AS
(SELECT 
    s.customer_id, m.*,
    CASE
        WHEN m.product_name = 'sushi' THEN m.price * 20
        ELSE m.price * 10
    END AS Points
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id)
SELECT DISTINCT
    PC.customer_id AS Customer_ID,
    SUM(PC.Points) OVER(PARTITION BY PC.customer_id) AS Points_Earned
FROM
    Points_Calculator PC;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?

WITH POINTS_EARNED_IN_JAN AS(
SELECT 
    s.*, m.product_name, m.price,
    CASE
		WHEN s.order_date >= mm.join_date AND s.order_date <= (mm.join_date + Interval  7 day) THEN m.price * 20
        WHEN m.product_name = 'sushi' THEN m.price * 20
        ELSE m.price * 10
    END AS Points
FROM
    sales s
        JOIN
    menu m ON m.product_id = s.product_id
        JOIN
    members mm ON mm.customer_id = s.customer_id 
WHERE
    s.order_date BETWEEN '2021-01-01' AND '2021-01-31')
SELECT DISTINCT
    PC.customer_ID AS Customer_ID,
    SUM(PC.Points) OVER(PARTITION BY PC.customer_id) AS Points_Earned
FROM
    POINTS_EARNED_IN_JAN AS PC;

/* --------------------
   BONUS Questions
   --------------------*/

-- 1. Join of all thing

SELECT 
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
        WHEN s.order_date >= memb.join_date THEN 'Y'
        ELSE 'N'
    END AS Member
FROM
    sales s
        LEFT JOIN
    menu m ON s.product_id = m.product_id
        LEFT JOIN
    members memb ON s.customer_id = memb.customer_id
ORDER BY s.customer_id , s.order_date, m.price DESC;

-- 2. Ranking of all thing

WITH Rank_of_all_thing AS(
SELECT 
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
        WHEN s.order_date >= memb.join_date THEN 'Y'
        ELSE 'N'
    END AS Member
FROM
    sales s
        LEFT JOIN
    menu m ON s.product_id = m.product_id
        LEFT JOIN
    members memb ON s.customer_id = memb.customer_id
ORDER BY s.customer_id , s.order_date, m.price desc)
SELECT 
    c1.*,
    CASE
        WHEN c1.Member = 'N' THEN 'NULL'
        ELSE RANK() OVER(PARTITION BY c1.member,c1.customer_id ORDER BY c1.order_date) 
    END AS RANKING
FROM
    Rank_of_all_thing c1
ORDER BY c1.customer_id , c1.order_date , c1.price DESC;



