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
    const result = await client.query(
      `
        select id,
               title,
               summary,
               owner,
               urgency,
               target_date,
               source,
               created_at
        from briefing_room.signal_entries
        order by created_at desc
        limit 6;
      `
    );

    res.setHeader("Cache-Control", "s-maxage=60, stale-while-revalidate=300");
    res.status(200).json({
      updatedAt: new Date().toISOString(),
      signals: result.rows
    });
  } catch (error) {
    res.status(500).json({
      error: "Failed to load briefing signals",
      details: error.message
    });
  } finally {
    await client.end();
  }
};
