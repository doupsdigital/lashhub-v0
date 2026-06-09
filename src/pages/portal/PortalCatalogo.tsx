import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Clock, Tag, Calendar, AlertCircle, Sparkles, RefreshCw } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import type { CategoriaServico, Servico, VariacaoServico } from '../../types';

interface ServicoComVariacoes extends Servico {
  variacoes: VariacaoServico[];
}

interface CategoriaComServicos extends CategoriaServico {
  servicos: ServicoComVariacoes[];
}

function formatDuracao(minutos: number): string {
  if (minutos <= 60) return `${minutos} min`;
  const horas = Math.floor(minutos / 60);
  const resto = minutos % 60;
  if (resto === 0) return `${horas}h`;
  return `${horas}h ${resto}min`;
}

function formatValor(valor: number): string {
  return `R$ ${Number(valor).toLocaleString('pt-BR', { minimumFractionDigits: 2 })}`;
}

function SkeletonCard() {
  return (
    <div className="bg-white border border-border rounded-2xl p-5 animate-pulse">
      <div className="h-5 bg-gray-200 rounded-lg w-3/4 mb-3"></div>
      <div className="h-3 bg-gray-100 rounded w-full mb-1.5"></div>
      <div className="h-3 bg-gray-100 rounded w-2/3 mb-5"></div>
      <div className="flex items-center gap-3 mb-5">
        <div className="h-4 bg-gray-200 rounded w-20"></div>
        <div className="h-4 bg-gray-200 rounded w-24"></div>
      </div>
      <div className="h-9 bg-rose-100 rounded-xl w-full"></div>
    </div>
  );
}

interface ServicoCardProps {
  servico: ServicoComVariacoes;
  onAgendar: () => void;
}

