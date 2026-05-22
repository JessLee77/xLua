---
name: env-jsonc-setup
description: Setup env.jsonc configuration file for db-tools module - guides user through creating database connection config with interactive questions
allowedTools:
  - Question
  - Write
  - Read
---

# Database Configuration Setup

This skill guides users through creating an `env.jsonc` file for configuring db-tools module.

## Overview

The `env.jsonc` file contains database connection settings for db-tools. This skill:
1. Collects database preferences (type, host, port, credentials)
2. Generates a properly formatted `env.jsonc` file with comments
3. Places it in the current working directory

## Workflow

Follow these steps EXACTLY as described.

### Step 1: Determine Database Type

Use the question tool to ask the user which database type they want to configure:

Options:
- **MySQL** (Recommended for local development, SQL databases)
- **MongoDB** (For NoSQL databases, MongoDB Atlas)

### Step 2: Ask Connection Details

Based on the database type selected, use the question tool to gather connection details.

#### For MySQL:
Ask for:
1. **Host** (default: "localhost")
2. **Port** (default: 3306)
3. **Database name** (required)
4. **Username** (required)
5. **Password** (optional, can be empty)
6. **Connection timeout** (default: 10000 ms)

#### For MongoDB:
Ask for:
1. **Connection method**:
   - Individual parameters (host, port, username, password)
   - Connection URI (recommended for Atlas)

If "Individual parameters":
   - **Host** (default: "localhost")
   - **Port** (default: 27017)
   - **Database name** (required)
   - **Username** (optional)
   - **Password** (optional)
   - **Connection timeout** (default: 10000 ms)

If "Connection URI":
   - **MongoDB URI** (required, e.g., `mongodb+srv://user:pass@cluster.mongodb.net/db`)
   - **Database name** (required)
   - **Connection timeout** (default: 10000 ms)

### Step 3: Check if env.jsonc Already Exists

Check if `env.jsonc` exists in the working directory:

```bash
test -f "env.jsonc" && echo "exists" || echo "not exists"
```

If the file exists:
- Use the question tool to ask: "env.jsonc already exists. Overwrite?"
  - Options: "Yes, overwrite", "No, keep existing"

If user selects "No", skip to Step 5 and report that no changes were made.

If user selects "Yes" or file doesn't exist, continue to Step 4.

### Step 4: Generate and Write env.jsonc

Create the `env.jsonc` file based on user's answers using the Write tool.

#### Template for MySQL:

```jsonc
{
  "db-tools": {
    "type": "mysql",
    "host": "<HOST>",
    "port": <PORT>,
    "database": "<DATABASE>",
    "username": "<USERNAME>",
    "password": "<PASSWORD>",
    "connectionTimeout": <TIMEOUT>
  }
}
```

Replace placeholders with user-provided values. If `password` is empty, use `""`.

#### Template for MongoDB (Individual Parameters):

```jsonc
{
  "db-tools": {
    "type": "mongodb",
    "host": "<HOST>",
    "port": <PORT>,
    "database": "<DATABASE>",
    "username": "<USERNAME>",
    "password": "<PASSWORD>",
    "connectionTimeout": <TIMEOUT>
  }
}
```

Replace placeholders with user-provided values. If `username` or `password` is empty, use `""`.

#### Template for MongoDB (Connection URI):

```jsonc
{
  "db-tools": {
    "type": "mongodb",
    "uri": "<MONGODB_URI>",
    "database": "<DATABASE>",
    "connectionTimeout": <TIMEOUT>
  }
}
```

Replace placeholders with user-provided values.

Use the Write tool to create `env.jsonc` with the generated content in the working directory.

### Step 5: Provide Usage Instructions

After the file is created, provide the user with:

1. **Configuration location**: `env.jsonc` in current working directory
2. **Database type**: The type configured
3. **Quick test command** (optional suggestion):

For testing connection:
- "Try using dbListTables tool to verify the connection works"
- "The configuration will be automatically loaded on first db-tools usage"

## Important Notes

- The `env.jsonc` file uses JSONC format (JSON with comments)
- Sensitive information like passwords are stored in plain text
- Add `env.jsonc` to `.gitignore` to avoid committing credentials
- The configuration is automatically loaded by db-tools on first tool use
- Comments in the file help document different use cases

## Error Handling

If at any point the user provides invalid input:
- Ask again with the same question
- Provide helpful hints (e.g., "Port must be a number between 1-65535")

## Examples

### MySQL Local Development:
```jsonc
{
  "db-tools": {
    "type": "mysql",
    "host": "localhost",
    "port": 3306,
    "database": "devdb",
    "username": "root",
    "password": "",
    "connectionTimeout": 10000
  }
}
```

### MongoDB Local:
```jsonc
{
  "db-tools": {
    "type": "mongodb",
    "host": "localhost",
    "port": 27017,
    "database": "mydb",
    "username": "admin",
    "password": "secret",
    "connectionTimeout": 10000
  }
}
```

### MongoDB Atlas:
```jsonc
{
  "db-tools": {
    "type": "mongodb",
    "uri": "mongodb+srv://user:pass@cluster0.mongodb.net/proddb?authSource=admin",
    "database": "proddb",
    "connectionTimeout": 10000
  }
}
```
