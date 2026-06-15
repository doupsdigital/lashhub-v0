-- =========================================================================
-- SCRIPT DE SEED E ONBOARDING DE SERVIÇOS (LASHLY SaaS)
-- Execute este script no SQL Editor do seu Supabase Dashboard
-- =========================================================================

-- 1. SEED DE SERVIÇOS PADRÃO PARA O ESTÚDIO ATUAL (ISADORA LASH)
-- Identifica se Isadora Lash está cadastrada e sem categorias
DO $$
DECLARE
  est_id UUID;
  cat_ext_id UUID;
  cat_lift_id UUID;
  cat_des_id UUID;
  cat_man_id UUID;
  srv_man_id UUID;
  cat_count INT;
BEGIN
  -- Busca o ID do estabelecimento da Isadora Lash
  SELECT id INTO est_id FROM public.estabelecimentos WHERE slug = 'isadora-lash' LIMIT 1;
  
  IF est_id IS NOT NULL THEN
    SELECT COUNT(*) INTO cat_count FROM public.categorias_servico WHERE estabelecimento_id = est_id;
    
    -- Só semeia se não tiver nenhuma categoria criada ainda
    IF cat_count = 0 THEN
      -- Semeia as Categorias
      INSERT INTO public.categorias_servico (estabelecimento_id, nome, descricao, ordem)
      VALUES (est_id, 'Extensão de Cílios', 'Técnicas de alongamento de cílios fio a fio e volumes.', 1)
      RETURNING id INTO cat_ext_id;

      INSERT INTO public.categorias_servico (estabelecimento_id, nome, descricao, ordem)
      VALUES (est_id, 'Lash Lifting & Tratamentos', 'Curvatura e tratamentos para cílios naturais.', 2)
      RETURNING id INTO cat_lift_id;

      INSERT INTO public.categorias_servico (estabelecimento_id, nome, descricao, ordem)
      VALUES (est_id, 'Design de Sobrancelhas', 'Modelagem, alinhamento e coloração para sobrancelhas.', 3)
      RETURNING id INTO cat_des_id;

      INSERT INTO public.categorias_servico (estabelecimento_id, nome, descricao, ordem)
      VALUES (est_id, 'Manutenções e Remoções', 'Cuidados periódicos e remoção segura de extensões.', 4)
      RETURNING id INTO cat_man_id;

      -- Serviços: Extensão de Cílios
      INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
      VALUES 
      (est_id, cat_ext_id, 'Fio a Fio Clássico', 'Um fio sintético acoplado a cada cílio natural. Efeito natural e discreto para o dia a dia.', 120, 150.00, true),
      (est_id, cat_ext_id, 'Volume Russo', 'Fans artesanais de 3 a 6 fios super finos aplicados em cada cílio. Efeito volumoso, denso e marcante.', 150, 200.00, true),
      (est_id, cat_ext_id, 'Volume Híbrido', 'Mescla perfeita de Fio a Fio com Volume Russo. Oferece volume com textura e leveza.', 135, 180.00, true),
      (est_id, cat_ext_id, 'Volume Brasileiro (Cílios Y)', 'Extensões em formato de Y aplicadas individualmente. Proporciona olhar preenchido e moderno.', 120, 160.00, true);

      -- Serviços: Lash Lifting
      INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
      VALUES 
      (est_id, cat_lift_id, 'Lash Lifting Completo', 'Curvatura natural e elevação dos cílios com aplicação de nutrição (Lash Botox) e tintura escura.', 60, 120.00, true),
      (est_id, cat_lift_id, 'Spa de Cílios', 'Higienização profunda dos fios, hidratação terapêutica e massagem relaxante na área dos olhos.', 30, 50.00, true);

      -- Serviços: Design de Sobrancelhas
      INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
      VALUES 
      (est_id, cat_des_id, 'Design de Sobrancelhas Simples', 'Modelagem personalizada respeitando a simetria e visagismo facial. Feito com pinça/linha.', 45, 50.00, true),
      (est_id, cat_des_id, 'Design com Henna', 'Modelagem personalizada com aplicação de Henna de alta fixação para preencher falhas e destacar o design.', 60, 70.00, true),
      (est_id, cat_des_id, 'Brow Lamination', 'Procedimento de alinhamento, estilização e nutrição química dos fios naturais das sobrancelhas.', 60, 130.00, true);

      -- Serviços: Manutenções
      INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
      VALUES (est_id, cat_man_id, 'Manutenção de Extensão', 'Reposição dos fios crescidos ou caídos. Válido até 20 dias após a aplicação original.', 90, 100.00, true)
      RETURNING id INTO srv_man_id;

      INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
      VALUES (est_id, cat_man_id, 'Remoção de Extensão', 'Retirada segura e indolor de extensões antigas usando removedor em gel profissional que protege os cílios naturais.', 45, 40.00, true);

      -- Variações de Serviço (Manutenções)
      INSERT INTO public.variacoes_servico (servico_id, nome, duracao_minutos, valor) 
      VALUES
      (srv_man_id, 'Manutenção Fio a Fio', 90, 90.00),
      (srv_man_id, 'Manutenção Volume Brasileiro', 90, 100.00),
      (srv_man_id, 'Manutenção Volume Híbrido', 100, 110.00),
      (srv_man_id, 'Manutenção Volume Russo', 120, 120.00);
      
    END IF;
  END IF;
