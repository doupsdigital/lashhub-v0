-- ================================================
-- SCHEMA COMPLETO - Rosaê Clinic CRM
-- Cole este SQL no Supabase SQL Editor e execute
-- ================================================

-- Extensões
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================
-- TABELAS
-- ================================================

CREATE TABLE IF NOT EXISTS usuarios (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nome TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS clientes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nome TEXT NOT NULL,
  sobrenome TEXT,
  whatsapp TEXT,
  email TEXT,
  data_nascimento DATE,
  cpf TEXT,
  endereco TEXT,
  como_conheceu TEXT,
  alergias TEXT,
  tipo_pele TEXT,
  restricoes TEXT,
  medicamentos TEXT,
  gestante BOOLEAN DEFAULT FALSE,
  doencas_cronicas TEXT,
  observacoes TEXT,
  ativo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS categorias_servico (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nome TEXT NOT NULL,
  ativo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS servicos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  categoria_id UUID REFERENCES categorias_servico(id) ON DELETE SET NULL,
  nome TEXT NOT NULL,
  duracao_minutos INTEGER DEFAULT 60,
  valor_padrao NUMERIC(10,2) DEFAULT 0,
  ativo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS variacoes_servico (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  servico_id UUID NOT NULL REFERENCES servicos(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  valor NUMERIC(10,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS profissionais (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nome TEXT NOT NULL,
  sobrenome TEXT,
  ativo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS horarios_profissional (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profissional_id UUID NOT NULL REFERENCES profissionais(id) ON DELETE CASCADE,
  dia_semana INTEGER NOT NULL CHECK (dia_semana BETWEEN 0 AND 6),
  hora_inicio TEXT NOT NULL,
  hora_fim TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS agendamentos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cliente_id UUID REFERENCES clientes(id) ON DELETE SET NULL,
  profissional_id UUID REFERENCES profissionais(id) ON DELETE SET NULL,
  data_hora TIMESTAMPTZ NOT NULL,
  duracao_minutos INTEGER DEFAULT 60,
  status TEXT NOT NULL DEFAULT 'confirmado' CHECK (status IN ('confirmado','cancelado','concluido')),
  observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS agendamento_servicos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  agendamento_id UUID NOT NULL REFERENCES agendamentos(id) ON DELETE CASCADE,
  servico_id UUID REFERENCES servicos(id) ON DELETE SET NULL,
  variacao_id UUID REFERENCES variacoes_servico(id) ON DELETE SET NULL,
  valor_cobrado NUMERIC(10,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS atendimentos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cliente_id UUID REFERENCES clientes(id) ON DELETE SET NULL,
  profissional_id UUID REFERENCES profissionais(id) ON DELETE SET NULL,
  servico_id UUID REFERENCES servicos(id) ON DELETE SET NULL,
  variacao_id UUID REFERENCES variacoes_servico(id) ON DELETE SET NULL,
  data_atendimento DATE NOT NULL,
  valor_cobrado NUMERIC(10,2) NOT NULL DEFAULT 0,
  observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  usuario_id UUID,
  usuario_nome TEXT NOT NULL DEFAULT 'Sistema',
  acao TEXT NOT NULL CHECK (acao IN ('criou','editou','excluiu')),
  entidade TEXT NOT NULL,
  entidade_id UUID,
  descricao TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ================================================
-- ROW LEVEL SECURITY
-- ================================================

ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE categorias_servico ENABLE ROW LEVEL SECURITY;
ALTER TABLE servicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE variacoes_servico ENABLE ROW LEVEL SECURITY;
ALTER TABLE profissionais ENABLE ROW LEVEL SECURITY;
ALTER TABLE horarios_profissional ENABLE ROW LEVEL SECURITY;
ALTER TABLE agendamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE agendamento_servicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE atendimentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE logs ENABLE ROW LEVEL SECURITY;

-- Políticas: acesso total para usuários autenticados
CREATE POLICY "Acesso autenticado" ON usuarios FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acesso autenticado" ON clientes FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acesso autenticado" ON categorias_servico FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acesso autenticado" ON servicos FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acesso autenticado" ON variacoes_servico FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acesso autenticado" ON profissionais FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acesso autenticado" ON horarios_profissional FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acesso autenticado" ON agendamentos FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acesso autenticado" ON agendamento_servicos FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acesso autenticado" ON atendimentos FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acesso autenticado" ON logs FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ================================================
-- STORAGE: bucket de avatares
-- ================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Avatar publico" ON storage.objects;
CREATE POLICY "Avatar publico" ON storage.objects
  FOR ALL TO public
  USING (bucket_id = 'avatars')
  WITH CHECK (bucket_id = 'avatars');

-- ================================================
-- USUÁRIO ADMIN INICIAL
-- ================================================

INSERT INTO usuarios (nome, email)
VALUES ('Administrador', 'rosae@clinic.com')
ON CONFLICT (email) DO NOTHING;
