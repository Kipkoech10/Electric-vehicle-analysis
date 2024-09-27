use [Electric vehicles analysis];

select *
from dbo.electric_vehicle_sales_by_makers

select *
from dbo.electric_vehicle_sales_by_state

select *
from dbo.dim_date

-- 1.List the top 3 and bottom 3 makers for the fiscal years 2023 and 2024 in terms of the number of 2-wheelers sold.

select maker,sum(electric_vehicles_sold) as total_sales,fiscal_year
from dbo.electric_vehicle_sales_by_makers as m
left join dbo.dim_date as d
on m.date = d.date
where vehicle_category = '2-wheelers' and fiscal_year in( 2023, 2024)
group  by maker,fiscal_year
order by  fiscal_year desc,total_sales desc

-- for the fiscal year 2024 the top 3 makers of ev's were	OLA ELECTRIC,TVS,ATHER  and the bottom 3 were BATTRE ELECTRIC,REVOLT,KINETIC GREEN
-- for the fiscal year 2023 the top 3 makers of ev's were	OLA ELECTRIC,IKONAWA,HERO ELECTRIC  and the bottom 3 were JITENDRA,BEING,PURE EV

-- 2. Identify the top 5 states with the highest penetration rate in 2-wheeler and 4-wheeler EV sales in FY 2024.
SELECT DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'electric_vehicle_sales_by_state'
AND COLUMN_NAME = 'electric_vehicles_sold';

ALTER TABLE dbo.electric_vehicle_sales_by_state
ALTER COLUMN electric_vehicles_sold FLOAT;


select 
state,vehicle_category ,
(sum(electric_vehicles_sold) / sum(total_vehicles_sold)) * 100 as penetration_rate
from dbo.electric_vehicle_sales_by_state as s
left join dbo.dim_date as d
on s.date = d.date
where fiscal_year = 2024 and vehicle_category in ('2-wheelers','4-wheelers')
group by state,vehicle_category
order by vehicle_category asc,penetration_rate desc;

-- in the 4 wheeler category kerala,chandigarh,delhi,karnataka,goa had the highest penetration rates respectively
-- in the 2 wheeler category goa,kerala,karnataka,maharashtra,delhi had the highest penetration rates respectively

-- 3. List the states with negative penetration (decline) in EV sales from 2022 to 2024?

WITH PenetrationRates AS (
  SELECT
    d.fiscal_year,
    s.state,
    s.vehicle_category,
    SUM(s.electric_vehicles_sold) AS total_evs_sold,
    SUM(s.total_vehicles_sold) AS total_vehicles_sold,
    (CAST(SUM(s.electric_vehicles_sold) AS FLOAT) / NULLIF(SUM(s.total_vehicles_sold), 0)) * 100 AS penetration_rate
  FROM
    dbo.electric_vehicle_sales_by_state AS s
  LEFT JOIN
    dbo.dim_date AS d ON s.date = d.date
  GROUP BY
    d.fiscal_year, s.state, s.vehicle_category
)
SELECT
  p2022.state,
  p2022.vehicle_category,
  p2022.penetration_rate AS rate_2022,
  p2024.penetration_rate AS rate_2024,
  p2024.penetration_rate - p2022.penetration_rate AS rate_change
FROM
  PenetrationRates p2022
JOIN
  PenetrationRates p2024 ON p2022.state = p2024.state AND p2022.vehicle_category = p2024.vehicle_category
WHERE
  p2022.fiscal_year = 2022
  AND p2024.fiscal_year = 2024

ORDER BY
vehicle_category,
  rate_change DESC;

  -- ladakh,andaman & nicobar island are the states with a negative penetration rate 

  -- 4.quarterly trends based on sales volume for the top 5 EV makers (4-wheelers) from 2022 to 2024?
