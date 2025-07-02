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

    const forecastQuery = client.query(
      `
        select
          id,
          cohort,
          risk_level,
          risk_driver,
          owner,
          risk_score,
          projected_retention,
          next_action,
          next_checkin,
          created_at
        from briefing_room.retention_forecast
        order by
          risk_score desc,
          next_checkin nulls last,
          created_at desc
        limit 6;
      `
    );

    const summaryQuery = client.query(
      `
        select
          count(*)::int as total,
          count(*) filter (where lower(risk_level) = 'critical')::int as critical,
          count(*) filter (where lower(risk_level) = 'high')::int as high_risk,
          count(*) filter (
            where next_checkin is not null
              and next_checkin <= current_date + interval '30 days'
          )::int as due_soon,
          round(avg(projected_retention)::numeric, 1) as avg_retention,
          max(created_at) as latest_update
        from briefing_room.retention_forecast;
      `
    );

    const [forecastResult, summaryResult] = await Promise.all([
      forecastQuery,
      summaryQuery
    ]);

    res.setHeader("Cache-Control", "s-maxage=60, stale-while-revalidate=300");
    res.status(200).json({
      updatedAt: new Date().toISOString(),
      forecast: forecastResult.rows,
      summary: summaryResult.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      error: "Failed to load retention outlook",
      details: error.message
    });
  } finally {
    await client.end();
  }
};
