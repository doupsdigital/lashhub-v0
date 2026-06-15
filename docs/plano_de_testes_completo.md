# Plano de Testes Completo e Roteiro de Validação (Lashly SaaS)

Este documento descreve o plano de testes completo para homologar todas as funcionalidades do **Lashly SaaS**. Ele está estruturado em fluxos lógicos de uso, permitindo que você navegue pelo sistema como **Profissional** e **Cliente**, validando o comportamento de cada tela, CRUD e regra de cobrança.

Você pode marcar as caixas com `[x]` para indicar que o teste passou ou adicionar anotações para correções futuras.

---

## 📅 Histórico de Execução de Testes
* **Responsável pelo Teste**: [Nome do Testador]
* **Data da Execução**: [__/__/____]
* **Resultado Geral**: `[ ] Aprovado para Produção` | `[ ] Ajustes Pendentes`

---

## 🔗 Massa de Dados Útil para Teste Local
* **URL do Admin**: `http://localhost:5174/`
* **Usuário Demo (Bruna Lash)**: `contato@brunalash.com.br` | Senha: `123456`
* **Portal da Cliente (Demo)**: `http://localhost:5174/portal/brunalash`

---

## 🛠️ FLUXO 1: Cadastro (Onboarding) e Período de Testes (Trial)
Este fluxo valida a jornada de uma nova profissional se registrando no SaaS.

| ID | Cenário de Teste | Passos para Executar | Resultado Esperado | Status |
| :--- | :--- | :--- | :--- | :---: |
| **T1.1** | Cadastro de Nova Profissional | 1. Acesse `http://localhost:5174/cadastro`<br>2. Preencha todos os campos com dados fictícios válidos.<br>3. Clique em **Cadastrar**. | - Redirecionamento automático para o `/dashboard`.<br>- Criação correta do registro da profissional e estabelecimento no banco. | `[ ]` |
| **T1.2** | Atribuição de Trial Premium | 1. Após o cadastro do **T1.1**, navegue pelo menu lateral.<br>2. Verifique se as páginas **Agenda** e **Horários** estão acessíveis. | - A nova profissional inicia com o plano **Premium (Trial)** liberado.<br>- Acesso total a todas as abas e menus, sem bloqueios de tela. | `[ ]` |
| **T1.3** | Informações de Trial em Faturamento | 1. No menu lateral, acesse **Faturamento**.<br>2. Observe o painel da esquerda "Assinatura Atual". | - O Status deve ser **"Período de Testes (14 dias restantes)"**.<br>- A data de término deve ser exatamente de 14 dias a contar de hoje. | `[ ]` |
| **T1.4** | Destaque do Plano de Testes Atual | 1. Ainda na página de **Faturamento**, observe o card de escolha de planos à direita. | - O card do **Plano Premium (Agenda)** deve exibir a badge: **"Seu plano de testes atual"**.<br>- Ambos os cards devem exibir os botões de checkout (Pix/Cartão). | `[ ]` |

*Observações do Fluxo 1:*
__________________________________________________________________________________________________

---

## 👥 FLUXO 2: Gestão de Clientes e Ficha de Anamnese (Profissional)
Valida o cadastro de clientes, histórico de atendimentos e personalização das fichas.

| ID | Cenário de Teste | Passos para Executar | Resultado Esperado | Status |
| :--- | :--- | :--- | :--- | :---: |
| **T2.1** | Cadastro Manual de Clientes | 1. Acesse a aba **Clientes**.<br>2. Clique em **Adicionar Cliente**.<br>3. Preencha Nome, Sobrenome, WhatsApp, Data de Nascimento e clique em **Salvar**. | - O cliente deve ser exibido imediatamente na lista geral.<br>- A busca rápida por nome/WhatsApp deve localizá-lo. | `[ ]` |
| **T2.2** | Edição de Cadastro de Cliente | 1. Na lista de clientes, clique sobre o cliente criado no **T2.1**.<br>2. No perfil do cliente, clique em **Editar Dados** (ou ícone correspondente).<br>3. Altere o número de WhatsApp e clique em **Salvar**. | - Os novos dados devem ser exibidos no cabeçalho do perfil imediatamente sem quebrar o layout. | `[ ]` |
| **T2.3** | Customização da Ficha de Anamnese | 1. No perfil do cliente, clique na seção **Ficha de Anamnese**.<br>2. Insira dados de testes nos campos (Ex: mapeamento de fios, alergias, estilo de cílios).<br>3. Clique em **Salvar Ficha**.<br>4. Recarregue a página (`F5`). | - A ficha de anamnese deve reter todos os dados digitados.<br>- O salvamento deve persistir corretamente no banco (campo JSONB). | `[ ]` |
| **T2.4** | Histórico e Anotações Rápidas | 1. No perfil do cliente, localize o bloco de **Histórico / Linha do Tempo**.<br>2. Digite uma anotação na caixa de texto rápida e envie.<br>3. Tente anexar ou fazer upload de uma foto de sessão (se houver o botão). | - A nota rápida deve ser adicionada à linha do tempo com a data atual e autor do registro. | `[ ]` |
| **T2.5** | Exclusão de Cliente | 1. Retorne à lista de **Clientes**.<br>2. Clique no ícone de lixeira (excluir) no cadastro do cliente de teste.<br>3. Confirme o modal/alerta do navegador. | - O cliente deve sumir da lista geral.<br>- Todos os registros associados devem sumir ou ser tratados no banco. | `[ ]` |

