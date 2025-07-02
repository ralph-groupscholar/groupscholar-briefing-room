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

    const itemsQuery = client.query(
      `
        select
          id,
          category,
          issue,
          impact,
          owner,
          status,
          eta,
          severity,
          created_at
        from briefing_room.escalation_watch
        order by created_at desc
        limit 6;
      `
    );

    const summaryQuery = client.query(
      `
        select
          count(*)::int as total,
          count(*) filter (where lower(status) = 'open')::int as open,
          count(*) filter (where lower(status) = 'pending')::int as pending,
          count(*) filter (where lower(status) = 'resolved')::int as resolved,
          max(created_at) as latest_update
        from briefing_room.escalation_watch;
      `
    );

    const [itemsResult, summaryResult] = await Promise.all([
      itemsQuery,
      summaryQuery
    ]);

    res.setHeader("Cache-Control", "s-maxage=60, stale-while-revalidate=300");
    res.status(200).json({
      updatedAt: new Date().toISOString(),
      items: itemsResult.rows,
      summary: summaryResult.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      error: "Failed to load escalations",
      details: error.message
    });
  } finally {
    await client.end();
  }
};
