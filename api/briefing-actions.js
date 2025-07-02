const { Client } = require("pg");

const buildConfig = () => {
  const sslSetting =
    process.env.PGSSLMODE === "disable" ? false : { rejectUnauthorized: false };

  if (process.env.DATABASE_URL) {
    return {
      connectionString: process.env.DATABASE_URL,
      ssl: sslSetting
    };
  }

  return {
    host: process.env.PGHOST,
    port: process.env.PGPORT ? Number(process.env.PGPORT) : 5432,
    user: process.env.PGUSER,
    password: process.env.PGPASSWORD,
    database: process.env.PGDATABASE || "postgres",
    ssl: sslSetting
  };
};

module.exports = async (req, res) => {
  const client = new Client(buildConfig());

  try {
    await client.connect();

    const actionsQuery = client.query(
      `
        select
          id,
          title,
          summary,
          owner,
          status,
          priority,
          lane,
          due_date,
          created_at
        from briefing_room.action_items
        order by
          case
            when lower(status) = 'blocked' then 1
            when lower(status) = 'in progress' then 2
            when lower(status) = 'queued' then 3
            when lower(status) = 'done' then 4
            else 5
          end,
          due_date nulls last,
          priority desc,
          created_at desc
        limit 6;
      `
    );

    const summaryQuery = client.query(
      `
        select
          count(*)::int as total,
          count(*) filter (where lower(status) = 'blocked')::int as blocked,
          count(*) filter (where lower(status) = 'in progress')::int as in_progress,
          count(*) filter (where lower(status) = 'done')::int as done,
          count(*) filter (
            where due_date is not null
              and due_date <= current_date + interval '7 days'
          )::int as due_soon,
          count(*) filter (
            where due_date is not null
              and due_date < current_date
              and lower(status) != 'done'
          )::int as overdue,
          max(created_at) as latest_action_at
        from briefing_room.action_items;
      `
    );

    const [actionsResult, summaryResult] = await Promise.all([
      actionsQuery,
      summaryQuery
    ]);

    res.setHeader("Cache-Control", "s-maxage=60, stale-while-revalidate=300");
    res.status(200).json({
      updatedAt: new Date().toISOString(),
      actions: actionsResult.rows,
      summary: summaryResult.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      error: "Failed to load action docket",
      details: error.message
    });
  } finally {
    await client.end();
  }
};
