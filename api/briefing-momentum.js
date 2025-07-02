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

    const updatesQuery = client.query(
      `
        select
          id,
          lane,
          headline,
          summary,
          owner,
          metric,
          delta,
          trend,
          updated_at
        from briefing_room.momentum_updates
        order by updated_at desc
        limit 6;
      `
    );

    const summaryQuery = client.query(
      `
        select
          count(*)::int as total,
          count(*) filter (where lower(trend) = 'up')::int as up,
          count(*) filter (where lower(trend) = 'down')::int as down,
          count(*) filter (where lower(trend) = 'flat')::int as flat,
          max(updated_at) as latest_update
        from briefing_room.momentum_updates;
      `
    );

    const [updatesResult, summaryResult] = await Promise.all([
      updatesQuery,
      summaryQuery
    ]);

    res.setHeader("Cache-Control", "s-maxage=60, stale-while-revalidate=300");
    res.status(200).json({
      updatedAt: new Date().toISOString(),
      updates: updatesResult.rows,
      summary: summaryResult.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      error: "Failed to load momentum updates",
      details: error.message
    });
  } finally {
    await client.end();
  }
};
