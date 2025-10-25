-- RLS ARCHITECTURE: TEST.SQL
-- This SQL script sets up a test environment for Row-Level Security (RLS) in PostgreSQL.
-- It creates a sample table, defines RLS policies, and inserts test data.  


ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;

CREATE ROLE alpha_admin LOGIN PASSWORD 'admin@123';

-- User sessions in application to login with this access role only
CREATE ROLE alpha_users NOLOGIN;

-- The llm to login with this access role only
CREATE ROLE alpha_llm LOGIN PASSWORD 'ai@123';

-- The scientist to login with this access role only
CREATE ROLE alpha_scientist LOGIN PASSWORD 'viewer@123';

-- Group role to assign multiple users
CREATE ROLE user_group NOLOGIN;
GRANT user_group TO alpha_users;

-- LLM and Scientist are part of developer group
CREATE ROLE alpha_devs NOLOGIN;
GRANT alpha_devs TO alpha_llm, alpha_scientist;

-- Assigning group roles to admin
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO alpha_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO user_group, alpha_llm, alpha_scientist;
GRANT INSERT ON ALL TABLES IN SCHEMA public TO alpha_devs;
GRANT UPDATE ON ALL TABLES IN SCHEMA public TO alpha_scientist;

-- RLS Policies
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY admin_policy
ON app_users
TO alpha_admin
USING (true)
WITH CHECK (true);

CREATE POLICY user_policy
ON app_users
TO user_group
USING (user_name = current_user) --Normal users have only SELECT thus no WITH CHECK needed for minimal optimizations

CREATE POLICY llm_policy
ON app_users
TO alpha_llm
USING (user_name = current_user)
WITH CHECK (user_name = current_user); -- FOR THE INSERT OPERATION BY LLM ROLE

CREATE POLICY scientist_policy
ON app_users
TO alpha_scientist
USING (user_name = current_user)
WITH CHECK (user_name = current_user); -- FOR THE INSERT/UPDATE OPERATION BY SCIENTIST ROLE