function ServicoCard({ servico, onAgendar }: ServicoCardProps) {
  return (
    <div className="bg-white border border-border rounded-2xl p-5 shadow-sm hover:shadow-md transition-shadow duration-200 flex flex-col gap-3">
      <h3 className="font-title font-semibold text-xl text-text-primary leading-snug">
        {servico.nome}
      </h3>

      {servico.descricao && (
        <p className="text-sm text-text-secondary leading-relaxed">{servico.descricao}</p>
      )}

      <div className="flex flex-wrap items-center gap-3">
        <span className="flex items-center gap-1.5 text-sm text-text-secondary">
          <Clock className="w-4 h-4 text-rose-400" />
          {formatDuracao(servico.duracao_minutos)}
        </span>
        <span className="flex items-center gap-1.5 text-base font-semibold text-text-primary">
          <Tag className="w-4 h-4 text-gold" />
          {formatValor(servico.valor)}
        </span>
      </div>

      {servico.variacoes.length > 0 && (
        <div className="border-t border-border pt-3 space-y-1.5">
          <p className="text-xs font-semibold uppercase tracking-wider text-text-muted mb-2">Opções</p>
          {servico.variacoes.map(v => (
            <div key={v.id} className="flex items-center justify-between gap-2 text-sm">
              <span className="text-text-secondary">{v.nome}</span>
              <div className="flex items-center gap-1.5 text-text-secondary shrink-0">
                {v.valor != null && (
                  <span className="font-medium text-text-primary">{formatValor(v.valor)}</span>
                )}
                {v.duracao_minutos != null && (
                  <span className="text-xs text-text-muted">• {formatDuracao(v.duracao_minutos)}</span>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      <button
        onClick={onAgendar}
        className="mt-auto w-full py-2.5 bg-rose-600 hover:bg-rose-800 text-white rounded-xl text-sm font-semibold transition-colors duration-200 flex items-center justify-center gap-2 cursor-pointer"
      >
        <Calendar className="w-4 h-4" />
        Agendar
      </button>
    </div>
  );
}

export default function PortalCatalogo() {
  const navigate = useNavigate();
  const [categorias, setCategorias] = useState<CategoriaComServicos[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [categoriaAtiva, setCategoriaAtiva] = useState<string>('todas');

  const fetchData = async () => {
    setLoading(true);
    setError(false);
    try {
      const [catResult, servResult, varResult] = await Promise.all([
        supabase.from('categorias_servico').select('*').order('ordem', { ascending: true }),
        supabase.from('servicos').select('*').eq('ativo', true).order('nome', { ascending: true }),
        supabase.from('variacoes_servico').select('*'),
      ]);

      if (catResult.error) throw catResult.error;
      if (servResult.error) throw servResult.error;
      if (varResult.error) throw varResult.error;

      const servicos = servResult.data || [];
      const variacoes = varResult.data || [];

      const mapped: CategoriaComServicos[] = (catResult.data || [])
        .map(cat => ({
          ...cat,
          servicos: servicos
            .filter(s => s.categoria_id === cat.id)
            .map(s => ({
              ...s,
              variacoes: variacoes.filter(v => v.servico_id === s.id),
            })),
        }))
        .filter(cat => cat.servicos.length > 0);

      setCategorias(mapped);
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const categoriasExibidas =
    categoriaAtiva === 'todas'
      ? categorias
      : categorias.filter(c => c.id === categoriaAtiva);

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="h-8 bg-gray-200 rounded-lg w-48 animate-pulse"></div>
        <div className="flex gap-2 overflow-x-auto pb-2">
          {[1, 2, 3].map(i => (
            <div key={i} className="h-8 bg-gray-100 rounded-full w-24 shrink-0 animate-pulse"></div>
          ))}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <SkeletonCard key={i} />
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-20 text-center gap-4">
        <AlertCircle className="w-12 h-12 text-rose-400" />
        <p className="font-semibold text-text-primary">Não foi possível carregar os serviços.</p>
        <p className="text-sm text-text-secondary">Tente novamente.</p>
        <button
          onClick={fetchData}
          className="flex items-center gap-2 px-5 py-2.5 bg-rose-600 hover:bg-rose-800 text-white rounded-xl text-sm font-semibold transition-colors cursor-pointer"
        >
          <RefreshCw className="w-4 h-4" />
          Tentar novamente
        </button>
      </div>
    );
  }

  if (categorias.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-20 text-center gap-3">
        <Sparkles className="w-12 h-12 text-rose-200" />
        <p className="font-title text-lg font-medium text-text-primary">
          Nenhum serviço disponível no momento.
        </p>
        <p className="text-sm text-text-muted">Em breve novidades!</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h1 className="font-title font-bold text-3xl text-text-primary">Nossos Serviços</h1>

      {/* Pills de categoria */}
      <div className="flex gap-2 overflow-x-auto pb-2">
        <button
          onClick={() => setCategoriaAtiva('todas')}
          className={`px-4 py-1.5 rounded-full text-sm font-medium whitespace-nowrap shrink-0 transition-colors cursor-pointer ${
            categoriaAtiva === 'todas'
              ? 'bg-rose-600 text-white'
              : 'bg-white border border-border text-text-secondary hover:border-rose-300 hover:text-rose-600'
          }`}
        >
          Todas
        </button>
        {categorias.map(cat => (
          <button
            key={cat.id}
            onClick={() => setCategoriaAtiva(cat.id)}
            className={`px-4 py-1.5 rounded-full text-sm font-medium whitespace-nowrap shrink-0 transition-colors cursor-pointer ${
              categoriaAtiva === cat.id
                ? 'bg-rose-600 text-white'
                : 'bg-white border border-border text-text-secondary hover:border-rose-300 hover:text-rose-600'
            }`}
          >
            {cat.nome}
          </button>
        ))}
      </div>

      {/* Seções por categoria */}
      <div className="space-y-10">
        {categoriasExibidas.map(cat => (
          <section key={cat.id}>
            <h2 className="font-title font-semibold text-2xl text-text-primary mb-4 pb-2 border-b border-border">
              {cat.nome}
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {cat.servicos.map(serv => (
                <ServicoCard
                  key={serv.id}
                  servico={serv}
                  onAgendar={() => navigate(`/portal/agendar?servico=${serv.id}`)}
                />
              ))}
            </div>
          </section>
        ))}
      </div>
    </div>
  );
}
