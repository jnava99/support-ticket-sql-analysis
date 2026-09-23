-- schema.sql
-- Support Ticket SQL Analytics — table definitions
-- Written for MySQL 8+/PostgreSQL; also runs as-is in SQLite (used for local testing).

CREATE TABLE agents (
    agent_id    INTEGER PRIMARY KEY,
    agent_name  VARCHAR(50) NOT NULL,
    team        VARCHAR(50) NOT NULL
);

CREATE TABLE customers (
    customer_id   INTEGER PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    plan_tier     VARCHAR(20) NOT NULL   -- Free, Pro, Enterprise
);

CREATE TABLE tickets (
    ticket_id    INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL,
    agent_id     INTEGER NOT NULL,
    category     VARCHAR(30) NOT NULL,   -- Billing, Technical, Onboarding, Bug, Account, Feature Request
    priority     VARCHAR(10) NOT NULL,   -- Low, Medium, High, Urgent
    status       VARCHAR(15) NOT NULL,   -- Open, In Progress, Resolved, Closed
    sla_hours    INTEGER NOT NULL,       -- target resolution time in hours, based on priority
    created_at   DATETIME NOT NULL,
    resolved_at  DATETIME,               -- NULL while the ticket is still open
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (agent_id) REFERENCES agents(agent_id)
);
