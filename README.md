# PostgreSQL RLS Architecture: Multi-Role Data Isolation

This repository contains the SQL script **(`TEST.SQL`)** used to establish a **robust Row-Level Security (RLS) architecture** in **PostgreSQL**.  

The primary goal of this setup is to ensure **data isolation** within a shared application environment — a **multi-tenant or multi-role system** — preventing users from viewing or modifying data that does not belong to them, based on their assigned role.

---

## 🧩 1. Architecture Overview

This design revolves around the `app_users` table and demonstrates **four distinct levels of access control**:

1. **Administrator** – Full control over all data (RLS bypass)
2. **Standard User** – Can only view their own data
3. **LLM Service** – Inserts and views its own data
4. **Data Scientist** – Inserts, updates, and views their own data

---

## 🔐 2. Defined Roles and Access Groups

### A. Login Roles (Connectable Users/Services)

| Role Name        | Password     | Primary Purpose |
|------------------|--------------|-----------------|
| `alpha_admin`     | `admin@123`   | **Administrator:** Full control over all data, bypassing RLS. |
| `alpha_llm`       | `ai@123`      | **LLM Service:** Expected to insert and view its own data. |
| `alpha_scientist` | `viewer@123`  | **Data Scientist:** Expected to insert, update, and view their own data. |

---

### B. Group Roles (NOLOGIN)

Group roles simplify permission management by grouping similar users or services.

| Group Role   | Members                     | Primary Permission |
|---------------|-----------------------------|--------------------|
| `user_group`  | `alpha_users`               | `SELECT` on all tables. |
| `alpha_devs`  | `alpha_llm`, `alpha_scientist` | `INSERT` on all tables. |

---

### C. Permissions Granted

Permissions are defined broadly on the `public` schema and then restricted **granularly** by **RLS policies** on the `app_users` table.

| Role / Group   | SELECT | INSERT | UPDATE | DELETE | Description |
|----------------|:------:|:------:|:------:|:------:|-------------|
| `alpha_admin`  | ✅ | ✅ | ✅ | ✅ | Full control (bypass RLS) |
| `user_group`   | ✅ | ❌ | ❌ | ❌ | Read-only access |
| `alpha_devs`   | ✅ (via group) | ✅ | ❌ | ❌ | Insert access (for LLM & Scientists) |
| `alpha_scientist` | ✅ | ✅ | ✅ | ❌ | Insert & update own data |

---

## 🧱 3. Row-Level Security (RLS) Policies

RLS is **enabled** on the `app_users` table, and the following policies enforce strict data filtering based on the **`current_user`** (the connecting PostgreSQL role name).

### RLS Policies on `app_users`

| Policy Name        | Target Role(s)      | Usage (Read/View) | Check (Write/Modify) | Access Control Level |
|--------------------|--------------------|--------------------|----------------------|----------------------|
| `admin_policy`     | `alpha_admin`      | `USING (true)` | `WITH CHECK (true)` | Full access (bypass) |
| `user_policy`      | `user_group`       | `USING (user_name = current_user)` | *(None)* | Read own data only |
| `llm_policy`       | `alpha_llm`        | `USING (user_name = current_user)` | `WITH CHECK (user_name = current_user)` | Insert/Read own data |
| `scientist_policy` | `alpha_scientist`  | `USING (user_name = current_user)` | `WITH CHECK (user_name = current_user)` | Update/Read own data |

---

### 🧠 Key RLS Concepts

- **`USING` Clause:**  
  Determines which rows are visible to the user during `SELECT`, `UPDATE`, or `DELETE` operations.

- **`WITH CHECK` Clause:**  
  Determines whether a new row being inserted (`INSERT`) or an updated row (`UPDATE`) satisfies the security policy.  
  Prevents users from inserting or updating data for another role.

---

## ⚙️ 4. Setup and Testing

### Prerequisites

- A PostgreSQL instance (v12+ recommended)
- An existing table named `app_users`
- Superuser access (e.g., `postgres`)

### Example: Creating the `app_users` Table

```sql
CREATE TABLE app_users (
    id SERIAL PRIMARY KEY,
    user_name TEXT NOT NULL,
    email TEXT,
    role TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
