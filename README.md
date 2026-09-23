# Support Ticket SQL Analytics

A small SQL practice project analyzing a synthetic support-ticket dataset — the kind of data model and questions that come up in customer support and technical support operations (ticket volume, SLA compliance, agent workload).

## Why this project

Built as a hands-on way to practice SQL against a dataset that mirrors real support/CS work: multiple related tables, date-based calculations, and the kinds of business questions a support team actually asks (Are we meeting our SLAs? Who's overloaded? Which accounts need attention?).

## Dataset

Three tables, ~50 synthetic tickets spanning Jan–Mar 2026:

| Table | Description |
|---|---|
| `agents` | 6 support agents across two teams (Tier 1, Tier 2) |
| `customers` | 20 fictional customer accounts, each on a Free/Pro/Enterprise plan |
| `tickets` | 50 support tickets, each linked to a customer and an agent, with priority, category, status, an SLA target (in hours), and timestamps |

All data is synthetic — generated for this project, not real customer information.

## How to run

Written for MySQL 8+ (works on PostgreSQL with one tweak — see note in `queries.sql`). Load the files in order:

```bash
mysql -u youruser -p yourdatabase < schema.sql
mysql -u youruser -p yourdatabase < seed_data.sql
mysql -u youruser -p yourdatabase < queries.sql
```

The schema and data also run as-is in SQLite, which is how the logic here was tested.

## Queries

`queries.sql` contains 8 annotated queries, each answering a specific business question:

1. **Average resolution time by priority** — how long tickets actually take to close, by urgency
2. **SLA compliance rate by priority** — % of tickets resolved within their SLA target
3. **Per-agent workload and speed** — ticket volume and average resolution time by agent
4. **Top 5 customers by ticket volume** — which accounts generate the most support load
5. **Ticket volume by category** — what kinds of issues make up the queue
6. **Open tickets, oldest first** — what needs attention right now
7. **Monthly opened vs. resolved trend** — is the queue growing or shrinking
8. **Agents ranked by resolution speed** *(window function)* — `RANK()` over average resolution time

## Sample findings

A few things that came out of running this against the sample data:

- Tier 2 agents resolved tickets faster on average than Tier 1 in this dataset (15–50 hrs vs. 63–74 hrs) — worth digging into whether that's ticket complexity, staffing, or something else before drawing conclusions.
- Low-priority tickets hit 100% SLA compliance, but High and Medium sat closer to 50–55% — the kind of gap a real team would want to investigate.
- Technical and Feature Request tickets made up nearly half the queue (24% and 22%).

*(These are artifacts of the randomly generated sample data, not real findings — but they're the shape of thing this kind of query surfaces on real ticket data.)*

## Next ideas

- Add a `first_response_at` column to analyze first-response time separately from resolution time
- Build a small dashboard (Tableau/Power BI) on top of these queries
- Swap in a real anonymized dataset if one becomes available
