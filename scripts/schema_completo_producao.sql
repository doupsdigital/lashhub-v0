-- =========================================================================
-- SCHEMA COMPLETO DE PRODUÇÃO (LASHLY SaaS MULTI-TENANT)
-- Cole e execute este script completo no SQL Editor do seu projeto Supabase de PRD
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1. TABELA DE ESTABELECIMENTOS (TENANTS)
-- -------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.estabelecimentos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_negocio TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  plano TEXT NOT NULL DEFAULT 'basico' CHECK (plano IN ('basico', 'premium')),
  status_assinatura TEXT NOT NULL DEFAULT 'trial' CHECK (status_assinatura IN ('trial', 'ativo', 'cancelado', 'suspenso')),
  billing_customer_id TEXT,
  billing_subscription_id TEXT,
  trial_ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- -------------------------------------------------------------------------
-- 2. TABELAS PRINCIPAIS MULTI-TENANT
-- -------------------------------------------------------------------------

-- Clientes
CREATE TABLE IF NOT EXISTS public.clientes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  estabelecimento_id UUID NOT NULL REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  sobrenome TEXT,
  email TEXT,
  whatsapp TEXT,
  data_nascimento DATE,
  cpf TEXT,
  endereco TEXT,
  observacoes TEXT,
  alergias TEXT,
  medicamentos TEXT,
  doencas_cronicas TEXT,
  gestante BOOLEAN DEFAULT false,
  anamnese_lash JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Usuários