END $$;

-- 2. ATUALIZAR O TRIGGER DE ONBOARDING PARA SEEDAR EM NOVOS NEGÓCIOS AUTOMATICAMENTE
CREATE OR REPLACE FUNCTION public.handle_new_user_onboarding()
RETURNS TRIGGER AS $$
DECLARE
  new_est_id UUID;
  negocio_nome TEXT;
  negocio_slug TEXT;
  user_role TEXT;
  client_uuid UUID;
  
  -- Category IDs
  cat_ext_id UUID;
  cat_lift_id UUID;
  cat_des_id UUID;
  cat_man_id UUID;
  
  -- Service IDs for variations
  srv_man_id UUID;
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

    -- 4. Seed das Categorias de Cílios / Lash Designer
    INSERT INTO public.categorias_servico (estabelecimento_id, nome, descricao, ordem)
    VALUES (new_est_id, 'Extensão de Cílios', 'Técnicas de alongamento de cílios fio a fio e volumes.', 1)
    RETURNING id INTO cat_ext_id;

    INSERT INTO public.categorias_servico (estabelecimento_id, nome, descricao, ordem)
    VALUES (new_est_id, 'Lash Lifting & Tratamentos', 'Curvatura e tratamentos para cílios naturais.', 2)
    RETURNING id INTO cat_lift_id;

    INSERT INTO public.categorias_servico (estabelecimento_id, nome, descricao, ordem)
    VALUES (new_est_id, 'Design de Sobrancelhas', 'Modelagem, alinhamento e coloração para sobrancelhas.', 3)
    RETURNING id INTO cat_des_id;

    INSERT INTO public.categorias_servico (estabelecimento_id, nome, descricao, ordem)
    VALUES (new_est_id, 'Manutenções e Remoções', 'Cuidados periódicos e remoção segura de extensões.', 4)
    RETURNING id INTO cat_man_id;

    -- 5. Seed dos Serviços de Lash Designer
    -- Categoria: Extensão de Cílios
    INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
    VALUES (new_est_id, cat_ext_id, 'Fio a Fio Clássico', 'Um fio sintético acoplado a cada cílio natural. Efeito natural e discreto para o dia a dia.', 120, 150.00, true);

    INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
    VALUES (new_est_id, cat_ext_id, 'Volume Russo', 'Fans artesanais de 3 a 6 fios super finos aplicados em cada cílio. Efeito volumoso, denso e marcante.', 150, 200.00, true);

    INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
    VALUES (new_est_id, cat_ext_id, 'Volume Híbrido', 'Mescla perfeita de Fio a Fio com Volume Russo. Oferece volume com textura e leveza.', 135, 180.00, true);

    INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
    VALUES (new_est_id, cat_ext_id, 'Volume Brasileiro (Cílios Y)', 'Extensões em formato de Y aplicadas individualmente. Proporciona olhar preenchido e moderno.', 120, 160.00, true);

    -- Categoria: Lash Lifting & Tratamentos
    INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
    VALUES (new_est_id, cat_lift_id, 'Lash Lifting Completo', 'Curvatura natural e elevação dos cílios com aplicação de nutrição (Lash Botox) e tintura escura.', 60, 120.00, true);

    INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
    VALUES (new_est_id, cat_lift_id, 'Spa de Cílios', 'Higienização profunda dos fios, hidratação terapêutica e massagem relaxante na área dos olhos.', 30, 50.00, true);

    -- Categoria: Design de Sobrancelhas
    INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
    VALUES (new_est_id, cat_des_id, 'Design de Sobrancelhas Simples', 'Modelagem personalizada respeitando a simetria e visagismo facial. Feito com pinça/linha.', 45, 50.00, true);

    INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
    VALUES (new_est_id, cat_des_id, 'Design com Henna', 'Modelagem personalizada com aplicação de Henna de alta fixação para preencher falhas e destacar o design.', 60, 70.00, true);

    INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
    VALUES (new_est_id, cat_des_id, 'Brow Lamination', 'Procedimento de alinhamento, estilização e nutrição química dos fios naturais das sobrancelhas.', 60, 130.00, true);

    -- Categoria: Manutenções e Remoções
    INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
    VALUES (new_est_id, cat_man_id, 'Manutenção de Extensão', 'Reposição dos fios crescidos ou caídos. Válido até 20 dias após a aplicação original.', 90, 100.00, true)
    RETURNING id INTO srv_man_id;

    INSERT INTO public.servicos (estabelecimento_id, categoria_id, nome, descricao, duracao_minutos, valor, ativo)
    VALUES (new_est_id, cat_man_id, 'Remoção de Extensão', 'Retirada segura e indolor de extensões antigas usando removedor em gel profissional que protege os cílios naturais.', 45, 40.00, true);

    -- 6. Seed das Variações de Serviço (Manutenções)
    INSERT INTO public.variacoes_servico (servico_id, nome, duracao_minutos, valor) VALUES
    (srv_man_id, 'Manutenção Fio a Fio', 90, 90.00),
    (srv_man_id, 'Manutenção Volume Brasileiro', 90, 100.00),
    (srv_man_id, 'Manutenção Volume Híbrido', 100, 110.00),
    (srv_man_id, 'Manutenção Volume Russo', 120, 120.00);

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
