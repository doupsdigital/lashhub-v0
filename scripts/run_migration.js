import pg from 'pg';
import fs from 'fs';
import path from 'path';

const { Client } = pg;

const client = new Client({
  host: 'db.agcfngaegopeyutjgncl.supabase.co',
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: 'b20eoCxsSlhpHwHQ',
  ssl: {
    rejectUnauthorized: false
  }
});

async function run() {
  try {
    console.log('Lendo o arquivo de migração...');
    const sqlPath = path.join(process.cwd(), 'scripts', 'etapa5_migracao.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('Conectando ao banco de dados Supabase...');
    await client.connect();
    console.log('Conexão estabelecida com sucesso!');

    console.log('Executando migração...');
    await client.query(sql);
    console.log('Migração concluída com sucesso!');
  } catch (err) {
    console.error('Erro ao executar a migração:', err);
  } finally {
    await client.end();
  }
}

run();
