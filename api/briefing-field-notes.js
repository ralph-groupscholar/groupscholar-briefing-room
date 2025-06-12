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

    const notesQuery = client.query(
      `
        select id,
               category,
               headline,
               summary,
               source,
               owner,
               spotlight,
               priority,
               created_at
        from briefing_room.field_notes
        order by spotlight desc, priority desc, created_at desc
        limit 4;
      `
    );

    const pulseQuery = client.query(
      `
        select
          count(*)::int as total_notes,
          count(distinct source)::int as listening_posts,
          (select headline
           from briefing_room.field_notes
           order by priority desc, created_at desc
           limit 1) as top_signal
        from briefing_room.field_notes;
      `
    );

    const [notesResult, pulseResult] = await Promise.all([
      notesQuery,
      pulseQuery
    ]);

    res.setHeader("Cache-Control", "s-maxage=60, stale-while-revalidate=300");
    res.status(200).json({
      updatedAt: new Date().toISOString(),
      notes: notesResult.rows,
      pulse: pulseResult.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      error: "Failed to load field notes",
      details: error.message
    });
  } finally {
    await client.end();
  }
};
