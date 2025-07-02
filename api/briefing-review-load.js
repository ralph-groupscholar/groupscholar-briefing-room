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
          stage,
          queue_size,
          reviewers_ready,
          sla_days,
          risk_level,
          owner,
          next_action,
          updated_at
        from briefing_room.review_load_forecast
        order by
          case
            when lower(risk_level) = 'high' then 1
            when lower(risk_level) = 'medium' then 2
            else 3
          end,
          queue_size desc,
          updated_at desc
        limit 6;
      `
    );

    const summaryQuery = client.query(
      `
        select
          count(*)::int as lanes,
          sum(queue_size)::int as total_queue,
          round(avg(sla_days))::int as avg_sla,
          count(*) filter (where lower(risk_level) = 'high')::int as high_risk,
          max(updated_at) as latest_update
        from briefing_room.review_load_forecast;
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
      error: "Failed to load review load forecast",
      details: error.message
    });
  } finally {
    await client.end();
  }
};
