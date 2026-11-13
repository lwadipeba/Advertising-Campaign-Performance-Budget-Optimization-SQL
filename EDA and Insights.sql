-/*1. What types of interactions are users having with advertisements, 
--and how frequently do they occur*/

select event_type, count(*) as total_events
from ad_events
group by event_type
order by total_events desc;

-- Calculate overall advertising metrics

select
-- Click-Through Rate: Click/Impressions x 100
  round(100.0* count(*) filter (where event_type = 'Click') /
  count(*) filter (where event_type = 'Impression'), 2) as CTR,

-- Engagement rate: (Clicks + Likes + Comments + Shares) / Impressions × 100
  round(100.0 * count(*) filter (where event_type in ('Click', 'Like', 'Comment', 'Share')) /
  count(*) filter (where event_type = 'Impression'), 2) as engagement_rate,

--Purchase-to-click event rate: Purchases / Clicks × 100
  round(100.0 * count(*) filter (where event_type = 'Purchase') /
  count(*) filter (where event_type = 'Click'), 2) as purchase_to_click_rate
  
from ad_events;
-- Engagement: 17.11%
-- CTR: 11.79%
-- Purchase: 5.07%

-/*2. Which campaigns generate the highest engagement  
-and conversion rates and what are their allocated budgets?*/
  
-- Calculate campaign performance using a CTE
-- Which campaigns perform best across engagement and purchase conversion, 
-- rather than just engagement alone?
with campaign_metrics as (
    select
        c.campaign_id, c.name, c.total_budget,
        count(*) filter (where e.event_type = 'Impression') as impressions,
        count(*) filter (where e.event_type = 'Click') as clicks,
        count(*) filter (where e.event_type in ('Click', 'Like', 'Comment', 'Share')) as engagement_events,
        count(*) filter (where e.event_type = 'Purchase') as purchases
    from campaigns c
    join ads a
    on c.campaign_id = a.campaign_id
    join ad_events e
    on a.ad_id = e.ad_id
    group by c.campaign_id, c.name, c.total_budget)

select
    campaign_id, name, total_budget,
    round(100.0 * clicks / impressions, 2) as ctr,
    round(100.0 * engagement_events / impressions, 2) as engagement_rate,
    round(100.0 * purchases / clicks, 2) as purchase_rate,
    rank() over (order by cast(engagement_events as numeric) / impressions desc) as engagement_rank,
    rank() over (order by cast(purchases as numeric) / clicks desc) as purchase_rank
from campaign_metrics
order by engagement_rate desc;

-- Campaign_22_Q3: No.1 in engagement but No.33 in purchase
-- Campaign_27_Q3: No. 10 in engagement but No. 1 in purchase
-- suggests that the campaign generating the most engagement isn't
-- necessarily the campaign generating the strongest purchase activity.


/*3. Which advertising platforms and ad formats generate the strongest 
 engagement and purchase conversion? */

-- Which platform generates more impressions, clicks, engagement, and purchase events.
select a.ad_platform,
count(*) filter (where e.event_type = 'Impression') as impressions,
count(*) filter (where e.event_type = 'Click') as clicks,
count(*) filter (where e.event_type in ('Click', 'Like', 'Comment', 'Share')) 
as engagement_events,
count(*) filter (where e.event_type = 'Purchase') as purchases
from ads a
join ad_events e
on a.ad_id = e.ad_id
group by a.ad_platform
order by impressions desc;

-- Facebook generated more activity across all four metrics

-- Compare platform performance metrics
with platform_metrics as (
    select
        a.ad_platform,
        count(*) filter (where e.event_type = 'Impression') as impressions,
        count(*) filter (where e.event_type = 'Click') as clicks,
        count(*) filter (where e.event_type in ('Click', 'Like', 'Comment', 'Share')) as engagement_events,
        count(*) filter (where e.event_type = 'Purchase') as purchases
    from ads a
    join ad_events e
    on a.ad_id = e.ad_id
    group by a.ad_platform)
select
    ad_platform,
    round(100.0 * clicks / impressions, 2) as ctr,
    round(100.0 * engagement_events / impressions, 2) as engagement_rate,
    round(100.0 * purchases / clicks, 2) as purchase_rate
from platform_metrics
order by purchase_rate desc;

-- CTR and Engagement rate: Instagram is slightly better
-- Purchase Rate: Facebook is stronger at turing clicks into purchases

