# BIF-MySQL_KEGG-Ortho

Scripts em shell para otimizar e automatizar o "Tutorial de Análise de Transcriptoma com MySQL e KEGG Orthology" da disciplina de Fundamentos de Bioinformática (PPGBioME - UFRN), ministrada pelo Professor Jorge Estefano de Souza.

## 🎯 Objetivos

Este repositório contém um script Bash (`MySQL_KEGG_Ortho.sh`) projetado para automatizar as etapas do tutorial de análise de transcriptoma. O objetivo é facilitar a execução da análise completa, desde o alinhamento com BLAST, processamento dos resultados, até a integração e análise dos dados em um banco de dados MySQL, culminando com a anotação funcional utilizando o KEGG Orthology.

## 🛠️ Pré-requisitos

Antes de executar o script, certifique-se de que os seguintes softwares estão instalados e configurados no seu sistema:

* **Bash:** Interpretador de comandos padrão na maioria dos sistemas Linux e macOS.
* **BLAST+:** Conjunto de ferramentas para alinhamento de sequências (especificamente o comando `megablast`).
* **MySQL Client:** Para interagir com o servidor MySQL e executar os comandos SQL.
* **Servidor MySQL:** Acessível pelo script (localmente ou remotamente).

## ⚙️ Configuração

Siga os passos abaixo para configurar o ambiente antes de rodar o script principal.

### 1. Arquivos de Entrada

O script espera uma estrutura específica de arquivos e diretórios.
No script `MySQL_KEGG_Ortho.sh`, a variável `WORK_DIR_NAME` define o diretório principal de trabalho. Por padrão, ela está configurada para um caminho específico (`/data/home/bif/barbara/desafio`). Você pode alterar essa variável para outro local desejado.

Os arquivos de entrada do tutorial podem ser acessados através do seguinte drive: [https://drive.google.com/drive/folders/1_xFuKNpD7Hyyr8zp0p9t3McaTRRH-05S?usp=sharing ](url). Este drive tem todos os arquivos do tutorial!

Dentro do diretório de trabalho (`$WORK_DIR_NAME`):

1.  **Coloque os arquivos de sequência FASTA. Os utilizados durante o tutorial são:**
    * `h.sapiens.nuc` (arquivo FASTA com CDS humanas)
    * `tumor.seq` (arquivo FASTA com reads de transcritos tumorais)

2.  **Crie um subdiretório chamado `mysql_aula`** (ou o nome definido na variável `MYSQL_DATA_SUBDIR` no script).
3.  **Dentro de `mysql_aula`, coloque os seguintes arquivos de dados tabulados. No caso do tutorial, são:**
    * `hsa_description` (descrições dos genes humanos)
    * `hsa_ko.list` (mapeamento de CDS humanas para IDs KO)
    * `ko_desc` (descrições dos IDs KO)
    * `KO2map` (mapeamento de KOs para vias metabólicas do KEGG e descrições das vias)
    * `megakegg` (output do BLAST)

O script possui um ponto de pausa para que você possa organizar esses arquivos após a criação inicial do diretório de trabalho. Confirme com `ENTER` se estiver tudo certo!

### 2. Credenciais MySQL

As credenciais de acesso ao banco de dados MySQL precisam ser configuradas diretamente no script `MySQL_KEGG_Ortho.sh`. Elas estão definidas para o usuário do servidor utilizado durante a atividade. Mas você pode editar as seguintes variáveis:

```bash
MYSQL_USER="seu_usuario_aqui"    # Substitua pelo seu usuário MySQL
MYSQL_PASSWORD="sua_senha_aqui"  # Substitua pela sua senha MySQL
MYSQL_DB_NAME="nome_do_seu_db"   # Nome do banco de dados a ser criado/usado (pode ser alterado)
```

## 📜 Funcionalidades do Workflow

O script `MySQL_KEGG_Ortho.sh` realiza as seguintes etapas principais:

1.  **Configuração do Ambiente:** Cria o diretório de trabalho e subdiretórios necessários.
2.  **Execução do BLAST:** Realiza o alinhamento das sequências de transcritos tumorais contra as CDS humanas usando `megablast`.
3.  **Processamento dos Resultados do BLAST:** Utiliza comandos shell (`awk`, `sort`, `uniq`) para contar os "hits" por CDS.
4.  **Preparação de Dados para MySQL:** Formata a saída do BLAST para um formato tabular adequado para importação.
5.  **Operações no MySQL:**
    * Cria o banco de dados (se não existir).
    * Cria as tabelas necessárias (`result_blast`, `hsa_count`, `hsa_description`, `hsa_ko`, `ko_hits`, `ko_description`, `KOmap`).
    * Carrega os dados dos arquivos preparados (`megakegg_tab`, `hsa_description`, `hsa_ko.list`, etc.) para as respectivas tabelas.
    * Executa junções (`JOIN`), atualizações (`UPDATE`) e agregações (`GROUP BY`) para enriquecer os dados e realizar análises.
    * Integra informações de contagem de hits com descrições de genes e anotações funcionais do KEGG Orthology (KO) e KEGG Pathway.
6.  **Exportação de Resultados:** As principais consultas `SELECT` têm seus resultados exportados para arquivos de texto individuais no subdiretório `resultados_consultas_mysql` dentro do `WORK_DIR_NAME`.

## 📊 Saída Esperada

Ao final da execução do script, você terá:

* **Arquivos Intermediários:**
    * `megakegg`: Saída bruta do BLAST.
    * `resultado`: Contagem de hits por CDS.
    * `mysql_aula/megakegg_tab`: Saída do BLAST formatada para MySQL.
* **Resultados das Consultas MySQL:**
    * Um subdiretório `resultados_consultas_mysql` (dentro do `WORK_DIR_NAME`) contendo arquivos `.txt` com os resultados das principais consultas SQL executadas. Cada arquivo é nomeado de forma descritiva (ex: `14_result_blast_amostra.txt`, `43_ko_hits_mais_hits_top10.txt`).
* **Banco de Dados MySQL:**
    * Um banco de dados (nomeado conforme `MYSQL_DB_NAME`) populado com as tabelas e dados processados, pronto para consultas e análises adicionais.