*Observações do Fluxo 2:*
__________________________________________________________________________________________________

---

## 💅 FLUXO 3: Catálogo de Serviços e Variações (Profissional)
Valida a montagem do portfólio de serviços com preços e durações variáveis.

| ID | Cenário de Teste | Passos para Executar | Resultado Esperado | Status |
| :--- | :--- | :--- | :--- | :---: |
| **T3.1** | Criação de Categoria de Serviço | 1. Acesse a aba **Serviços**.<br>2. Clique em **Nova Categoria**.<br>3. Digite o nome (ex: `Lash Lifting`) e salve. | - A nova categoria deve aparecer listada como um bloco vazio de serviços. | `[ ]` |
| **T3.2** | Criação de Serviço Simples (Preço Fixo) | 1. Na categoria criada (**T3.1**), clique em **Adicionar Serviço**.<br>2. Digite Nome (`Lash Lifting Clássico`), Preço (`R$ 130,00`), Duração (`60 minutos`).<br>3. Salve. | - O serviço deve aparecer listado dentro do bloco da categoria.<br>- O preço e tempo devem ser exibidos de forma legível. | `[ ]` |
| **T3.3** | Criação de Serviço com Variações | 1. Adicione outro serviço (ex: `Manutenção de Cílios`).<br>2. Deixe o preço/tempo principal em branco.<br>3. Adicione variações: <br>   * Var 1: `15 dias` - `R$ 80,00` - `45 min`<br>   * Var 2: `30 dias` - `R$ 110,00` - `60 min`<br>4. Salve. | - O serviço deve listar as opções de variação com seus respectivos valores adicionais e durações no painel. | `[ ]` |
| **T3.4** | Desativação Temporária de Serviço | 1. Edite o serviço simples criado no **T3.2**.<br>2. Desmarque a opção **Ativo** (Status ativo para falso) e salve. | - O serviço deve aparecer como inativo/apagado no painel da profissional.<br>- O serviço **não** deve aparecer no portal de agendamentos do cliente. | `[ ]` |

*Observações do Fluxo 3:*
__________________________________________________________________________________________________

---

## ⏰ FLUXO 4: Agenda, Expediente e Bloqueios (Profissional)
Valida a configuração de horários de expediente e criação de recessos.

| ID | Cenário de Teste | Passos para Executar | Resultado Esperado | Status |
| :--- | :--- | :--- | :--- | :---: |
| **T4.1** | Alteração de Horário de Expediente | 1. Acesse a aba **Horários**.<br>2. Edite os horários de início e fim da Segunda-feira (ex: mude de `09:00 - 18:00` para `10:00 - 17:00`).<br>3. Salve as alterações. | - O novo expediente deve ser persistido.<br>- Na grade de agendamentos, o plano de fundo deve refletir os novos limites. | `[ ]` |
| **T4.2** | Dias de Folga (Desativação de Dia) | 1. Na aba **Horários**, desmarque a caixa de seleção de um dia (ex: Sábado).<br>2. Salve as alterações. | - O Sábado deve constar como "Fechado".<br>- Clientes no portal online não devem conseguir selecionar datas de sábado para agendar. | `[ ]` |
| **T4.3** | Cadastro de Bloqueio de Agenda | 1. Na seção **Bloqueios de Agenda**, clique em **Adicionar Bloqueio**.<br>2. Preencha uma data específica (ex: amanhã), motivo (`Curso Presencial`) e salve. | - O bloqueio deve constar na listagem de bloqueios cadastrados.<br>- Clientes no portal online não devem ver horários disponíveis na data do bloqueio. | `[ ]` |

