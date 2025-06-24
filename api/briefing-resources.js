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

    const requestsQuery = client.query(
      `
        select
          id,
          request_type,
          title,
          justification,
          owner,
          status,
          priority,
          needed_by,
          impact,
          created_at
        from briefing_room.resource_requests
        order by
          priority desc,
          needed_by nulls last,
          created_at desc
        limit 6;
      `
    );

    const summaryQuery = client.query(
      `
        select
          count(*)::int as total,
          count(*) filter (where lower(status) = 'pending')::int as pending,
          count(*) filter (where lower(status) = 'in review')::int as in_review,
          count(*) filter (where lower(status) = 'approved')::int as approved,
          count(*) filter (where lower(status) = 'fulfilled')::int as fulfilled,
          count(*) filter (
            where needed_by is not null
              and needed_by <= current_date + interval '7 days'
          )::int as due_soon,
          count(*) filter (
            where needed_by is not null
              and needed_by < current_date
              and lower(status) != 'fulfilled'
          )::int as overdue,
          max(created_at) as latest_request_at
        from briefing_room.resource_requests;
      `
    );

    const [requestsResult, summaryResult] = await Promise.all([
      requestsQuery,
      summaryQuery
    ]);

    res.setHeader("Cache-Control", "s-maxage=60, stale-while-revalidate=300");
    res.status(200).json({
      updatedAt: new Date().toISOString(),
      requests: requestsResult.rows,
      summary: summaryResult.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      error: "Failed to load resource requests",
      details: error.message
    });
  } finally {
    await client.end();
  }
};
