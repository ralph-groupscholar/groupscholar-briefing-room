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

    const callsQuery = client.query(
      `
        select id,
               title,
               summary,
               owner,
               lane,
               decision_by,
               confidence,
               created_at
        from briefing_room.decision_calls
        order by created_at desc
        limit 3;
      `
    );

    const metricsQuery = client.query(
      `
        select label, value, detail, position
        from briefing_room.decision_metrics
        order by position asc;
      `
    );

    const [callsResult, metricsResult] = await Promise.all([
      callsQuery,
      metricsQuery
    ]);

    res.setHeader("Cache-Control", "s-maxage=60, stale-while-revalidate=300");
    res.status(200).json({
      updatedAt: new Date().toISOString(),
      calls: callsResult.rows,
      metrics: metricsResult.rows
    });
  } catch (error) {
    res.status(500).json({
      error: "Failed to load decision calls",
      details: error.message
    });
  } finally {
    await client.end();
  }
};