-- Which ad formats generate the strongest engagement and purchase rates?
--  and compare ad format performance rates
with ad_metrics as (
    select
        a.ad_type,
        count(*) filter (where e.event_type = 'Impression') as impressions,
        count(*) filter (where e.event_type = 'Click') as clicks,
        count(*) filter (where e.event_type in ('Click', 'Like', 'Comment', 'Share'))
        as engagement_events,
        count(*) filter (where e.event_type = 'Purchase') as purchases
    from ads a
    join ad_events e
    on a.ad_id = e.ad_id
    group by a.ad_type)
select
    ad_type, impressions, clicks, engagement_events, purchases,
    round(100.0 * clicks / impressions, 2) as ctr,
    round(100.0 * engagement_events / impressions, 2) as engagement_rate,
    round(100.0 * purchases / clicks, 2) as purchase_rate
from ad_metrics
order by purchase_rate desc;

-- Engagement rate: Video is highest
-- Purchase Rate: Stories is highest


/*4. Do different gender and age groups respond differently to advertising campaigns?*/
-- Calculate and rank metrics across different genders and age group
with valid_users as (
    select user_id
    from users
    group by user_id
    having count(*) = 1),
demographic_metrics as (
    select
        u.user_gender,
        u.age_group,
        count(*) filter (where e.event_type = 'Impression') as impressions,
        count(*) filter (where e.event_type = 'Click') as clicks,
        count(*) filter (
        where e.event_type in ('Click', 'Like', 'Comment', 'Share')) as engagement_events,
        count(*) filter (where e.event_type = 'Purchase') as purchases
    from users u
    join valid_users v
    on u.user_id = v.user_id
    join ad_events e
    on u.user_id = e.user_id
    group by u.user_gender, u.age_group)
select
    user_gender, age_group,
    round(100.0 * clicks / impressions, 2) as ctr,
    round(100.0 * engagement_events / impressions, 2) as engagement_rate,
    round(100.0 * purchases / clicks, 2) as purchase_rate,
    rank() over ( order by cast(engagement_events as numeric) / impressions desc) 
    as engagement_rank,
    rank() over (order by cast(purchases as numeric) / clicks desc) as purchase_rank
from demographic_metrics
order by purchase_rank desc;

-- Other 45-44 has the highest engangement ranking and purchase rankings
 
/*5. How do day of the week and time of day relate to advertising performance? */
with timing_metrics as (
    select day_of_week, time_of_day,
        count(*) filter (where event_type = 'Impression') as impressions,
        count(*) filter (where event_type = 'Click') as clicks,
        count(*) filter (where event_type in ('Click', 'Like', 'Comment', 'Share')) 
        as engagement_events,
        count(*) filter (where event_type = 'Purchase') as purchases
    from ad_events
    group by day_of_week, time_of_day)
    
select day_of_week, time_of_day,
    round(100.0 * clicks / impressions, 2) as ctr,
    round(100.0 * engagement_events / impressions, 2) as engagement_rate,
    round(100.0 * purchases / clicks, 2) as purchase_rate,
    rank() over (order by cast(engagement_events as numeric) / impressions desc) 
    as engagement_rank,
    rank() over (order by cast(purchases as numeric) / clicks desc) as purchase_rank
from timing_metrics
order by purchase_rate desc;

-- Thursday afternoon has the highest purchase rate.
-- Friday afternoon has the highest engagement rate.
-- Engagement and purchase activity peak at different times.

/* Budget Optimization*/

-- Campaign budget and performance comparison
with campaign_metrics as (
    select c.campaign_id, c.name, c.total_budget,
        count(*) filter (where e.event_type = 'Impression') as impressions,
        count(*) filter (where e.event_type = 'Click') as clicks,
        count(*) filter (where e.event_type in ('Click', 'Like', 'Comment', 'Share')) 
        as engagement_events,
        count(*) filter (where e.event_type = 'Purchase') as purchases
    from campaigns c
    join ads a
    on c.campaign_id = a.campaign_id
    join ad_events e
    on a.ad_id = e.ad_id
    group by c.campaign_id, c.name, c.total_budget)
select campaign_id, name, total_budget,
    round(100.0 * engagement_events / impressions, 2) as engagement_rate,
    round(100.0 * purchases / clicks, 2) as purchase_rate,
    case when purchases > 0 -- handling when a campaign has 0 purchases
        then round(cast(total_budget as numeric) / purchases, 2)
        else null
    end as budget_per_purchase,
    rank() over (order by cast(total_budget as numeric) / nullif(purchases, 0) asc nulls last)
    as budget_per_purchase_rank
from campaign_metrics
order by purchase_rate desc;
