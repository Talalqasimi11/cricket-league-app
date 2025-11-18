require('dotenv').config({ path: './backend/.env' });
const mysql = require('mysql2/promise');

async function testDatabase() {
  console.log('Testing database connection with current environment variables:');
  console.log('DB_HOST:', process.env.DB_HOST);
  console.log('DB_USER:', process.env.DB_USER);
  console.log('DB_NAME:', process.env.DB_NAME);
  console.log('DB_PASS length:', process.env.DB_PASS ? process.env.DB_PASS.length : 'undefined');

  const config = {
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    connectTimeout: 10000,
  };

  try {
    console.log('\n1. Testing basic connection...');
    const connection = await mysql.createConnection(config);
    console.log('✅ Basic connection successful');

    console.log('\n2. Testing simple query...');
    const [rows] = await connection.execute('SELECT 1 as test');
    console.log('✅ Simple query successful:', rows[0]);

    console.log('\n3. Testing database existence...');
    const [dbRows] = await connection.execute('SELECT DATABASE() as current_db');
    console.log('✅ Current database:', dbRows[0]);

    console.log('\n4. Testing teams table access...');
    let tableExists = false;
    try {
      const [teamsRows] = await connection.execute('SELECT COUNT(*) as count FROM teams');
      console.log('✅ Teams table accessible, count:', teamsRows[0].count);
      tableExists = true;
    } catch (err) {
      console.log('⚠️  Teams table access failed:', err.message);
    }

    console.log('\n5. Listing available tables...');
    try {
      const [tables] = await connection.execute('SHOW TABLES');
      console.log('✅ Available tables:', tables.map(row => Object.values(row)[0]));
    } catch (err) {
      console.log('⚠️  Cannot list tables:', err.message);
    }

    if (!tableExists) {
      console.log('\n6. Importing schema...');
      const fs = require('fs');
      const schemaPath = './cricket-league-db/schema.sql';
      if (fs.existsSync(schemaPath)) {
        const schema = fs.readFileSync(schemaPath, 'utf8');
        // Split on semicolons and filter out empty statements
        const statements = schema.split(';').map(s => s.trim()).filter(s => s.length > 0);

        for (let i = 0; i < statements.length; i++) {
          try {
            await connection.execute(statements[i]);
            console.log(`✅ Executed statement ${i + 1}/${statements.length}`);
          } catch (err) {
            console.log(`⚠️  Statement ${i + 1} failed:`, err.message);
          }
        }
        console.log('✅ Schema import completed');
      } else {
        console.log('❌ Schema file not found at:', schemaPath);
      }
    }

    await connection.end();
    console.log('\n✅ Database testing completed');

  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    console.error('Error code:', error.code);
    console.error('Full error:', error);
    process.exit(1);
  }
}

testDatabase();
