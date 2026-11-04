# Infraestrutura do workshop no OCI Resource Manager

[Voltar ao tutorial](../README.md) · [Baixar o pacote Terraform](../Terraform.zip)

Esta configuração provisiona o ambiente OCI do workshop. Execute-a pelo **Resource Manager**, no Console OCI. Os arquivos desta pasta reproduzem o código do pacote original, sem alterações.

## Pré-requisitos

- Conta OCI ativa, com acesso ao Resource Manager e autorização para criar os recursos deste pacote, inclusive compartment e policies na tenancy.
- Região `us-chicago-1` assinada e com AIDP, quotas, capacidade e créditos disponíveis para a conta. O código verifica se a região está assinada e `READY`, mas não garante os demais requisitos.
- Um compartment existente para hospedar a stack, fora do compartment descartável que será criado pelo Terraform.
- Acesso à home region da tenancy para as operações IAM. A configuração descobre essa região automaticamente, que pode ser diferente de Chicago.

O Resource Manager fornece a autenticação da execução. Esta etapa não exige Terraform ou Python instalados no computador nem upload de chave privada PEM. A API Key usada posteriormente pelo plugin Ask AIDP é uma configuração local separada.

## O que será criado

| Recurso | Configuração |
| --- | --- |
| Compartment | `lab_codex_aidp_rm`, com os valores padrão |
| Policies do serviço AIDP | Uma na tenancy e outra no compartment do laboratório |
| Instância AIDP | `lab-codex-aidp-rm` |
| Workspace inicial | `lab-validacao`, criado pela configuração da instância |
| Lakehouse 26ai | Opcional, desabilitado por padrão |

A stack inclui uma espera para propagação inicial das policies. As operações IAM usam a home region da tenancy.

O Terraform **não cria** o Spark Compute `labspark`, schema, volume, CSV, notebooks ou job. Siga o [tutorial principal](../README.md) para executar essas etapas pelo Codex e Ask AIDP após o Apply.

As policies deste código concedem acesso ao **serviço AIDP**, com condições sobre o principal e os recursos. Elas não criam usuários, grupos ou credenciais e não concedem ao participante as permissões necessárias para executar a stack. Em uma conta com acesso restrito, o administrador deve verificar essas permissões antes do workshop.

## Parâmetros

| Parâmetro | Padrão | Orientação para o laboratório |
| --- | --- | --- |
| `tenancy_ocid` | Sem padrão no Terraform | Conferir o OCID da própria tenancy preenchido no formulário |
| `region` | `us-chicago-1` | Usar Chicago após conferir disponibilidade e quotas |
| `lab_name` | `lab-codex-aidp-rm` | Manter em uma trial individual ou usar um nome exclusivo |
| `workspace_name` | `lab-validacao` | Manter o mesmo nome nas etapas seguintes |
| `enable_ai_features` | `false` | Deixar desmarcado para os notebooks Spark |
| `iam_wait_seconds` | `90` | Espera inicial de IAM; aceita de 30 a 600 segundos |
| `lakehouse_database_name` | `LABAIDP` | Usado somente se o Lakehouse estiver habilitado |
| `lakehouse_admin_password` | `null` | Preencher somente no campo protegido, se habilitar o Lakehouse |

O formulário oculta `tenancy_ocid` e `iam_wait_seconds` no grupo de configuração automática. O nome do compartment deriva de `lab_name`, com os hífens substituídos por sublinhados.

Com `enable_ai_features=true`, o pacote cria Lakehouse 26ai com **2 ECPUs e 1 TB**, licença incluída e autoscaling desligado. Isso consome créditos adicionais. A senha tem marcação sensível, mas pode estar presente no state; restrinja o acesso à stack. Este opcional não é necessário para o laboratório Spark.

## Criar a stack