*Observações do Fluxo 4:*
__________________________________________________________________________________________________

---

## 🗓️ FLUXO 5: Grade de Agendamentos (Profissional)
Valida as operações cotidianas do calendário administrativo.

| ID | Cenário de Teste | Passos para Executar | Resultado Esperado | Status |
| :--- | :--- | :--- | :--- | :---: |
| **T5.1** | Agendamento Manual (Interno) | 1. Acesse a aba **Agenda**.<br>2. Clique em um espaço vazio na grade de horários ou no botão **Novo Agendamento**.<br>3. Selecione o Cliente cadastrado, Data/Hora, Serviço e confirme. | - O agendamento deve ser plotado visualmente na hora e duração corretas na grade.<br>- O status inicial deve ser "Confirmado" por padrão para agendamentos manuais. | `[ ]` |
| **T5.2** | Mudança de Status do Agendamento | 1. Clique no card de agendamento criado no **T5.1**.<br>2. Mude o status para **Concluído** e salve. | - A cor do card na grade da agenda deve mudar para indicar a conclusão (ex: tom verde/esmeralda). | `[ ]` |
| **T5.3** | Cancelamento / Edição de Registro | 1. Clique em outro agendamento na grade.<br>2. Altere o horário ou mude o status para **Cancelado**.<br>3. Salve. | - Se cancelado, o card deve mudar para tom escuro/riscado ou sumir da grade principal dependendo do filtro.<br>- O horário correspondente deve ficar livre para novas marcações. | `[ ]` |

*Observações do Fluxo 5:*
__________________________________________________________________________________________________

---

## 🌐 FLUXO 6: Portal do Cliente (Experiência do Usuário Final)
Valida a ponta final onde a cliente realiza o autoagendamento online.

| ID | Cenário de Teste | Passos para Executar | Resultado Esperado | Status |
| :--- | :--- | :--- | :--- | :---: |
| **T6.1** | Cadastro de Nova Cliente no Portal | 1. Abra o portal público (`http://localhost:5174/portal/brunalash/cadastro`).<br>2. Cadastre uma cliente informando Nome, E-mail e Senha. | - A conta de cliente final deve ser criada e associada ao estabelecimento correto.<br>- Login imediato após o cadastro. | `[ ]` |
| **T6.2** | Navegação no Catálogo de Serviços | 1. Acesse `/portal/brunalash/catalogo`.<br>2. Verifique a listagem de categorias e serviços ativos. | - Apenas os serviços marcados como "Ativo" devem constar.<br>- Os preços e durações mostrados devem bater com o admin. | `[ ]` |
| **T6.3** | Agendamento Online em 4 Passos | 1. No catálogo, clique em **Agendar** no serviço desejado.<br>2. **Passo 1 (Serviços)**: Confirme a seleção (e variação, se houver) e continue.<br>3. **Passo 2 (Data)**: Selecione a data no calendário (Verifique se dias fechados e bloqueados estão indisponíveis).<br>4. **Passo 3 (Horário)**: Selecione um slot livre.<br>5. **Passo 4 (Confirmação)**: Insira uma observação rápida e clique em **Confirmar**. | - Exibição da tela de sucesso com a mensagem personalizada pós-agendamento configurada pelo painel admin.<br>- Redirecionamento para a lista de agendamentos. | `[ ]` |
| **T6.4** | Visualização de Histórico da Cliente | 1. No portal da cliente, acesse **Meus Agendamentos**.<br>2. Veja o status da reserva recém-efetuada. | - O agendamento deve aparecer com status "Pendente" ou "Confirmado" (dependendo da regra de aprovação do painel). | `[ ]` |

*Observações do Fluxo 6:*
__________________________________________________________________________________________________

---

## 🎨 FLUXO 7: Configurações do Estúdio e Customização
Valida a flexibilidade visual e as regras de agendamento online.

