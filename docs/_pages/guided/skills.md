---
title: "Power Up Cline with Skills"
permalink: /guided/skills/
layout: single
classes: wide
---

## 🧠 From Generic Assistant to MongoDB Expert

Out of the box, Cline is a great general-purpose coding assistant. **Cline Skills** are MongoDB-authored instruction sets that turn it into a domain expert—covering schema design, query optimization, search, and more. They're already pre-installed in your workspace.

---

### 🔍 Step 1: Find Your Skills

The Skills panel lives behind the **⚖ scale icon** in the Cline chat input area (not in Settings).

1. Click the **Cline** icon in the VSCode sidebar to open the chat panel.
2. In the chat input, click the **⚖ scale icon**.
3. You should see a list of MongoDB skills, including:
   - `mongodb-schema-design`
   - `mongodb-natural-language-querying`
   - `mongodb-query-optimizer`
   - `mongodb-search-and-ai`
   - `mongodb-mcp-setup`
   - `mongodb-connection`
   - `atlas-stream-processing`

**⚠️ Note:** If you don't see any skills, reload the window: `☰ > View > Command Palette… > Developer: Reload Window`.

---

### 🤖 Step 2: Try the Schema Design Skill

**📋 Prompt:** Start a new chat in Cline and paste this in:

> Use the **mongodb-schema-design** skill. I'm migrating from a Postgres schema where `bookings`, `listings`, `hosts`, `addresses`, and `reviews` are five tables joined by foreign keys. I'm tempted to create five collections in MongoDB with `ObjectId` references that mimic the foreign keys. Why is that a mistake, and what should I actually do? Be specific about which tables to merge and which to keep separate, and why.

---

### 🎯 Step 3: Review the Response

The skill-powered answer should reference MongoDB-specific concepts by name. Look for:

- **Anti-patterns** called out explicitly (e.g., `excessive-lookups`, `unnecessary-collections`)
- **Design patterns** named (e.g., `extended-reference`, `bucket`, `computed`)
- **The embed-vs-reference framework** applied per relationship (1:1, 1:few, 1:many, M:N)
- A concrete recommendation, for example:
  - **Embed** `address` into `listings` (1:1, always accessed together)
  - **Extended reference** for `host` inside `listings` (cache `name` and `picture_url`, keep full host doc separate)
  - **Reference** for `reviews` (unbounded, can grow past the 16MB document limit)
  - **Reference** for `bookings` (independent lifecycle, queried separately)
- The guiding principle quoted: *"Data that is accessed together should be stored together."*

---

### 💡 The Takeaway

**Each major section of this Arena has a matching skill:**
- 📊 Aggregations & slow queries → `mongodb-query-optimizer`
- 🔎 Atlas Search & 🧠 Vector Search → `mongodb-search-and-ai`
- ✏️ Writing queries from scratch → `mongodb-natural-language-querying`

Reach for the **⚖ scale icon** whenever you start a new section. You'll get answers tuned for MongoDB, not generic SQL-flavored guesses.

---

### 📚 Learn More

- [MongoDB Agent Skills on GitHub](https://github.com/mongodb/agent-skills)
- [Cline Skills Documentation](https://docs.cline.bot/features/skills)

{% include simple_next_nav.html %}