with evsales as (
	select 
	d.fiscal_year,
	d.quarter,
	m.maker,
	sum(m.electric_vehicles_sold) as quartely_sales
	from dbo.electric_vehicle_sales_by_makers as m
	left join dbo.dim_date as d
	on m.date = d.date
	where m.vehicle_category = '4-wheelers' and fiscal_year between 2022 and 2024
	group by d.fiscal_year,d.quarter,m.maker
),top5makers as (
	select top 5
	maker,
	sum(quartely_sales) as total_sales
	from evsales
	group by maker
	order by total_sales desc
),quartelytrends  as (
	select 
	e.fiscal_year,
	e.maker,
	e.quarter,
	e.quartely_sales,
	ROW_NUMBER() over (partition by e.fiscal_year,e.quarter order by e.quartely_sales desc) as rank_in_quarter
	from evsales as e
	join top5makers t on e.maker = t.maker
)
select fiscal_year,quarter,maker,quartely_sales
from quartelytrends
where rank_in_quarter <= 5
order by fiscal_year,quarter,quartely_sales desc;

-- 5.How do the EV sales and penetration rates in Delhi compare to Karnataka for 2024? 
select state,vehicle_category ,
(sum(electric_vehicles_sold) / sum(total_vehicles_sold)) * 100 as penetration_rate
from dbo.electric_vehicle_sales_by_state as s
left join dbo.dim_date as d
on s.date = d.date
where fiscal_year = 2024 and state = 'Delhi'
group by state,vehicle_category
order by vehicle_category asc,penetration_rate desc

select state,vehicle_category ,
(sum(electric_vehicles_sold) / sum(total_vehicles_sold)) * 100 as penetration_rate
from dbo.electric_vehicle_sales_by_state as s
left join dbo.dim_date as d
on s.date = d.date
where fiscal_year = 2024 and state = 'Karnataka'
group by state,vehicle_category
order by vehicle_category asc,penetration_rate desc;
-- in the 2 wheeler category karnataka has a higher penetration rate than delhi
-- in the 4 wheeler category both states  are within the same range in terms of penetration rate

-- 6.List down the compounded annual growth rate (CAGR) in 4-wheeler units for the top 5 makers from 2022 to 2024. 

WITH EV_Sales AS (
    SELECT 
        d.fiscal_year,
        m.maker,
        SUM(m.electric_vehicles_sold) AS annual_sales
    FROM 
        dbo.electric_vehicle_sales_by_makers m
    LEFT JOIN 
        dbo.dim_date d ON m.date = d.date
    WHERE 
        m.vehicle_category = '4-Wheelers'
        AND d.fiscal_year IN (2022, 2023, 2024)
    GROUP BY 
        d.fiscal_year, m.maker
),
Top_5_Makers AS (
    SELECT TOP 5
        maker,
        SUM(annual_sales) AS total_sales
    FROM 
        EV_Sales
    GROUP BY 
        maker
    ORDER BY 
        total_sales DESC
),
Annual_Sales AS (
    SELECT 
        e.maker,
        MAX(CASE WHEN e.fiscal_year = 2022 THEN e.annual_sales ELSE 0 END) AS sales_2022,
        MAX(CASE WHEN e.fiscal_year = 2023 THEN e.annual_sales ELSE 0 END) AS sales_2023,
        MAX(CASE WHEN e.fiscal_year = 2024 THEN e.annual_sales ELSE 0 END) AS sales_2024
    FROM 
        EV_Sales e
    JOIN 
        Top_5_Makers t ON e.maker = t.maker
    GROUP BY 
        e.maker
)
SELECT 
    maker,
    sales_2022 AS [Sales 2022],
    sales_2023 AS [Sales 2023],
    sales_2024 AS [Sales 2024],
    CASE 
        WHEN sales_2022 > 0 THEN 
            (POWER(CAST(sales_2024 AS FLOAT) / CAST(sales_2022 AS FLOAT), 0.5) - 1) * 100
        ELSE 
            NULL
    END AS [CAGR (%)]

FROM 
    Annual_Sales
ORDER BY 
    [CAGR (%)] DESC;