| ID | Cenário de Teste | Passos para Executar | Resultado Esperado | Status |
| :--- | :--- | :--- | :--- | :---: |
| **T7.1** | Mudança de Paleta de Cores e Tema | 1. No painel admin, acesse a aba **Configurações**.<br>2. Mude a paleta de cores (ex: de `Rosa Rose` para `Dourado Classic`) e ative o **Modo Escuro**.<br>3. Salve. | - O painel administrativo deve mudar imediatamente de cores.<br>- Ao abrir o Portal do Cliente, a identidade visual deve refletir as novas cores e o modo escuro salvos. | `[ ]` |
| **T7.2** | Alternância de Aprovação Automática | 1. Em **Configurações**, mude a regra de agendamento para **Aprovação Automática = Não** e salve.<br>2. Faça um agendamento no portal da cliente.<br>3. Mude a regra para **Aprovação Automática = Sim** e faça outro agendamento. | - O primeiro agendamento deve aparecer na agenda admin com uma tarja "Pendente de Aprovação".<br>- O segundo agendamento deve aparecer direto como "Confirmado". | `[ ]` |
| **T7.3** | Mensagem de Confirmação Customizada | 1. Em **Configurações**, mude o campo "Mensagem de Sucesso" para `Prontinho, agendamento feito! Amamos te ver aqui.` e salve.<br>2. Agende um serviço no Portal do Cliente. | - A tela final de sucesso do portal do cliente deve exibir exatamente a nova mensagem salva. | `[ ]` |

*Observações do Fluxo 7:*
__________________________________________________________________________________________________

---

## 💳 FLUXO 8: Faturamento, Gateway Asaas e Restrições de Planos (SaaS)
Valida a regra de negócios crucial da Etapa 5: cobrança e bloqueio.

| ID | Cenário de Teste | Passos para Executar | Resultado Esperado | Status |
| :--- | :--- | :--- | :--- | :---: |
| **T8.1** | Simulação de Assinatura via Pix | 1. Acesse **Faturamento** e clique em **Assinar via Pix** em qualquer plano.<br>2. Copie o código Pix copia e cola e clique em **Confirmar Pagamento Pix** para simular o recebimento. | - Mensagem de pagamento confirmado com sucesso.<br>- O status do faturamento do estúdio muda imediatamente para **Assinatura Ativa** (com plano correspondente). | `[ ]` |
| **T8.2** | Simulação de Assinatura via Cartão | 1. Acesse **Faturamento** e clique em **Assinar via Cartão**.<br>2. Insira dados fictícios de cartão (ex: `1234...`), validade e CVV.<br>3. Clique em **Assinar com Cartão**. | - Validação simulada concluída com sucesso.<br>- Acesso ativo imediato. | `[ ]` |
| **T8.3** | Downgrade/Bloqueio de Agenda Online (Plano Básico) | 1. Certifique-se de que o plano do estúdio está configurado como **Básico** (você pode assinar o básico para testar).<br>2. Acesse `/portal/brunalash/agendar` ou clique em agendar no catálogo. | - O sistema deve interceptar e redirecionar a cliente de volta ao catálogo `/catalogo`, impedindo o autoagendamento online.<br>- No painel administrativo, a aba **Agenda** deve estar trancada/bloqueada (PlanGuard bloqueia o agendamento no plano Básico). | `[ ]` |
| **T8.4** | Bloqueio por Faturamento Expirado / Inadimplente | 1. Mude o status do estúdio para inadimplência rodando o script no terminal local: `node scripts/simular_webhook_asaas.js suspend brunalash`<br>2. Tente navegar para o `/dashboard` ou `/clientes`. | - O sistema exibe o painel de bloqueio administrativo em tela cheia informando sobre a inadimplência.<br>- Todas as rotas de operação (clientes, serviços, agenda, etc.) ficam inacessíveis, exceto as telas de **Faturamento** e **Configurações**. | `[ ]` |
| **T8.5** | Desbloqueio Automático Pós-Pagamento (Inadimplência) | 1. Com a tela de bloqueio ativa, clique em **Regularizar Financeiro** ou acesse a página de **Faturamento**.<br>2. Efetue um pagamento Pix simulado.<br>3. Tente acessar o `/dashboard`. | - A assinatura é reativada de forma instantânea.<br>- O painel de bloqueio some e o acesso total ao sistema é restabelecido. | `[ ]` |
| **T8.6** | Cancelamento de Assinatura Ativa | 1. Com uma assinatura paga ativa, vá em **Faturamento**.<br>2. No painel esquerdo, clique em **Cancelar Assinatura** e confirme a caixa de diálogo do navegador. | - A assinatura é inativada no banco.<br>- O plano é rebaixado para **Básico** e o status de assinatura para **Cancelado**. | `[ ]` |

*Observações do Fluxo 8:*
__________________________________________________________________________________________________
