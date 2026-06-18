# PRD — Lash Hub
**Versão:** 1.0 (v0)
**Data:** Junho 2026
**Status:** MVP Concluído

---

## 1. Visão Geral do Produto

**Lash Hub** é um SaaS (Software as a Service) de gestão e agendamento online voltado para profissionais autônomas de cílios e estética (lash designers, designers de sobrancelhas, etc.). A plataforma elimina a dependência do WhatsApp para marcação de horários, oferecendo à profissional um painel administrativo completo e às clientes um portal de autoatendimento exclusivo do estúdio.

### Proposta de Valor

| Para quem | Problema resolvido | Solução |
|---|---|---|
| **Profissional** | Horas perdidas respondendo WhatsApp para agendar | Painel com agenda, CRM, financeiro e portal próprio |
| **Cliente final** | Dependência da disponibilidade da profissional para marcar | Portal online 24h com catálogo, datas e horários disponíveis |
| **Profissional** | Falta de histórico clínico e financeiro organizado | Fichas de anamnese, histórico de atendimentos e dashboard financeiro |

---

## 2. Modelo de Negócio

- **Tipo:** SaaS Multi-Tenant — cada profissional é um "tenant" isolado
- **Monetização:** Assinatura mensal recorrente
- **Trial:** 14 dias no Plano Premium (completo) ao se cadastrar

### Planos

| | Plano Básico — R$ 59,90/mês | Plano Premium — R$ 99,90/mês |
|---|---|---|
| Cadastro de clientes ilimitado | ✅ | ✅ |
| Ficha clínica de anamnese | ✅ | ✅ |
| Dashboard de relatórios | ✅ | ✅ |
| Histórico de atendimentos | ✅ | ✅ |
| Suporte por e-mail | ✅ | ✅ |
| Agenda e calendário | ❌ | ✅ |
| Portal de agendamento online | ❌ | ✅ |
| Horários dinâmicos | ❌ | ✅ |
| Bloqueios rápidos de agenda | ❌ | ✅ |
| Aprovação manual/automática | ❌ | ✅ |
| Suporte prioritário | ❌ | ✅ |

---

## 3. Arquitetura do Sistema

- **Frontend:** React + TypeScript + Vite + TailwindCSS
- **Backend/DB:** Supabase (PostgreSQL + Auth + Storage)
- **Deploy:** Vercel (frontend) + Supabase (banco)
- **PWA:** Instalável como app no Android e iOS

### Ambientes

| Ambiente | Frontend | Banco |
|---|---|---|
| Desenvolvimento | `localhost` | `lashhub-desenv` (Supabase) |
| Produção | Vercel | `lashhub-prd` (Supabase) |

### Isolamento Multi-Tenant

Cada estabelecimento tem seus dados completamente isolados via `estabelecimento_id` em todas as tabelas + Row Level Security (RLS) no banco. Um tenant jamais acessa dados de outro.

---

## 4. Usuários do Sistema

### 4.1 Profissional (admin do estúdio)
- Se cadastra em `/cadastro` e recebe automaticamente: estabelecimento, configuração padrão e catálogo inicial de serviços
- Acessa o painel administrativo completo
- Gerencia clientes, agenda, serviços e financeiro

### 4.2 Cliente final (cliente do estúdio)
- Acessa o portal exclusivo do estúdio via link: `lashhub.com/portal/[slug]`
- Cria conta no portal para agendar
- Visualiza catálogo, seleciona serviços, escolhe data/hora e confirma agendamento
- Gerencia seus próprios agendamentos

---

## 5. Módulos e Funcionalidades

### 5.1 Painel da Profissional

#### Dashboard
- KPIs: Valor Total Ganho, Total de Agendamentos, Aguardando Confirmação, Novos Clientes
- Filtros de período: Hoje, Ontem, 7 dias, Este mês, Mês passado, Este ano, Personalizado
- Gráficos: Receita ao longo do tempo, Agendamentos por dia da semana, Clientes novas vs recorrentes, Serviços mais realizados, Receita por categoria
- Lista de Próximos Atendimentos de Hoje

#### Clientes (CRM)
- Cadastro completo: nome, sobrenome, WhatsApp, e-mail, CPF, endereço, data de nascimento
- Ficha clínica de anamnese lash (13 campos específicos para extensão de cílios)
- Histórico de atendimentos (manual + agendamentos concluídos + faltas) em linha do tempo
- Indicador de faltas (no-show) no Resumo Rápido do perfil
- Busca e filtro de clientes

#### Serviços
- Organização por categorias com ordem customizável
- Serviços com nome, descrição, duração e valor
- Variações por serviço (ex: Volume Russo, Clássico, Híbrido) com preço e duração próprios
- Ativação/desativação de serviços
- Serviços padrão criados automaticamente no cadastro (10 serviços em 4 categorias)

#### Agendamentos
- Visualização em calendário: Mensal, Semanal e Diária
- Criação manual de agendamentos (admin)
- Gestão de status: Pendente → Confirmado → Concluído / Cancelado / Falta
- Painel de agendamentos aguardando confirmação (ordenado por data)
- Modal de conclusão com valor recebido e registro no dashboard
- Registro de falta (no-show) com histórico no perfil da cliente
- Verificação de sobreposição de horários
- Notificação via WhatsApp (links pré-preenchidos) ao aprovar/recusar

