-- queries.sql
-- Support Ticket SQL Analytics — analysis queries
-- Written for MySQL 8+. On PostgreSQL, replace TIMESTAMPDIFF(HOUR, a, b)
-- with EXTRACT(EPOCH FROM (b - a)) / 3600.

-- 1. Average resolution time by priority (resolved tickets only)
-- Business question: how long does it actually take to close a ticket,
-- broken down by how urgent it was marked?
SELECT
    priority,
    COUNT(*)                                            AS resolved_tickets,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, created_at, resolved_at)), 1) AS avg_resolution_hours
FROM tickets
WHERE resolved_at IS NOT NULL
GROUP BY priority
ORDER BY FIELD(priority, 'Urgent', 'High', 'Medium', 'Low');


-- 2. SLA compliance rate by priority
-- Business question: what share of tickets in each priority tier were
-- actually resolved within their target SLA window?
SELECT
    priority,
    sla_hours,
    COUNT(*)                                                        AS resolved_tickets,
    SUM(CASE WHEN TIMESTAMPDIFF(HOUR, created_at, resolved_at) <= sla_hours
             THEN 1 ELSE 0 END)                                     AS within_sla,
    ROUND(100.0 * SUM(CASE WHEN TIMESTAMPDIFF(HOUR, created_at, resolved_at) <= sla_hours
                            THEN 1 ELSE 0 END) / COUNT(*), 1)        AS sla_compliance_pct
FROM tickets
WHERE resolved_at IS NOT NULL
GROUP BY priority, sla_hours
ORDER BY FIELD(priority, 'Urgent', 'High', 'Medium', 'Low');


-- 3. Ticket volume and average resolution time per agent
-- Business question: how is workload distributed across the team, and
-- who's resolving tickets fastest on average?
SELECT
    a.agent_name,
    a.team,
    COUNT(t.ticket_id)                                             AS total_tickets,
    SUM(CASE WHEN t.resolved_at IS NULL THEN 1 ELSE 0 END)         AS open_tickets,
    ROUND(AVG(CASE WHEN t.resolved_at IS NOT NULL
                   THEN TIMESTAMPDIFF(HOUR, t.created_at, t.resolved_at) END), 1)
                                                                     AS avg_resolution_hours
FROM agents a
LEFT JOIN tickets t ON t.agent_id = a.agent_id
GROUP BY a.agent_id, a.agent_name, a.team
ORDER BY total_tickets DESC;


-- 4. Top 5 customers by ticket volume
-- Business question: which accounts are generating the most support load?
-- (Worth cross-checking against plan tier — is it mostly Enterprise accounts?)
SELECT
    c.customer_name,
    c.plan_tier,
    COUNT(t.ticket_id) AS ticket_count
FROM customers c
JOIN tickets t ON t.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.plan_tier
ORDER BY ticket_count DESC
LIMIT 5;


-- 5. Ticket count by category
-- Business question: what kinds of issues make up the bulk of the queue?
SELECT
    category,
    COUNT(*) AS ticket_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM tickets), 1) AS pct_of_total
FROM tickets
GROUP BY category
ORDER BY ticket_count DESC;


-- 6. Currently open tickets, oldest first
-- Business question: which open tickets need attention first?
SELECT
    t.ticket_id,
    c.customer_name,
    a.agent_name,
    t.priority,
    t.status,
    t.created_at,
    TIMESTAMPDIFF(HOUR, t.created_at, NOW()) AS hours_open
FROM tickets t
JOIN customers c ON c.customer_id = t.customer_id
JOIN agents a    ON a.agent_id = t.agent_id
WHERE t.resolved_at IS NULL
ORDER BY t.created_at ASC;


-- 7. Monthly trend: tickets opened vs. tickets resolved
-- Business question: is the queue growing or shrinking month over month?
SELECT
    DATE_FORMAT(created_at, '%Y-%m')                                   AS month,
    COUNT(*)                                                            AS opened,
    SUM(CASE WHEN resolved_at IS NOT NULL
             AND DATE_FORMAT(resolved_at, '%Y-%m') = DATE_FORMAT(created_at, '%Y-%m')
             THEN 1 ELSE 0 END)                                         AS resolved_same_month
FROM tickets
GROUP BY DATE_FORMAT(created_at, '%Y-%m')
ORDER BY month;


-- 8. Rank agents by average resolution time (window function)
-- Business question: who are the fastest resolvers on the team, ranked?
SELECT
    agent_name,
    team,
    avg_resolution_hours,
    RANK() OVER (ORDER BY avg_resolution_hours ASC) AS speed_rank
FROM (
    SELECT
        a.agent_name,
        a.team,
        ROUND(AVG(TIMESTAMPDIFF(HOUR, t.created_at, t.resolved_at)), 1) AS avg_resolution_hours
    FROM agents a
    JOIN tickets t ON t.agent_id = a.agent_id
    WHERE t.resolved_at IS NOT NULL
    GROUP BY a.agent_id, a.agent_name, a.team
) AS agent_avg
ORDER BY speed_rank;
