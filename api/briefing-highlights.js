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

    const highlightsQuery = client.query(
      `
        select
          id,
          category,
          headline,
          summary,
          owner,
          impact,
          status,
          created_at
        from briefing_room.executive_highlights
        order by created_at desc
        limit 6;
      `
    );

    const summaryQuery = client.query(
      `
        select
          count(*)::int as total,
          count(*) filter (where lower(category) = 'win')::int as wins,
          count(*) filter (where lower(category) = 'risk')::int as risks,
          count(*) filter (where lower(category) = 'watch')::int as watch,
          max(created_at) as latest_update
        from briefing_room.executive_highlights;
      `
    );

    const [highlightsResult, summaryResult] = await Promise.all([
      highlightsQuery,
      summaryQuery
    ]);

    res.setHeader("Cache-Control", "s-maxage=60, stale-while-revalidate=300");
    res.status(200).json({
      updatedAt: new Date().toISOString(),
      highlights: highlightsResult.rows,
      summary: summaryResult.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      error: "Failed to load executive highlights",
      details: error.message
    });
  } finally {
    await client.end();
  }
};