-- 7. List down the top 10 states that had the highest compounded annual growth rate (CAGR) from 2022 to 2024 in total vehicles sold.
WITH State_Sales AS (
    SELECT 
        d.fiscal_year,
        s.state,
        SUM(s.total_vehicles_sold) AS annual_sales
    FROM 
        dbo.electric_vehicle_sales_by_state s
    JOIN 
        dbo.dim_date d ON s.date = d.date
    WHERE 
        d.fiscal_year IN (2022, 2023, 2024)
    GROUP BY 
        d.fiscal_year, s.state
),
State_Annual_Sales AS (
    SELECT 
        state,
        MAX(CASE WHEN fiscal_year = 2022 THEN annual_sales ELSE 0 END) AS sales_2022,
		MAX(CASE WHEN fiscal_year = 2023 THEN annual_sales ELSE 0 END) AS sales_2023,
        MAX(CASE WHEN fiscal_year = 2024 THEN annual_sales ELSE 0 END) AS sales_2024
    FROM 
        State_Sales
    GROUP BY 
        state
),
State_CAGR AS (
    SELECT 
        state,
        sales_2022,
		sales_2023,
        sales_2024,
        CASE 
            WHEN sales_2022 > 0 THEN 
                (POWER(CAST(sales_2024 AS FLOAT) / CAST(sales_2022 AS FLOAT), 1.0/2) - 1) * 100
            ELSE 
                NULL
        END AS cagr_percentage
    FROM 
        State_Annual_Sales
)
SELECT TOP 10
    state AS 'State',
    sales_2022 AS 'Total Vehicles Sold 2022',
	sales_2023 AS 'Total Vehicles Sold 2023',
    sales_2024 AS 'Total Vehicles Sold 2024',
    ROUND(cagr_percentage, 2) AS 'CAGR (%)'
FROM 
    State_CAGR
WHERE 
    cagr_percentage IS NOT NULL
ORDER BY 
    cagr_percentage DESC;

-- 8. What are the peak and low season months for EV sales based on the data from 2022 to 2024? 

WITH quarterly_sales AS (
    SELECT 
        d.fiscal_year,
        d.quarter,
        SUM(electric_vehicles_sold) AS total_sales
    FROM 
        dbo.electric_vehicle_sales_by_state s
    LEFT JOIN 
        dbo.dim_date AS d ON s.date = d.date
    WHERE 
        d.fiscal_year IN (2022, 2023, 2024)
    GROUP BY 
       d.fiscal_year, d.quarter
),
yearly_stats AS (
    SELECT 
        fiscal_year,
        MAX(total_sales) AS max_sales,
        MIN(total_sales) AS min_sales
    FROM 
        quarterly_sales
    GROUP BY 
        fiscal_year
)
SELECT 
    qs.fiscal_year, 
    qs.quarter, 
    qs.total_sales,
    CASE 
        WHEN qs.total_sales = ys.max_sales THEN 'Peak'
        WHEN qs.total_sales = ys.min_sales THEN 'Low'
        ELSE 'Regular'
    END AS season
FROM 
    quarterly_sales qs
JOIN 
    yearly_stats ys ON qs.fiscal_year = ys.fiscal_year
ORDER BY 
    qs.fiscal_year, qs.quarter
 
-- 9.What is the projected number of EV sales (including 2-wheelers and 4wheelers) for the top 10 states by penetration rate in 2030, based on the 
--  compounded annual growth rate (CAGR) from previous years?
WITH yearly_sales AS (
SELECT
state,
fiscal_year,
SUM(electric_vehicles_sold) AS ev_sales,
SUM(total_vehicles_sold) AS total_sales
FROM dbo.electric_vehicle_sales_by_state
LEFT JOIN dbo.dim_date ON electric_vehicle_sales_by_state.date = dim_date.date
WHERE vehicle_category IN ('2-Wheelers', '4-Wheelers')
GROUP BY state, fiscal_year
),
state_year_bounds AS (
SELECT
state,
MIN(fiscal_year) AS min_year,
MAX(fiscal_year) AS max_year
FROM yearly_sales
GROUP BY state
),
state_cagr AS (
SELECT
yearly_sales.state,
(POWER(CAST(y_end.ev_sales AS FLOAT) / NULLIF(y_start.ev_sales, 0),
1.0 / (state_year_bounds.max_year - state_year_bounds.min_year)) - 1) * 100 AS cagr
FROM state_year_bounds
JOIN yearly_sales y_start ON state_year_bounds.state = y_start.state AND state_year_bounds.min_year = y_start.fiscal_year
JOIN yearly_sales y_end ON state_year_bounds.state = y_end.state AND state_year_bounds.max_year = y_end.fiscal_year
JOIN yearly_sales ON state_year_bounds.state = yearly_sales.state
GROUP BY yearly_sales.state, y_start.ev_sales, y_end.ev_sales, state_year_bounds.min_year, state_year_bounds.max_year
),
current_penetration AS (
SELECT
state,
ev_sales,
total_sales,
CAST(ev_sales AS FLOAT) / NULLIF(total_sales, 0) * 100 AS penetration_rate,
ROW_NUMBER() OVER (ORDER BY CAST(ev_sales AS FLOAT) / NULLIF(total_sales, 0) DESC) AS rank
FROM yearly_sales
WHERE fiscal_year = (SELECT MAX(fiscal_year) FROM yearly_sales)
),
top_10_states AS (
SELECT state, penetration_rate, ev_sales
FROM current_penetration
WHERE rank <= 10
)
SELECT
top_10_states.state,
top_10_states.penetration_rate AS current_penetration_rate,
top_10_states.ev_sales AS current_ev_sales,
state_cagr.cagr,
ROUND(top_10_states.ev_sales * POWER(1 + state_cagr.cagr / 100, 2030 - (SELECT MAX(fiscal_year) FROM yearly_sales)), 0) AS projected_ev_sales_2030
FROM top_10_states
JOIN state_cagr ON top_10_states.state = state_cagr.state
ORDER BY top_10_states.penetration_rate DESC;


