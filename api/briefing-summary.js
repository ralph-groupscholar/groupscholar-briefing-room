const { Client } = require("pg");

const buildConfig = () => {
  if (process.env.DATABASE_URL) {
    return {
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false }
    };
  }

  return {
    host: process.env.PGHOST,
    port: process.env.PGPORT ? Number(process.env.PGPORT) : 5432,
    user: process.env.PGUSER,
    password: process.env.PGPASSWORD,
    database: process.env.PGDATABASE || "postgres",
    ssl: { rejectUnauthorized: false }
  };
};

module.exports = async (req, res) => {
  const client = new Client(buildConfig());

  try {
    await client.connect();

    const summaryQuery = client.query(
      `
        select
          count(*)::int as total,
          count(*) filter (where lower(urgency) = 'high')::int as high,
          count(*) filter (where lower(urgency) = 'medium')::int as medium,
          count(*) filter (where lower(urgency) = 'low')::int as low,
          count(*) filter (
            where target_date is not null
              and target_date <= current_date + interval '7 days'
          )::int as due_soon,
          count(*) filter (
            where target_date is not null
              and target_date < current_date
          )::int as overdue,
          max(created_at) as latest_signal_at
        from briefing_room.signal_entries;
      `
    );

    const ownersQuery = client.query(
      `
        select owner, count(*)::int as count
        from briefing_room.signal_entries
        group by owner
        order by count desc, owner asc
        limit 4;
      `
    );

    const [summaryResult, ownersResult] = await Promise.all([
      summaryQuery,
      ownersQuery
    ]);

    res.setHeader("Cache-Control", "s-maxage=60, stale-while-revalidate=300");
    res.status(200).json({
      updatedAt: new Date().toISOString(),
      summary: summaryResult.rows[0],
      owners: ownersResult.rows
    });
  } catch (error) {
    res.status(500).json({
      error: "Failed to load briefing summary",
      details: error.message
    });
  } finally {
    await client.end();
  }
};
