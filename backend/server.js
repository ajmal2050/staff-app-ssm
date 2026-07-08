
const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
  user: process.env.DB_USER,
  host: 'postgres',
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: 5432,
});

pool.query(`
  CREATE TABLE IF NOT EXISTS staff (
    id SERIAL PRIMARY KEY, 
    name VARCHAR(100), 
    role VARCHAR(100)
  )
`);

app.get('/api/staff', async (req, res) => {
  const result = await pool.query('SELECT * FROM staff ORDER BY id DESC');
  res.json(result.rows);
});

app.post('/api/staff', async (req, res) => {
  const { name, role } = req.body;
  const result = await pool.query(
    'INSERT INTO staff (name, role) VALUES ($1, $2) RETURNING *',
    [name, role]
  );
  res.json(result.rows[0]);
});

app.listen(5000, () => console.log('Backend running on port 5000'));
