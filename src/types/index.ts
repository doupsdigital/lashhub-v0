export interface Usuario {
  id: string;
  nome: string;
  email: string;
  avatar_url?: string | null;
  created_at?: string;
}

export interface CategoriaServico {
  id: string;
  nome: string;
  ativo: boolean;
  created_at?: string;
}

export interface Servico {
  id: string;
  categoria_id: string;
  nome: string;
  duracao_minutos: number;
  valor_padrao: number;
  ativo: boolean;
  created_at?: string;
  categoria?: CategoriaServico;
}

export interface VariacaoServico {
  id: string;
  servico_id: string;
  nome: string;
  valor: number;
  created_at?: string;
}

export interface Profissional {
  id: string;
  nome: string;
  sobrenome: string;
  ativo: boolean;
  created_at?: string;
}

export interface HorarioProfissional {
  id: string;
  profissional_id: string;
  dia_semana: number; // 0=Domingo, 1=Segunda...
  hora_inicio: string; // "HH:MM"
  hora_fim: string; // "HH:MM"
}

export interface Cliente {
  id: string;
  nome: string;
  sobrenome: string;
  whatsapp: string;
  email?: string | null;
  data_nascimento?: string | null;
  cpf?: string | null;
  endereco?: string | null;
  como_conheceu?: string | null;
  alergias?: string | null;
  tipo_pele?: string | null;
  restricoes?: string | null;
  medicamentos?: string | null;
  gestante: boolean;
  doencas_cronicas?: string | null;
  observacoes?: string | null;
  ativo: boolean;
  created_at?: string;
}

export interface Agendamento {
  id: string;
  cliente_id: string;
  profissional_id: string;
  data_hora: string;
  duracao_minutos: number;
  status: 'confirmado' | 'cancelado' | 'concluido';
  observacoes?: string | null;
  created_at?: string;
  cliente?: Cliente;
  profissional?: Profissional;
}

export interface AgendamentoServico {
  id: string;
  agendamento_id: string;
  servico_id: string;
  variacao_id?: string | null;
  valor_cobrado: number;
  servico?: Servico;
  variacao?: VariacaoServico;
}

export interface Atendimento {
  id: string;
  cliente_id: string;
  profissional_id: string;
  servico_id: string;
  variacao_id?: string | null;
  data_atendimento: string;
  valor_cobrado: number;
  observacoes?: string | null;
  created_at?: string;
  cliente?: Cliente;
  profissional?: Profissional;
  servico?: Servico;
  variacao?: VariacaoServico;
}

export interface Log {
  id: string;
  usuario_id?: string | null;
  usuario_nome: string;
  acao: 'criou' | 'editou' | 'excluiu';
  entidade: string;
  entidade_id?: string | null;
  descricao: string;
  created_at?: string;
}