#### Meus Horários
- Configuração de dias e horários de atendimento por dia da semana
- Bloqueios de agenda: dia inteiro ou horário específico (férias, feriados, compromissos)

#### Configurações
- Dados do negócio: nome do estúdio, Instagram, endereço, logo
- Personalização visual: 6 paletas de cores + modo escuro/claro
- Regras de agendamento: aprovação automática ou manual, antecedência mínima para cancelamento
- Mensagem pós-agendamento personalizada

#### Minha Assinatura
- Visualização do plano ativo e status (trial, ativo, suspenso, cancelado)
- Comparativo de planos com funcionalidades
- Assinatura via Pix (integração simulada — gateway real pendente)
- Indicação de término do trial

### 5.2 Portal da Cliente

#### Catálogo de Serviços
- Catálogo público com categorias, serviços, descrições, preços e durações
- Filtro por categoria
- FAQ integrado com dúvidas frequentes
- Plano Básico: exibe banner com botão "Agendar via WhatsApp" em vez do agendamento online

#### Agendamento Online (Premium)
- Seleção de serviço e variação
- Calendário com dias disponíveis (respeita horários e bloqueios da profissional)
- Lista de horários disponíveis calculados automaticamente
- Verificação de race condition no momento da confirmação
- Status: Confirmado (aprovação automática) ou Pendente (aprovação manual)
- Mensagem personalizada pós-agendamento

#### Meus Agendamentos
- Divisão em Próximos e Passados
- Cancelamento online dentro da janela de antecedência configurada pela profissional

#### Meu Perfil
- Atualização de dados pessoais, WhatsApp, e-mail
- Upload de foto de perfil
- Alteração de senha

#### Autenticação do Portal
- Tela de login com identidade visual da plataforma (Lash Hub)
- Cadastro com validação de e-mail único + rollback em falha
- Navegação simplificada no Plano Básico (só Catálogo, sem login)

---

## 6. Segurança

- **Row Level Security (RLS)** em todas as 13 tabelas — isolamento completo por tenant
- **Sem `console.log`** com dados sensíveis em produção
- Todas as queries de mutação validam `estabelecimento_id` no WHERE
- Senhas gerenciadas exclusivamente pelo Supabase Auth
- `.env` com credenciais fora do controle de versão

---

## 7. PWA (Progressive Web App)

- Instalável como app no Android (banner automático) e iOS (instrução via banner customizado)
- Modo standalone (sem barra do navegador)
- Service worker network-first (sempre busca dados atualizados)
- Ícones 192×192 e 512×512
- Orientação livre (portrait e landscape)
- Atualizações de código entregues automaticamente sem reinstalação

---

## 8. Onboarding Automático

Ao se cadastrar, a profissional recebe automaticamente (via trigger no banco):
1. Estabelecimento criado com 14 dias de trial Premium
2. Configuração padrão do negócio
3. **10 serviços prontos** em 4 categorias:
   - Extensão de Cílios (4 serviços)
   - Lash Lifting & Tratamentos (2 serviços)
   - Design de Sobrancelhas (3 serviços)
   - Manutenções e Remoções (2 serviços + 4 variações)

A profissional entra no sistema com tudo configurado para começar a usar imediatamente.

---

## 9. Logs de Auditoria

Todas as ações relevantes são registradas na tabela `logs`:
- Criação, edição e exclusão de clientes, serviços e agendamentos
- Mudanças de status de agendamentos
- Registro de conclusões e faltas
- Logs identificados com o nome real do usuário

---

## 10. Pendências (Roadmap)

| Item | Prioridade | Referência |
|---|---|---|
| Integração real com gateway de pagamento (Asaas/Stripe) — webhooks, renovação automática, suspensão por inadimplência | Alta | `migracao_saas/etapa5_stripe_asaas.md` |
| Notificações automáticas via WhatsApp (lembretes de agendamento) | Média | `docs/plano_notificacoes_whatsapp.md` |
| Remoção dos botões de simulação de plano da tela de Minha Assinatura | Alta (pré-lançamento) | — |
| Ícones PWA com fundo transparente (versão branca do logo) | Baixa | — |

---

## 11. Estrutura do Projeto

```
src/
├── pages/
│   ├── profissional/     # Painel administrativo da profissional
│   └── portal-clientes/  # Portal de agendamento da cliente
├── components/
│   ├── common/           # Componentes compartilhados (modais, guards, banners)
│   └── layout/           # Layouts (sidebar, header, portal layout)
├── contexts/             # AuthContext, PortalContext
├── hooks/                # useSubscription
├── lib/                  # Cliente Supabase
├── types/                # Interfaces TypeScript
└── utils/                # Log, tema, formatações

scripts/
├── schema_definitivo.sql # Schema completo para novos bancos
└── limpar_producao.sql   # Utilitário para limpar dados de teste

docs/
├── manual_profissional.md
├── manual_cliente.md
├── plano_notificacoes_whatsapp.md
└── roadmap_producao_asaas.md
```
