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
          category,
          headline,
          summary,
          owner,
          open_count,
          sla_status,
          response_sla_hours,
          updated_at
        from briefing_room.support_pulse
        order by
          case
            when lower(sla_status) = 'breached' then 1
            when lower(sla_status) = 'at risk' then 2
            when lower(sla_status) = 'on track' then 3
            else 4
          end,
          open_count desc,
          updated_at desc
        limit 6;
      `
    );

    const summaryQuery = client.query(
      `
        select
          count(*)::int as lanes,
          sum(open_count)::int as open_tickets,
          count(*) filter (where lower(sla_status) = 'at risk')::int as at_risk,
          count(*) filter (where lower(sla_status) = 'breached')::int as breached,
          round(avg(response_sla_hours))::int as avg_sla,
          max(updated_at) as latest_update
        from briefing_room.support_pulse;
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
      error: "Failed to load support pulse",
      details: error.message
    });
  } finally {
    await client.end();
  }
};
