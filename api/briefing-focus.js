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

    const focusQuery = client.query(
      `
        select id,
               focus_type,
               title,
               summary,
               owner,
               due_date,
               status,
               created_at
        from briefing_room.focus_items
        order by created_at desc
        limit 6;
      `
    );

    const summaryQuery = client.query(
      `
        select
          count(*)::int as total,
          count(*) filter (where lower(focus_type) = 'risk')::int as risk,
          count(*) filter (where lower(focus_type) = 'experiment')::int as experiment,
          count(*) filter (where lower(focus_type) = 'commitment')::int as commitment,
          max(created_at) as latest_focus_at
        from briefing_room.focus_items;
      `
    );

    const [focusResult, summaryResult] = await Promise.all([
      focusQuery,
      summaryQuery
    ]);

    res.setHeader("Cache-Control", "s-maxage=60, stale-while-revalidate=300");
    res.status(200).json({
      updatedAt: new Date().toISOString(),
      focus: focusResult.rows,
      summary: summaryResult.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      error: "Failed to load briefing focus",
      details: error.message
    });
  } finally {
    await client.end();
  }
};