CREATE TABLE IF NOT EXISTS public.usuarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  estabelecimento_id UUID NOT NULL REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'cliente' CHECK (role IN ('profissional', 'cliente')),
  cliente_id UUID REFERENCES public.clientes(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Categorias de Serviço
CREATE TABLE IF NOT EXISTS public.categorias_servico (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  estabelecimento_id UUID NOT NULL REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  descricao TEXT,
  ordem INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Serviços
CREATE TABLE IF NOT EXISTS public.servicos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  estabelecimento_id UUID NOT NULL REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
  categoria_id UUID REFERENCES public.categorias_servico(id) ON DELETE SET NULL,
  nome TEXT NOT NULL,
  descricao TEXT,
  duracao_minutos INTEGER NOT NULL DEFAULT 60,
  valor NUMERIC(10,2) NOT NULL DEFAULT 0,
  ativo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Variações de Serviço
CREATE TABLE IF NOT EXISTS public.variacoes_servico (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  servico_id UUID NOT NULL REFERENCES public.servicos(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  duracao_minutos INTEGER,
  valor NUMERIC(10,2),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Horários de Atendimento
CREATE TABLE IF NOT EXISTS public.horarios_atendimento (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  estabelecimento_id UUID NOT NULL REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
  dia_semana INTEGER NOT NULL CHECK (dia_semana BETWEEN 0 AND 6),
  hora_inicio TIME NOT NULL,
  hora_fim TIME NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT unique_dia_semana_estabelecimento UNIQUE (estabelecimento_id, dia_semana)
);

-- Bloqueios de Agenda
CREATE TABLE IF NOT EXISTS public.bloqueios_agenda (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  estabelecimento_id UUID NOT NULL REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
  data_inicio DATE NOT NULL,
  data_fim DATE NOT NULL,
  motivo TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Agendamentos
CREATE TABLE IF NOT EXISTS public.agendamentos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  estabelecimento_id UUID NOT NULL REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
  cliente_id UUID NOT NULL REFERENCES public.clientes(id),
  data_hora TIMESTAMPTZ NOT NULL,
  duracao_minutos INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'confirmado', 'cancelado', 'concluido')),
  origem TEXT DEFAULT 'admin' CHECK (origem IN ('admin', 'portal')),
  observacoes TEXT,
  valor_cobrado NUMERIC(10,2),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Itens / Serviços do Agendamento
CREATE TABLE IF NOT EXISTS public.agendamento_servicos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agendamento_id UUID NOT NULL REFERENCES public.agendamentos(id) ON DELETE CASCADE,
  servico_id UUID NOT NULL REFERENCES public.servicos(id),
  variacao_id UUID REFERENCES public.variacoes_servico(id),
  valor_cobrado NUMERIC(10,2),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Atendimentos (Histórico concluído)
CREATE TABLE IF NOT EXISTS public.atendimentos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  estabelecimento_id UUID NOT NULL REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
  cliente_id UUID NOT NULL REFERENCES public.clientes(id),
  servico_id UUID NOT NULL REFERENCES public.servicos(id),
  variacao_id UUID REFERENCES public.variacoes_servico(id),
  data_atendimento DATE NOT NULL,
  valor_cobrado NUMERIC(10,2) NOT NULL,
  observacoes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Configurações Visuais e Regras de Negócio do Estabelecimento
CREATE TABLE IF NOT EXISTS public.configuracao_negocio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  estabelecimento_id UUID NOT NULL REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
  nome_negocio TEXT NOT NULL DEFAULT 'Meu Studio',
  descricao TEXT,
  instagram TEXT,
  endereco TEXT,
  logo_url TEXT,
  aprovacao_automatica BOOLEAN DEFAULT false,
  antecedencia_cancelamento_horas INTEGER DEFAULT 24,
  mensagem_pos_agendamento TEXT DEFAULT 'Seu agendamento foi recebido! Aguarde a confirmação.',
  paleta_cores TEXT DEFAULT 'rosa_rose',
  modo_escuro BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Logs de Auditoria
CREATE TABLE IF NOT EXISTS public.logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  estabelecimento_id UUID NOT NULL REFERENCES public.estabelecimentos(id) ON DELETE CASCADE,
  usuario_id UUID REFERENCES public.usuarios(id) ON DELETE SET NULL,
  acao TEXT NOT NULL,
  detalhes JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- -------------------------------------------------------------------------
-- 3. FUNÇÕES DE SUPORTE DE SEGURANÇA (EVITA RECURSÃO RLS)
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_auth_user_role()
RETURNS TEXT AS $$
  SELECT role FROM public.usuarios WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.get_auth_user_establishment()
RETURNS UUID AS $$
  SELECT estabelecimento_id FROM public.usuarios WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER SET search_path = public;

-- -------------------------------------------------------------------------
-- 4. FUNÇÃO E TRIGGER DE CADASTRO (ONBOARDING AUTOMÁTICO)
-- -------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user_onboarding()
RETURNS TRIGGER AS $$
DECLARE
  new_est_id UUID;
  negocio_nome TEXT;
  negocio_slug TEXT;
  user_role TEXT;
  client_uuid UUID;
BEGIN
  negocio_nome := new.raw_user_meta_data ->> 'nome_negocio';
  negocio_slug := new.raw_user_meta_data ->> 'slug';
  user_role := COALESCE(new.raw_user_meta_data ->> 'role', 'profissional');

  IF user_role = 'profissional' AND negocio_nome IS NOT NULL THEN
    -- 1. Criar o estabelecimento com trial de 14 dias no plano PREMIUM (completo)
    INSERT INTO public.estabelecimentos (nome_negocio, slug, plano, status_assinatura, trial_ends_at)
    VALUES (
      negocio_nome, 
      COALESCE(negocio_slug, lower(regexp_replace(negocio_nome, '[^a-zA-Z0-9]', '', 'g'))), 
      'premium', 
      'trial',
      now() + INTERVAL '14 days'
    )
    RETURNING id INTO new_est_id;

    -- 2. Criar o profissional vinculado ao estabelecimento
    INSERT INTO public.usuarios (id, nome, email, role, estabelecimento_id)
    VALUES (new.id, negocio_nome, new.email, 'profissional', new_est_id);

    -- 3. Criar as configurações iniciais padrão do negócio
    INSERT INTO public.configuracao_negocio (estabelecimento_id, nome_negocio)
    VALUES (new_est_id, negocio_nome);

  ELSIF user_role = 'cliente' THEN
    client_uuid := (new.raw_user_meta_data ->> 'cliente_id')::UUID;
    
    INSERT INTO public.usuarios (id, nome, email, role, cliente_id, estabelecimento_id)
    VALUES (
      new.id,
      new.raw_user_meta_data ->> 'nome',
      new.email,
      'cliente',
      client_uuid,
      (new.raw_user_meta_data ->> 'estabelecimento_id')::UUID
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Associar a trigger ao auth.users do Supabase
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_onboarding();

-- -------------------------------------------------------------------------
-- 5. CONFIGURAÇÃO DE SEGURANÇA ROW LEVEL SECURITY (RLS)
-- -------------------------------------------------------------------------
ALTER TABLE public.estabelecimentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agendamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.atendimentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agendamento_servicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.horarios_atendimento ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bloqueios_agenda ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.configuracao_negocio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.servicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias_servico ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.variacoes_servico ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.logs ENABLE ROW LEVEL SECURITY;

-- POLÍTICAS: ESTABELECIMENTOS
CREATE POLICY "public_read_estabelecimento" ON public.estabelecimentos
  FOR SELECT USING (true);

CREATE POLICY "profissional_update_estabelecimento" ON public.estabelecimentos
  FOR UPDATE USING (
    id = (SELECT estabelecimento_id FROM public.usuarios WHERE id = auth.uid() AND role = 'profissional')
  );

-- POLÍTICAS: USUÁRIOS
CREATE POLICY "usuarios_select" ON public.usuarios
  FOR SELECT USING (
    id = auth.uid()
    OR (
      public.get_auth_user_role() = 'profissional'
      AND estabelecimento_id = public.get_auth_user_establishment()
    )
  );

CREATE POLICY "usuarios_insert" ON public.usuarios FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY "usuarios_update" ON public.usuarios FOR UPDATE USING (id = auth.uid());

-- POLÍTICAS: CLIENTES
CREATE POLICY "clientes_select" ON public.clientes
  FOR SELECT USING (
    id = (SELECT cliente_id FROM public.usuarios WHERE id = auth.uid())
    OR (
      public.get_auth_user_role() = 'profissional'
      AND estabelecimento_id = public.get_auth_user_establishment()
    )
  );

CREATE POLICY "clientes_insert" ON public.clientes FOR INSERT WITH CHECK (true);

CREATE POLICY "clientes_update" ON public.clientes
  FOR UPDATE USING (
    id = (SELECT cliente_id FROM public.usuarios WHERE id = auth.uid())
    OR (
      public.get_auth_user_role() = 'profissional'
      AND estabelecimento_id = public.get_auth_user_establishment()
    )
  );

CREATE POLICY "clientes_delete" ON public.clientes
  FOR DELETE USING (
    public.get_auth_user_role() = 'profissional'
    AND estabelecimento_id = public.get_auth_user_establishment()
  );

-- POLÍTICAS: CATEGORIAS DE SERVIÇO
CREATE POLICY "categorias_select" ON public.categorias_servico FOR SELECT USING (true);
CREATE POLICY "categorias_modify" ON public.categorias_servico
  FOR ALL USING (
    public.get_auth_user_role() = 'profissional'
    AND estabelecimento_id = public.get_auth_user_establishment()
  );

-- POLÍTICAS: SERVIÇOS
CREATE POLICY "servicos_select" ON public.servicos FOR SELECT USING (true);
CREATE POLICY "servicos_modify" ON public.servicos
  FOR ALL USING (
    public.get_auth_user_role() = 'profissional'
    AND estabelecimento_id = public.get_auth_user_establishment()
  );

-- POLÍTICAS: VARIAÇÕES DE SERVIÇO
CREATE POLICY "variacoes_select" ON public.variacoes_servico FOR SELECT USING (true);
CREATE POLICY "variacoes_modify" ON public.variacoes_servico
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.servicos s
      WHERE s.id = servico_id
      AND s.estabelecimento_id = public.get_auth_user_establishment()
      AND public.get_auth_user_role() = 'profissional'
    )
  );

-- POLÍTICAS: HORÁRIOS DE ATENDIMENTO
CREATE POLICY "horarios_select" ON public.horarios_atendimento FOR SELECT USING (true);
CREATE POLICY "horarios_modify" ON public.horarios_atendimento
  FOR ALL USING (
    public.get_auth_user_role() = 'profissional'
    AND estabelecimento_id = public.get_auth_user_establishment()
  );

-- POLÍTICAS: BLOQUEIOS DE AGENDA
CREATE POLICY "bloqueios_select" ON public.bloqueios_agenda FOR SELECT USING (true);
CREATE POLICY "bloqueios_modify" ON public.bloqueios_agenda
  FOR ALL USING (
    public.get_auth_user_role() = 'profissional'
    AND estabelecimento_id = public.get_auth_user_establishment()
  );

-- POLÍTICAS: CONFIGURAÇÃO DE NEGÓCIO
CREATE POLICY "config_select" ON public.configuracao_negocio FOR SELECT USING (true);
CREATE POLICY "config_modify" ON public.configuracao_negocio
  FOR ALL USING (
    public.get_auth_user_role() = 'profissional'
    AND estabelecimento_id = public.get_auth_user_establishment()
  );

-- POLÍTICAS: AGENDAMENTOS
CREATE POLICY "agendamentos_select" ON public.agendamentos
  FOR SELECT USING (
    cliente_id = (SELECT cliente_id FROM public.usuarios WHERE id = auth.uid())
    OR (
      public.get_auth_user_role() = 'profissional'
      AND estabelecimento_id = public.get_auth_user_establishment()
    )
  );

CREATE POLICY "agendamentos_insert" ON public.agendamentos FOR INSERT WITH CHECK (true);

CREATE POLICY "agendamentos_update" ON public.agendamentos
  FOR UPDATE USING (
    cliente_id = (SELECT cliente_id FROM public.usuarios WHERE id = auth.uid())
    OR (
      public.get_auth_user_role() = 'profissional'
      AND estabelecimento_id = public.get_auth_user_establishment()
    )
  );

CREATE POLICY "agendamentos_delete" ON public.agendamentos
  FOR DELETE USING (
    public.get_auth_user_role() = 'profissional'
    AND estabelecimento_id = public.get_auth_user_establishment()
  );

-- POLÍTICAS: ITENS / SERVIÇOS DO AGENDAMENTO
CREATE POLICY "agendamento_servicos_select" ON public.agendamento_servicos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.agendamentos a
      WHERE a.id = agendamento_id
      AND (
        a.cliente_id = (SELECT cliente_id FROM public.usuarios WHERE id = auth.uid())
        OR (
          public.get_auth_user_role() = 'profissional'
          AND a.estabelecimento_id = public.get_auth_user_establishment()
        )
      )
    )
  );

