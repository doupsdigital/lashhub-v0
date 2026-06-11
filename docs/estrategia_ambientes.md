# Guia de Estratégia: Ambientes Demo vs. Produção no Supabase

Este guia explica detalhadamente a estratégia para gerenciar dois estados do seu sistema (Demonstração com dados fictícios e Produção Limpa para entrega) usando um único código frontend e múltiplos projetos no Supabase.

---

## 1. Visão Geral da Arquitetura

O sistema é dividido em duas partes independentes:
1. **Frontend (React + Vite):** A interface do usuário. O código é exatamente o mesmo para todos os ambientes. Ele descobre a qual banco de dados se conectar lendo as variáveis do arquivo `.env`.
2. **Backend/Database (Supabase):** Responsável por autenticação, banco de dados PostgreSQL, armazenamento de arquivos (Storage) e segurança RLS.

```
+--------------------------+
|  Frontend Local / Web    |
|                          |
|    [ Código React/Vite ]  |
|            |             |
|            v             |
|      [ Arquivo .env ]    |
+------------|-------------+
             |
             | (lê a URL e Chaves configuradas)
             |
             +-------------> [ Se aponta para Projeto A ] ---> Banco de Demonstração (Showroom)
             |
             +-------------> [ Se aponta para Projeto B ] ---> Banco de Produção Limpa (Template)
             |
             +-------------> [ Se aponta para Projeto C ] ---> Novo Cliente Individual
```

---

## 2. Como funcionam os Ambientes Separados

Para manter um sistema com dados simulados para apresentação e outro limpo para vender, você criará dois projetos independentes no Supabase:

### Projeto A: `beauty-demo` (Showroom & Testes)
* **Objetivo:** Demonstrar o funcionamento do sistema para potenciais clientes.
* **Conteúdo:** Contém 25 clientes fictícias, fichas de anamnese preenchidas, histórico financeiro de agendamentos e atendimentos.
* **Uso:** Você abrirá este ambiente em reuniões de vendas para mostrar o Dashboard preenchido e a agenda em funcionamento.

### Projeto B: `beauty-prod` (Template de Produção Limpa)
* **Objetivo:** Servir de ponto de partida para novas instalações.
* **Conteúdo:** Possui a estrutura das tabelas criada (via `schema.sql`), mas sem clientes ou agendamentos cadastrados.
* **Uso:** Quando você vender o sistema para a primeira profissional, você pode usar este banco (ou criar um novo **Projeto C** exclusivo para ela) e conectar o build dela a ele.

---

## 3. Como alternar entre Ambientes no Frontend

Para mudar de banco de dados, você **nunca** altera o código-fonte React. Você apenas edita o arquivo `.env` na raiz do projeto:

### Para rodar o ambiente de Demonstração (Showroom):
Configure o arquivo `.env` com as chaves do seu projeto **Demo**:
```env
VITE_SUPABASE_URL=https://id-do-projeto-demo.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.demo-key...
```

### Para rodar o ambiente de Produção Limpa (ou entregar para um cliente):
Altere as chaves do `.env` para o projeto do cliente real:
```env
VITE_SUPABASE_URL=https://id-do-projeto-cliente.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.cliente-key...
```

---

## 4. O papel dos Scripts Automatizados (`seed` e `purge`)

Para evitar ter que preencher ou limpar tabelas manualmente pelo painel do Supabase, nós criamos scripts JavaScript executados via terminal local.

Esses scripts realizam operações diretamente no banco que estiver ativo no arquivo `.env` no momento da execução:

### Script 1: Povoamento (`seed_demo.js`)
* **O que faz:** Limpa dados antigos de transações e insere 25 clientes com nomes de mulheres brasileiras, anamnese em formato JSONB, além de dezenas de agendamentos (pendentes, confirmados, concluídos, cancelados) e atendimentos.
* **Quando usar:** Sempre que você quiser resetar o ambiente de demonstração para a versão original com dados preenchidos.
* **Comando:**
  ```bash
  node scripts/seed_demo.js
  ```

### Script 2: Limpeza (`purge_db.js`)
* **O que faz:** Deleta todas as clientes, fichas, agendamentos, logs e atendimentos. Ele **preserva** as configurações básicas do negócio e o catálogo de serviços (evitando que a profissional tenha que cadastrar tudo do zero).
* **Quando usar:** Antes de entregar o banco de dados para um novo cliente real, garantindo que não restem dados de teste ou de demonstração.
* **Comando:**
  ```bash
  node scripts/purge_db.js
  ```

---

## 5. Evolução para SaaS (Software as a Service) no Futuro

Se amanhã você quiser transformar este aplicativo em um SaaS (onde várias profissionais assinam o sistema e usam o mesmo site com bancos isolados):

1. **Uma Única Base de Dados:** Você não precisará mais criar um projeto Supabase para cada cliente. Todos os dados ficarão no mesmo banco.
2. **Coluna de Identificação:** Adicionamos uma coluna `estabelecimento_id` (ou `profissional_id`) em todas as tabelas (ex: `clientes`, `agendamentos`).
3. **Isolamento de Segurança (RLS):** As políticas de RLS (Row Level Security) do Supabase passam a filtrar as consultas automaticamente para garantir que a profissional logada veja apenas dados correspondentes ao seu ID de estabelecimento:
   ```sql
   CREATE POLICY "profissional_ver_proprio_estabelecimento" ON clientes
     FOR ALL USING (estabelecimento_id = auth.jwt() ->> 'estabelecimento_id');
   ```
4. **Demonstração Integrada:** O seu showroom será apenas um cadastro de demonstração pré-povoado (ex: `estabelecimento_id = 'demo-lash'`). Quando você for apresentar o sistema, você faz login com a conta demo. Quando um novo cliente se cadastrar, ele ganha um `estabelecimento_id` novo e inicia com o painel totalmente zerado.
