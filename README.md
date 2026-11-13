# Advertising Campaign Performance & Budget Optimization

## Project Overview

**Central business question**

> How can businesses evaluate campaign performance, identify the factors
> driving successful campaigns, and allocate future advertising budgets
> more effectively?

This project uses relational advertising data to evaluate campaign
performance, investigate factors associated with engagement and purchase
activity, and develop evidence-based recommendations for future
advertising budget allocation.

The analysis is conducted in **PostgreSQL**, using **DBeaver**. For this project, the four tables (`users`, `ads`, `campaigns`, and `ad_events`) were supplied and analyzed as CSV files imported into PostgreSQL.

**Dataset source:** [Social Media Advertisement Performance ---
Kaggle](https://www.kaggle.com/datasets/alperenmyung/social-media-advertisement-performance?resource=download&select=ad_campaign_db.sqlite)

The project follows four phases:

1. Data Familiarization & Documentation
2. Data Preparation, Cleaning & Evaluation
3. Exploratory Analysis & Insight Generation
4. Synthesis & Recommendations

> **Scope note:** The uploaded files contain campaign budgets and user
> advertising events, but do not include actual advertising spend or
> purchase revenue. Therefore, this project can assess engagement,
> purchase-event activity, and budget-allocation efficiency proxies. It
> cannot calculate actual ROAS, profit, or true cost per acquisition.

---
# Phase 1: Data Familiarization & Documentation

## 1.1 Dataset Inventory

The project analyzes four relational tables from the Kaggle dataset.
| Table | Rows | Columns | Description |
|---|---:|---:|---|
| `users` | 10,000 | 7 | Customer demographics, location, and interests |
| `ads` | 200 | 7 | Ad platform, format, campaign association, and targeting |
| `campaigns` | 50 | 6 | Campaign dates, duration, and allocated budget |
| `ad_events` | 400,000 | 7 | Recorded user interactions with advertisements |
| **Total** | **410,250** | **27** | |

The row and column counts above were verified against the supplied CSV
files.

## 1.2 Database Relationships

The tables are related as follows:

``` text
campaigns
   |
   | campaign_id
   | one campaign can have multiple ads
   v
ads
   |
   | ad_id
   | one ad can generate multiple events
   v
ad_events
   |
   | user_id
   | events are associated with users
   v
users
```

Key relationships:

- `campaigns.campaign_id` → `ads.campaign_id`
- `ads.ad_id` → `ad_events.ad_id`
- `users.user_id` → `ad_events.user_id` (logical relationship; the
    users table contains duplicate `user_id` values and requires
    investigation before treating it as a one-to-one customer lookup).

To analyze campaign outcomes, join `campaigns` to `ads` and then to
`ad_events`. To analyze customer characteristics, join `ad_events` to
`users` after resolving duplicate user records.

## 1.3 Data Dictionary

### Table: `users`

**Purpose:** Stores customer demographic, geographic, and interest
information. These fields support audience segmentation and analysis of
which customer groups interact with advertisements.

| Field | PostgreSQL type | Business definition |
|---|---|---|
| `user_id` | `VARCHAR(10)` | Identifier associated with a user record. Duplicate values exist and must be investigated. |
| `user_gender` | `VARCHAR(20)` | Recorded gender category for the user. |
| `user_age` | `INTEGER` | Recorded age of the user. |
| `age_group` | `VARCHAR(10)` | Age band assigned to the user. |
| `country` | `VARCHAR(100)` | Country associated with the user. |
| `location` | `VARCHAR(100)` | More specific user location, apparently a city or locality; exact definition should be confirmed. |
| `interests` | `TEXT` | Comma-separated or text-form list of user interests; representation and categorization need validation. |

### Table: `ads`

**Purpose:** Describes each advertisement, its platform, creative
format, campaign association, and intended audience.

| Field | PostgreSQL type | Business definition |
|---|---|---|
| `ad_id` | `INTEGER` | Unique identifier for an advertisement. |
| `campaign_id` | `INTEGER` | Identifier of the campaign to which the ad belongs. |
| `ad_platform` | `VARCHAR(50)` | Platform where the advertisement is served (observed values include Facebook and Instagram). |
| `ad_type` | `VARCHAR(50)` | Advertisement creative or placement format (observed categories include Stories, Image, Carousel, and Video). |
| `target_gender` | `VARCHAR(20)` | Gender audience selected for targeting. |
| `target_age_group` | `VARCHAR(20)` | Age band selected for targeting. |
| `target_interests` | `TEXT` | Interest criteria used to define the intended audience. |



### Table: `campaigns`

**Purpose:** Stores campaign identifiers, names, scheduling information,
duration, and budget allocation.

| Field | PostgreSQL type | Business definition |
|---|---|---|
| `campaign_id` | `INTEGER` | Unique identifier for a campaign. |
| `name` | `VARCHAR(100)` | Campaign name or label. |
| `start_date` | `DATE` | Scheduled campaign start date. |
| `end_date` | `DATE` | Scheduled campaign end date. |
| `duration_days` | `INTEGER` | Recorded campaign duration. The observed values equal `end_date - start_date`; confirm whether the convention excludes one endpoint. |
| `total_budget` | `NUMERIC(12,2)` | Campaign budget amount. Currency and whether this is planned, allocated, or spent need clarification. |

### Table: `ad_events`

**Purpose:** Records individual interactions between users and
advertisements. This is the largest table and the main source of
observed advertising activity.

| Field | PostgreSQL type | Business definition |
|---|---|---|
| `event_id` | `INTEGER` | Unique identifier for an event record. |
| `ad_id` | `INTEGER` | Identifier of the advertisement associated with the event. |
| `user_id` | `VARCHAR(10)` | Identifier associated with the user who generated the event. |
| `timestamp` | `TIMESTAMP` | Date and time at which the event was recorded. |
| `day_of_week` | `VARCHAR(20)` | Day of the week associated with the event. |
| `time_of_day` | `VARCHAR(20)` | Broad time-of-day category associated with the event. |
| `event_type` | `VARCHAR(30)` | Type of recorded interaction. Observed categories include Impression, Click, Like, Comment, Purchase, and Share. |

## 1.4 Initial Dataset Observations

The following characteristics were observed during initial inspection:

- The dataset contains 10,000 user records, 200 ads, 50 campaigns, and
    400,000 ad-event records.
- The ads data contains two observed platforms: Facebook and
    Instagram.
- The ads data contains four observed formats: Stories, Image,
    Carousel, and Video.
- The ad-events data contains six observed event types: Impression,
    Click, Like, Comment, Purchase, and Share.
- The users data contains 10 countries.
- The users table has 9,950 distinct `user_id` values across 10,000
    records, indicating 50 records beyond the distinct-ID count.
- No exact duplicate rows were found in the initial file-level
    inspection.
- No missing values were found in the initial file-level inspection.
- Campaign `duration_days` values match the difference between
    `end_date` and `start_date` in the supplied data. The business
    convention for counting inclusive calendar days remains to be
    confirmed.

These are initial observations, not a substitute for the more detailed
quality checks in Phase 2.

## 1.5 Ambiguous Fields and Clarification Questions

| Field / concept | Ambiguity to resolve | Why it matters |
|---|---|---|
| `total_budget` | What currency is used? Is this planned, allocated, or actual spend? | Determines which budget-efficiency measures are valid. |
| `event_type = Purchase` | Does each event represent a completed, paid transaction, or only a purchase-intent event? | Determines whether purchase events can be treated as conversions. |
| Event records | Are events deduplicated, and can one user generate multiple events of the same type for the same ad? | Affects event counts and conversion-rate definitions. |
| `duration_days` | Are start and end dates counted inclusively? | Affects daily budget calculations and campaign comparisons. |
| `interests` / `target_interests` | Are interests single values or multi-value text fields? What taxonomy is used? | Affects audience matching and segmentation. |
| `location` | Does this field represent city, region, or another geographic unit? | Affects geographic comparisons. |
| `time_of_day` | What exact hour ranges define Morning, Afternoon, Evening, and Night? Which timezone is used? | Affects scheduling analysis. |

## 1.6 Additional Data That Would Strengthen the Analysis

The current dataset supports analysis of recorded engagement and
purchase-event activity. The following additional data would improve
business interpretation and budget decisions:

| Additional data needed | Analytical benefit |
|---|---|
| Actual advertising spend by campaign, ad, and platform | Calculate actual cost per click, cost per acquisition, and spend efficiency. |
| Revenue and order value for each purchase | Calculate ROAS, revenue per customer, and campaign profitability. |
| Unique impressions / reach and frequency | Distinguish total impressions from unique people reached and assess ad fatigue. |
| Conversion attribution window and exposure history | Understand the relationship between ad exposure and later purchases. |
| Campaign objectives | Compare campaigns against the outcomes they were designed to achieve. |
| New vs. returning customer indicator | Separate acquisition performance from retention or repeat purchasing. |


# Phase 2: Data Preparation, Cleaning & Evaluation

## 2.1 Quality Checks and Findings


| Quality check | Finding | Interpretation |
|---|---:|---|
| Duplicate `user_id` values | 50 | The `users` table contains 50 IDs that appear more than once. |
| Conflicting user profiles | 50 IDs | Each repeated ID was found with different demographic/profile information. |
| Advertising events linked to those IDs | 3,967 | These event records may match multiple user profiles in a direct join. |
| Duplicate `event_id` values | 0 | No repeated event IDs were returned. |
| Duplicate `ad_id` values | 0 | No repeated ad IDs were returned. |
| Duplicate `campaign_id` values | 0 | No repeated campaign IDs were returned. |
| Missing records in `users` | 0 | No rows with NULLs in the checked user fields were found. |
| Missing records in `ads` | 0 | No rows with NULLs in the checked ad fields were found. |
| Missing records in `campaigns` | 0 | No rows with NULLs in the checked campaign fields were found. |
| Missing records in `ad_events` | 0 | No rows with NULLs in the checked event fields were found. |
| Invalid user ages (`user_age` < 0 or > 100) | 0 | No out-of-range ages were returned. |
| Invalid campaign date ranges (`end_date` < `start_date`) | 0 | No campaigns with an end date before the start date were returned. |

The 3,967 events associated with repeated user IDs represent
approximately 0.99% of the 400,000 event records.

## 2.2 Cleaning Decisions

- **Preserve the raw tables.** No source records have been deleted or
    overwritten.
- **Do not arbitrarily remove the repeated user profiles.** The 50
    repeated IDs have different profile information, and the available
    data does not establish which profile is correct.
- **Exclude unresolved user IDs from demographic analysis.** When
    analyzing demographics, filter out the 50 repeated IDs until their
    identity/profile conflict can be resolved.
- **Use event data cautiously for analyses that do not require user
    demographics.** Campaign, ad, and event-level analysis can proceed
    without joining to the problematic user profiles, subject to the
    other metric limitations documented above.

# Phase 3: Exploratory Analysis & Insight Generation

## 3.1 Business Questions

1. Which campaigns generate the highest engagement and conversion
    rates, and what are their allocated budgets?
2. Which advertising platforms and ad formats generate the strongest
    engagement and purchase conversion?
3. Which customer demographics and interest groups are most responsive
    to advertising campaigns?
4. How do campaign timing and user engagement patterns influence
    advertising performance?
5. How should businesses prioritize future advertising budgets based on
    campaign performance and conversion outcomes?

## 3.2 Metric Definitions Used

- **CTR:** Click events / impression events × 100.
- **Engagement events:** Clicks + likes + comments + shares.
- **Engagement rate:** Engagement events / impression events × 100.
- **Purchase-to-click rate:** Purchase events / click events × 100.
- **Budget per purchase event:** Allocated campaign budget / purchase
    events.

## 3.3 Overall Event Performance

The event table contains 400,000 records:

| Event type | Event count | Share of all events |
|---|---:|---:|
| Impression | 339,812 | 84.95% |
| Click | 40,079 | 10.02% |
| Like | 12,013 | 3.00% |
| Comment | 4,108 | 1.03% |
| Purchase | 2,031 | 0.51% |
| Share | 1,957 | 0.49% |

Overall calculated rates:

| Metric | Result |
|---|---:|
| CTR | 11.79% |
| Engagement rate | 17.11% |
| Purchase-to-click event rate | 5.07% |


## 3.4 Campaign Performance

Campaign-level metrics were calculated by joining `campaigns`, `ads`,
and `ad_events`.

Top five campaigns by engagement rate:

| Campaign | Engagement rate |
|---|---:|
| Campaign 22 Q3 | 18.28% |
| Campaign 40 Summer | 18.17% |
| Campaign 12 Q3 | 18.04% |
| Campaign 19 Winter | 17.71% |
| Campaign 7 Winter | 17.71% |

Top five campaigns by purchase-to-click event rate:

| Campaign | Purchase rate |
|---|---:|
| Campaign 27 Q3 | 8.40% |
| Campaign 31 Summer | 7.13% |
| Campaign 23 Winter | 6.94% |
| Campaign 33 Summer | 6.08% |
| Campaign 38 Q3 | 6.03% |

Campaign 22 ranked first in engagement but 33rd in purchase rate, while
Campaign 27 ranked first in purchase rate and 10th in engagement. This
demonstrates that high engagement does not necessarily correspond to the
strongest purchase activity.

The campaign analysis used inner joins, so it covered the 48 campaigns
represented in the `ads` table, rather than all 50 campaigns.

## 3.5 Platform Performance

| Platform | CTR | Engagement rate | Purchase-to-click rate |
|---|---:|---:|---:|
| Facebook | 11.76% | 17.04% | 5.21% |
| Instagram | 11.86% | 17.24% | 4.82% |

Instagram had slightly higher CTR and engagement, while Facebook had a
higher purchase-to-click event rate. The differences are descriptive and
do not establish that platform choice caused the outcomes.

## 3.6 Ad Format Performance

| Ad format | CTR | Engagement rate | Purchase-to-click rate |
|---|---:|---:|---:|
| Stories | 11.73% | 17.10% | 5.34% |
| Carousel | 11.72% | 17.00% | 5.13% |
| Video | 11.90% | 17.22% | 5.07% |
| Image | 11.88% | 17.18% | 4.67% |

Video had the highest engagement rate, while Stories had the highest
purchase-to-click event rate. Image ads had the lowest purchase-to-click
event rate among the four formats.

## 3.7 Demographic Patterns

The demographic analysis excluded the 50 user IDs with conflicting
profiles to avoid duplicating event records in the join.

Selected observations:

- The `Other`, 45--54 segment had the highest observed
    purchase-to-click rate at 9.15%, based on 13 purchase events from
    142 clicks.
- The Male, 55--65 segment had a 7.34% purchase-to-click rate.
- The Female, 35--44 segment had a 6.16% purchase-to-click rate and
    124 purchase events.

The highest rates in small segments should be interpreted cautiously.
Purchase volume and sample size matter alongside conversion rates.

## 3.8 Timing Patterns

The strongest observed purchase-to-click event rates included:

| Day and time | Purchase-to-click rate |
|---|---:|
| Thursday Afternoon | 6.03% |
| Thursday Morning | 5.95% |
| Monday Night | 5.80% |
| Saturday Afternoon | 5.65% |
| Sunday Night | 5.50% |

Friday Afternoon had the highest engagement rate at 17.81%. These
patterns can inform future scheduling tests, but they do not prove that
timing caused higher engagement or purchase activity.

## 3.9 Budget Efficiency Proxy

The analysis compared each campaign's allocated budget with its number
of purchase events. Campaign 42 (Summer) had the lowest observed
allocated-budget-per-purchase-event proxy at 118.18 and ranked first on
this measure. Its purchase-to-click event rate was 4.20%.

## 3.10 SQL Techniques Demonstrated

The project uses:

- Multi-table `JOIN`s to connect campaigns, ads, events, and users.
- `GROUP BY` and aggregate functions to summarize activity.
- `FILTER (WHERE ...)` for conditional event counts.
- CTEs (`WITH`) to organize multi-step calculations.
- `CASE WHEN` to handle conditional metric calculations.
- `CAST()` to avoid integer division and support numeric calculations.
- Window functions such as `RANK()` to compare campaign and segment
    performance.
- `NULLIF()` and `NULLS LAST` to handle zero denominators in ranking
    calculations.

# Phase 4: Synthesis & Recommendations

## 4.1 Key Takeaways

1. **Engagement and purchase outcomes differ.** Campaign 22 led on
    engagement rate but ranked 33rd on purchase rate. Campaign 27 led on
    purchase rate, showing why campaigns should be evaluated against
    multiple performance measures.
2. **Platform results vary by objective.** Instagram had slightly
    higher CTR and engagement, while Facebook had a higher
    purchase-to-click event rate.
3. **Creative format results vary.** Video led on engagement rate,
    while Stories led on purchase-to-click event rate.
4. **Audience segments need both rate and volume analysis.** Some
    segments showed high purchase rates with relatively few purchase
    events, while Female 35--44 had a larger observed purchase count.
5. **Timing patterns can guide testing.** Thursday afternoon had the
    highest purchase-to-click event rate, while Friday afternoon had the
    highest engagement rate.

## 4.2 Business Recommendations

- **Use a balanced campaign scorecard.** Evaluate campaigns using
    engagement rate, purchase-to-click event rate, purchase-event
    volume, and allocated budget rather than ranking campaigns on
    engagement alone.
- **Align platform choice with campaign objectives.** Consider testing
    Instagram for engagement-focused activity and Facebook for
    purchase-focused activity, while validating results through
    controlled tests.
- **Test creative formats by objective.** Use Video as a candidate for
    engagement-focused tests and Stories as a candidate for
    purchase-focused tests. Avoid assuming the observed differences will
    persist across audiences and campaigns.
- **Prioritize audiences using both conversion rate and volume.**
    Investigate promising demographic segments, but avoid reallocating
    substantial budget based only on high rates from small samples.
- **Run scheduling experiments.** Test Thursday afternoon for
    purchase-oriented campaigns and Friday afternoon for
    engagement-oriented campaigns, using comparable audiences and
    creative.
- **Use budget-efficiency proxies cautiously.** Review allocated
    budget per purchase event together with purchase rate and purchase
    volume. Obtain actual spend and revenue data before making
    profitability or CPA decisions.
- **Reallocate budgets incrementally and measure results.** Run
    controlled budget tests, compare outcomes against a baseline, and
    scale only when improved performance is sustained.

## 4.3 Limitations

- `total_budget` represents an allocated campaign budget; actual
    advertising spend is not available.
- The currency for campaign budgets is not specified.
- Revenue and order values are unavailable, so ROAS and profitability
    cannot be calculated.
- Purchase events have not been independently verified as completed,
    paid transactions.
- CTR, engagement rate, and purchase-to-click rate are event-level
    measures, not unique-user conversion metrics.
- The 50 conflicting user IDs were excluded from demographic analysis.
- Campaign-level analysis used inner joins and included the 48
    campaigns represented in the ads table.
- Campaign objectives, and timezone definitions are not available.

## 4.4 Further Data Needed

To make stronger budget allocation decisions, the business should
collect actual spend, attributed revenue, order values, unique reach,
frequency, campaign objectives, conversion attribution details, and
controlled experiment results.

## 4.5 Final Conclusion

The analysis shows that campaign performance depends on the metric being
evaluated. The campaigns and formats with the strongest engagement are
not always those with the strongest purchase activity. Therefore engagement, purchase-event rates, purchase volume, nd budget information should be further evaluated together. The results provide useful directions
for further testing, but actual spend and revenue data are required
before making definitive profitability or return-on-advertising-spend
decisions.

## Project Tools

- **Database:** PostgreSQL
- **SQL environment:** DBeaver
- **Version control / portfolio:** GitHub
- **Dataset:** Social Media Advertisement Performance, by alperenmyung
- **Dataset source:** [Kaggle dataset
    page](https://www.kaggle.com/datasets/alperenmyung/social-media-advertisement-performance)
- **Source file linked on Kaggle:** `ad_campaign_db.sqlite`
- **Working data:** Four CSV tables (`users`, `ads`, `campaigns`,
    `ad_events`) imported into PostgreSQL