1. Abra **Developer Services > Resource Manager > Stacks > Create stack** no Console OCI.
2. Selecione a opção de configuração própria e envie [Terraform.zip](../Terraform.zip). Envie esse ZIP interno, com os `.tf` na raiz, em vez do ZIP do repositório inteiro.
3. Se houver o campo de diretório de trabalho, escolha a raiz (`.`).
4. Selecione **Terraform 1.5.x**, conforme o requisito deste pacote.
5. Hospede a stack em um compartment existente. Não use o compartment descartável criado pelo próprio laboratório.
6. Confira os parâmetros da tabela anterior e mantenha Lakehouse desabilitado.
7. Execute **Plan**. Revise os recursos e qualquer alteração ou substituição indicada.
8. Execute **Apply** e acompanhe o job até o estado final.
9. Confira a instância AIDP no Console, aguarde `ACTIVE` e guarde os outputs abaixo.

Se uma tentativa falhar, consulte o erro e corrija a **mesma stack**, preservando parâmetros e state. Antes de tentar novamente, confira quais recursos já existem. Não crie outra stack para gerenciar o mesmo ambiente.

## Outputs e próxima etapa

| Output | Uso |
| --- | --- |
| `aidp_instance_id` | OCID da instância para conectar o plugin |
| `region` | Região da instância |
| `workspace_name` | Nome usado para resolver o workspace real |
| `compartment_id` | Identificação do compartment para conferência e limpeza |
| `home_region` | Região das operações IAM |
| `lakehouse_id` | OCID do Lakehouse opcional, ou `null` |
| `console_url` | Link do AIDP na região configurada |
| `next_step` | Lembrete para criar o Spark pelo Codex/Workbench |

Guarde também o nome e o link da stack. O próximo passo do tutorial usa `aidp_instance_id`, `region` e `workspace_name` para conectar Ask AIDP e salvar `ambiente-lab.json` localmente.

`workspaceKey` e `clusterKey` não são outputs desta stack. O plugin resolve o primeiro ao conectar e salva o segundo depois de criar ou reutilizar `labspark`.

## Encerramento e remoção

Execute esta etapa somente depois de concluir o workshop e guardar os resultados que deseja preservar.

1. Exporte notebooks e evidências. Encerre jobs e outras execuções do laboratório.
2. Pare o compute `labspark` desta conta.
3. Revise os dados e arquivos gerenciados do ambiente. Quando necessário, use as opções de exclusão no Console AIDP antes de remover a instância.
4. Abra a **mesma stack**, revise o impacto e execute **Terraform actions > Destroy**.
5. Aguarde o estado final do job. Se a exclusão do compartment falhar, confira os buckets e logs restantes, remova somente os resíduos deste laboratório e repita Destroy.
6. Confira no Console os recursos restantes e o consumo da conta. Exclua a stack somente após concluir Destroy e a conferência.

O state cobre os recursos declarados neste pacote. Ele não inclui individualmente todos os objetos criados pelo plugin nem todos os recursos internos gerados pelo AIDP. Parar Spark ou excluir apenas a stack não remove toda a infraestrutura. O state desta variante pertence ao Resource Manager; não use o `destroy.py` de outra variante local.

## Versões e limites de validação

- Terraform exigido pelo código: `~> 1.5.0`.
- Provider OCI: `9.11.0`.
- Provider Time: `~> 0.13.0`, travado em `0.13.1` no lockfile.

[VALIDACAO.json](VALIDACAO.json) registra os testes estáticos locais do kit de origem, feitos em 3 de novembro de 2026 com Terraform CLI 1.5.7. O registro inclui `init`, `validate`, schema e planos mockados. Ele declara que **não houve Plan, Apply ou Destroy real no OCI Resource Manager**. Esses testes não comprovam elegibilidade da conta, permissões, quota, disponibilidade regional ou aceitação da configuração pela API.

## Referências oficiais

- [Estrutura de configurações e autenticação no Resource Manager](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/terraformconfigresourcemanager.htm)
- [Versões Terraform do Resource Manager](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Reference/terraformversions.htm)
- [Recurso AIDP do provider OCI](https://docs.oracle.com/en-us/iaas/tools/terraform-provider-oci/latest/docs/r/ai_data_platform_ai_data_platform.html)
- [Modelos de computação do Autonomous Database](https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/autonomous-compute-models.html)