CREATE POLICY "agendamento_servicos_modify" ON public.agendamento_servicos
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.agendamentos a
      WHERE a.id = agendamento_id
      AND (
        a.cliente_id = (SELECT cliente_id FROM public.usuarios WHERE id = auth.uid())
        OR (
          public.get_auth_user_role() = 'profissional'
          AND a.estabelecimento_id = public.get_auth_user_establishment()
        )
      )
    )
  );

-- POLÍTICAS: ATENDIMENTOS
CREATE POLICY "atendimentos_policy" ON public.atendimentos
  FOR ALL USING (
    public.get_auth_user_role() = 'profissional'
    AND estabelecimento_id = public.get_auth_user_establishment()
  );

-- POLÍTICAS: LOGS
CREATE POLICY "logs_policy" ON public.logs
  FOR ALL USING (
    public.get_auth_user_role() = 'profissional'
    AND estabelecimento_id = public.get_auth_user_establishment()
  );

-- -------------------------------------------------------------------------
-- 6. CRIAÇÃO DO STORAGE BUCKET PARA AVATARES E IMAGENS
-- -------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Avatar publico" ON storage.objects;
CREATE POLICY "Avatar publico" ON storage.objects
  FOR ALL TO public
  USING (bucket_id = 'avatars')
  WITH CHECK (bucket_id = 'avatars');

-- -------------------------------------------------------------------------
-- 7. ESTABELECIMENTO DEMO PADRÃO (OPCIONAL - PARA FALLBACK)
-- -------------------------------------------------------------------------
INSERT INTO public.estabelecimentos (id, nome_negocio, slug, plano, status_assinatura)
VALUES ('e1000000-0000-0000-0000-000000000000', 'Bruna Lash', 'brunalash', 'premium', 'ativo')
ON CONFLICT (id) DO NOTHING;
