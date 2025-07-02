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
          partner_name,
          status,
          readiness_score,
          renewal_date,
          risk_level,
          owner,
          next_step,
          summary,
          updated_at
        from briefing_room.partner_updates
        order by
          renewal_date is null,
          renewal_date asc,
          updated_at desc
        limit 6;
      `
    );

    const metricsQuery = client.query(
      `
        select
          count(*)::int as active,
          round(avg(readiness_score))::int as average_readiness,
          count(*) filter (where lower(risk_level) = 'high')::int as high_risk,
          count(*) filter (
            where renewal_date is not null
              and renewal_date <= current_date + interval '45 days'
          )::int as due_soon,
          max(updated_at) as latest_update
        from briefing_room.partner_updates;
      `
    );

    const [updatesResult, metricsResult] = await Promise.all([
      updatesQuery,
      metricsQuery
    ]);

    res.setHeader("Cache-Control", "s-maxage=60, stale-while-revalidate=300");
    res.status(200).json({
      updatedAt: new Date().toISOString(),
      updates: updatesResult.rows,
      metrics: metricsResult.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      error: "Failed to load partner readiness",
      details: error.message
    });
  } finally {
    await client.end();
  }
};
