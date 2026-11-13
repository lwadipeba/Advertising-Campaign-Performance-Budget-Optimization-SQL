--Check row counts for all four tables

select 'ad_events' as table_name, count(*) as table_row_counts from ad_events
union all
select 'ads', count(*) from ads
union all
select 'campaigns', count(*) from campaigns
union all
select 'users', count(*) from users;


-- Check for duplicate records
select user_id, count(*) as record_count
from users
group by user_id
having count(*) > 1
order by record_count desc;


-- Inspecting duplicate records
select * from users
where user_id in (
select user_id from users
group by user_id
having count(*) > 1)
order by user_id;
/*potentional user ID integrity issues, repeated user_ids are associatied with
different user information*/

-- Count how many user IDs have conflicing profiles
select count(*) as conflicting_user_ids
from (select user_id from users
group by user_id
having count(distinct (user_gender, user_age, age_group, country, location, interests)) > 1
) as duplicates;

--  See how many advertising events are affected by duplicate user_ids
select count(*) as affected_events
from ad_events
where user_id in 
(select user_id from users
group by user_id
having count(*) > 1);


-- Check for duplicate event IDs
select event_id, count(*) as record_count
from ad_events
group by event_id
having count(*) > 1;
-- no duplicates

-- Check for duplicate ads
select ad_id, count(*) from ads
group by ad_id 
having count(*) > 1;
-- no duplicates

-- Check for duplicate campaigns
select campaign_id, count(*) from campaigns
group by campaign_id 
having count(*) > 1;
-- no duplicates


-- Check for null values in users
select count(*) as missing_user_records
from users
where num_nulls(user_id, user_gender, user_age, age_group, 
country, location, interests) > 0;
-- no missing records

-- Check for null values in ads
select count(*) as missing_records
from ads
where num_nulls(ad_id, campaign_id, ad_platform, ad_type,
target_gender, target_age_group, target_interests) > 0;
-- no missing records

-- Check for null values in campaigns
select count(*) as missing_records
from campaigns
where num_nulls(campaign_id, name, start_date, end_date,
duration_days, total_budget) > 0;
-- no missing records

-- Check for null values in campaigns
select count(*) as missing_records
from ad_events
where num_nulls(event_id, ad_id, user_id, timestamp,
day_of_week, time_of_day, event_type) > 0;
-- no missing records

-- Check for invalid values
-- User ages
select * from users
where user_age < 0 or user_age > 100;

-- Campaigns
-- no 0 or -ve budgets
select * from campaigns where total_budget <=0;

-- validating campaign dates
select * from campaigns
where end_date < start_date;

-- Check for invalid advertising events
select distinct event_type from ad_events
order by event_type;

-- Check whether every advertising event is linked to an existing ad.
select * from ad_events
where ad_id not in ( select ad_id from ads );