-- 10 Estimate the revenue growth rate of 4-wheeler and 2-wheelers EVs in India for 2022 vs 2024 and 2023 vs 2024,
-- assuming an average unit price
WITH EV_Sales AS (
    SELECT 
        d.fiscal_year,
        s.vehicle_category,
        SUM(CAST(s.electric_vehicles_sold AS BIGINT)) AS total_ev_sales
    FROM 
        dbo.electric_vehicle_sales_by_state s
    JOIN 
        dbo.dim_date d ON s.date = d.date
    WHERE 
        d.fiscal_year IN (2022, 2023, 2024)
        AND s.vehicle_category IN ('2-wheelers', '4-wheelers')
    GROUP BY 
        d.fiscal_year, s.vehicle_category
),
EV_Revenue AS (
    SELECT 
        fiscal_year,
        vehicle_category,
        total_ev_sales,
        CASE 
            WHEN vehicle_category = '2-wheelers' THEN total_ev_sales * 85000
            WHEN vehicle_category = '4-wheelers' THEN total_ev_sales * 1500000
        END AS estimated_revenue
    FROM 
        EV_Sales
),
Revenue_Growth AS (
    SELECT 
        r2024.vehicle_category,
        r2024.estimated_revenue AS revenue_2024,
        r2023.estimated_revenue AS revenue_2023,
        r2022.estimated_revenue AS revenue_2022,
        (r2024.estimated_revenue - r2023.estimated_revenue) / r2023.estimated_revenue AS growth_rate_2023_2024,
        (r2024.estimated_revenue - r2022.estimated_revenue) / r2022.estimated_revenue AS growth_rate_2022_2024
    FROM 
        EV_Revenue r2024
    JOIN 
        EV_Revenue r2023 ON r2024.vehicle_category = r2023.vehicle_category AND r2023.fiscal_year = 2023
    JOIN 
        EV_Revenue r2022 ON r2024.vehicle_category = r2022.vehicle_category AND r2022.fiscal_year = 2022
    WHERE 
        r2024.fiscal_year = 2024
)
SELECT 
    vehicle_category AS 'Vehicle Category',
    CAST(revenue_2022 / 1000000 AS DECIMAL(18,2)) AS 'Revenue 2022 (Million INR)',
    CAST(revenue_2023 / 1000000 AS DECIMAL(18,2)) AS 'Revenue 2023 (Million INR)',
    CAST(revenue_2024 / 1000000 AS DECIMAL(18,2)) AS 'Revenue 2024 (Million INR)',
    CAST(growth_rate_2023_2024 * 100 AS DECIMAL(18,2)) AS 'Growth Rate 2023 vs 2024 (%)',
    CAST(growth_rate_2022_2024 * 100 AS DECIMAL(18,2)) AS 'Growth Rate 2022 vs 2024 (%)'
FROM 
    Revenue_Growth
ORDER BY 
    vehicle_category;

