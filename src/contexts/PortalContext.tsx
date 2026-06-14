import React, { createContext, useContext, useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { applyPalette } from '../utils/theme';

interface PortalContextType {
  establishmentId: string | null;
  nomeNegocio: string | null;
  logoUrl: string | null;
  paletaCores: string | null;
  loading: boolean;
  slug: string | null;
}

const PortalContext = createContext<PortalContextType | undefined>(undefined);

export function PortalProvider({ children }: { children: React.ReactNode }) {
  const { slug } = useParams<{ slug: string }>();
  const navigate = useNavigate();
  const [establishmentId, setEstablishmentId] = useState<string | null>(null);
  const [nomeNegocio, setNomeNegocio] = useState<string | null>(null);
  const [logoUrl, setLogoUrl] = useState<string | null>(null);
  const [paletaCores, setPaletaCores] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!slug) {
      setLoading(false);
      return;
    }

    async function loadPortalData() {
      setLoading(true);
      try {
        // 1. Buscar estabelecimento pelo slug
        const { data: est, error: estError } = await supabase
          .from('estabelecimentos')
          .select('id, nome_negocio')
          .eq('slug', slug)
          .maybeSingle();

        if (estError || !est) {
          console.error('Estabelecimento não encontrado para o slug:', slug);
          // Redireciona para o login global de profissionais se o estúdio não for encontrado
          navigate('/login', { replace: true });
          return;
        }

        setEstablishmentId(est.id);
        setNomeNegocio(est.nome_negocio);

        // 2. Buscar configurações visuais do estabelecimento
        const { data: config, error: configError } = await supabase
          .from('configuracao_negocio')
          .select('logo_url, paleta_cores, modo_escuro')
          .eq('estabelecimento_id', est.id)
          .maybeSingle();

        if (!configError && config) {
          setLogoUrl(config.logo_url);
          setPaletaCores(config.paleta_cores || 'rosa_rose');
          
          // Aplicar a paleta de cores correspondente do estúdio no DOM
          applyPalette(config.paleta_cores || 'rosa_rose', config.modo_escuro || false);
        } else {
          // Defaults caso não haja configuração personalizada
          setLogoUrl(null);
          setPaletaCores('rosa_rose');
          applyPalette('rosa_rose', false);
        }
      } catch (err) {
        console.error('Erro ao carregar dados do portal:', err);
      } finally {
        setLoading(false);
      }
    }

    loadPortalData();
  }, [slug, navigate]);

  return (
    <PortalContext.Provider
      value={{
        establishmentId,
        nomeNegocio,
        logoUrl,
        paletaCores,
        loading,
        slug: slug || null,
      }}
    >
      {children}
    </PortalContext.Provider>
  );
}

export function usePortal() {
  const context = useContext(PortalContext);
  if (context === undefined) {
    throw new Error('usePortal deve ser usado dentro de um PortalProvider');
  }
  return context;
}
