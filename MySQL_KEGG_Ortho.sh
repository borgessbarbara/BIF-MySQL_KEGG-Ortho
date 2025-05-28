#!/bin/bash

# Script para automatizar a Análise de Transcriptoma com BLAST e MySQL
# Baseado no tutorial fornecido (Versão Não Interativa, com exportação de resultados)

echo "Script de Automação de Análise de Transcriptoma (Não Interativo)"
echo "-----------------------------------------------------------------"

# --- Configuração (Valores Fixos) ---
# Defina o nome do seu diretório de trabalho
WORK_DIR_NAME="/data/home/bif/barbara/desafio"

# Dados MySQL
MYSQL_USER="bif01"
MYSQL_PASSWORD="bif01"


# Defina o nome do banco de dados MySQL conforme solicitado
MYSQL_DB_NAME="Barbara"

# Defina os arquivos de entrada (garanta que estes caminhos estejam corretos ou os arquivos estejam em WORK_DIR_NAME)
HUMAN_CDS_FILE="h.sapiens.nuc"
TUMOR_SEQ_FILE="tumor.seq"

# Arquivos para importação no MySQL (esperado que estejam em WORK_DIR_NAME/mysql_aula)
MYSQL_DATA_SUBDIR="mysql_aula"
HSA_DESCRIPTION_FILE="hsa_description"
HSA_KO_LIST_FILE="hsa_ko.list"
KO_DESC_FILE="ko_desc"
K02MAP_FILE="KO2map" # Corrigido para KO2map conforme o script original, o tutorial usa K02map.

# Arquivo de saída do BLAST
BLAST_OUTPUT_FILE="megakegg"

# Diretório para salvar os resultados das consultas MySQL
MYSQL_RESULTS_DIR="resultados_consultas_mysql"

echo "Usando Diretório de Trabalho: '$WORK_DIR_NAME'"
echo "Usando Usuário MySQL: '$MYSQL_USER'"
echo "Usando Banco de Dados MySQL: '$MYSQL_DB_NAME'"
echo ""
echo "AVISO: Certifique-se de que sua senha do MySQL está corretamente definida no script."
read -p "Pressione [Enter] para continuar se a configuração estiver correta e os arquivos preparados..."


# --- Etapa 0: Configurar Diretório de Trabalho ---
echo ""
echo "--- Configurando Diretório de Trabalho ---"
if [ -d "$WORK_DIR_NAME" ]; then
    echo "Diretório '$WORK_DIR_NAME' já existe. Usando-o."
else
    mkdir -p "$WORK_DIR_NAME" # Usando -p para garantir que o caminho completo seja criado se necessário
    echo "Diretório '$WORK_DIR_NAME' criado."
fi
cd "$WORK_DIR_NAME"
echo "Diretório de trabalho alterado para $(pwd)"

# Criar subdiretório para resultados das consultas MySQL
if [ ! -d "$MYSQL_RESULTS_DIR" ]; then
    mkdir "$MYSQL_RESULTS_DIR"
    echo "Diretório '$MYSQL_RESULTS_DIR' criado para salvar os resultados das consultas."
fi


echo ""
echo "IMPORTANTE: Por favor, garanta que os seguintes arquivos estejam presentes no diretório '$(pwd)':"
echo "- $HUMAN_CDS_FILE"
echo "- $TUMOR_SEQ_FILE"
echo "E que os seguintes arquivos estejam em um subdiretório chamado '$MYSQL_DATA_SUBDIR' dentro de '$(pwd)':"
echo "- $HSA_DESCRIPTION_FILE"
echo "- $HSA_KO_LIST_FILE"
echo "- $KO_DESC_FILE"
echo "- $K02MAP_FILE"
echo "- megakegg"
read -p "Pressione [Enter] para continuar após garantir que os arquivos estão nos lugares corretos..."


# --- Etapa 1: Execução do BLAST (MegaBLAST) ---
echo ""
echo "--- Etapa 1: Executando o MegaBLAST ---"
# Objetivo: Identificar reads de transcritos de tumor de mama semelhantes aos CDS humanos.
if [ -f "$HUMAN_CDS_FILE" ] && [ -f "$TUMOR_SEQ_FILE" ]; then
    megablast -i "$HUMAN_CDS_FILE" -d "$TUMOR_SEQ_FILE" -D 3 -F F -a 10 -p 97 -s 80 -o "$BLAST_OUTPUT_FILE"
    echo "MegaBLAST concluído. Saída salva em '$BLAST_OUTPUT_FILE'."
else
    echo "Erro: Arquivos de entrada do BLAST ($HUMAN_CDS_FILE ou $TUMOR_SEQ_FILE) não encontrados em $(pwd)."
    echo "Por favor, coloque-os no diretório de trabalho ('$WORK_DIR_NAME') e reinicie o script."
    exit 1
fi

# --- Etapa 2: Processamento dos Resultados (Shell) ---
echo ""
echo "--- Etapa 2: Processando Resultados do BLAST (Shell) ---"
# Objetivo: Contar quantas vezes cada CDS apareceu no resultado do BLAST, ou seja, quantos hits teve.
PROCESSED_BLAST_HITS_FILE="resultado"
if [ -f "$BLAST_OUTPUT_FILE" ]; then
    cat "$BLAST_OUTPUT_FILE" | awk '{print $1}' | sort | uniq -c | sort -k 1,1 -n -r > "$PROCESSED_BLAST_HITS_FILE"
    echo "Resultados do BLAST processados. Contagem de hits salva em '$PROCESSED_BLAST_HITS_FILE'."
    echo "Amostra dos dados processados (primeiras 5 linhas) está em '$PROCESSED_BLAST_HITS_FILE'."
else
    echo "Erro: Arquivo de saída do BLAST '$BLAST_OUTPUT_FILE' não encontrado."
    exit 1
fi

# --- MySQL: Armazenamento e Análise ---
echo ""
echo "--- Etapas MySQL ---"

# --- Sub-Etapa: Configuração do MySQL e Preparação dos Dados ---
echo ""
echo "--- Sub-Etapa: Preparação de Dados para o MySQL ---"
if [ ! -d "$MYSQL_DATA_SUBDIR" ]; then
    mkdir "$MYSQL_DATA_SUBDIR"
    echo "Diretório '$MYSQL_DATA_SUBDIR' criado para arquivos relacionados ao MySQL."
fi

BLAST_TAB_FILE="$MYSQL_DATA_SUBDIR/megakegg_tab"

echo "Preparando arquivo BLAST tabular para importação no MySQL..."
if [ -f "$BLAST_OUTPUT_FILE" ]; then
    cat "$BLAST_OUTPUT_FILE" | awk -v OFS="\t" '($1!="#") {print $1, $2, $3, $11, $12}' > "$BLAST_TAB_FILE"
    echo "Arquivo BLAST tabular '$BLAST_TAB_FILE' criado."
    echo "Amostra dos dados tabulares (primeiras 2 linhas) está em '$BLAST_TAB_FILE'."
else
    echo "Erro: Arquivo de saída do BLAST '$BLAST_OUTPUT_FILE' não encontrado para conversão tabular."
    exit 1
fi

# Verifica os arquivos de importação necessários em mysql_aula
MISSING_FILES=0
for f_check in "$HSA_DESCRIPTION_FILE" "$HSA_KO_LIST_FILE" "$KO_DESC_FILE" "$K02MAP_FILE"; do
    if [ ! -f "$MYSQL_DATA_SUBDIR/$f_check" ]; then
        echo "Erro: Arquivo de importação MySQL necessário '$MYSQL_DATA_SUBDIR/$f_check' não encontrado."
        MISSING_FILES=1
    fi
done

if [ "$MISSING_FILES" -eq 1 ]; then
    echo "Por favor, garanta que todos os arquivos de dados necessários estejam no diretório '$MYSQL_DATA_SUBDIR' dentro de '$WORK_DIR_NAME' e reinicie."
    exit 1
fi


# --- Sub-Etapa: Operações de Banco de Dados e Tabelas MySQL ---
echo ""
echo "--- Sub-Etapa: Operações de Banco de Dados e Tabelas MySQL ---"
echo "As seguintes operações serão realizadas no servidor MySQL."
echo "Conectando como usuário '$MYSQL_USER' ao banco de dados '$MYSQL_DB_NAME'."

# Função para executar um comando MySQL e opcionalmente salvar a saída
exec_mysql_query() {
    local query="$1"
    local output_file="$2"
    local db_name="$3"

    if [ -n "$output_file" ]; then
        echo "Executando consulta e salvando em: $output_file"
        mysql --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" --enable-local-infile -h localhost "$db_name" -e "$query" > "$MYSQL_RESULTS_DIR/$output_file"
        if [ $? -ne 0 ]; then echo "Erro ao executar consulta para $output_file"; exit 1; fi
    else
        mysql --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" --enable-local-infile -h localhost "$db_name" -e "$query"
        if [ $? -ne 0 ]; then echo "Erro ao executar consulta: $query"; exit 1; fi
    fi
}
# Função para executar um bloco de comandos DDL/DML
exec_mysql_block() {
    local commands="$1"
    local db_name="$2"
    echo "$commands" | mysql --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" --enable-local-infile -h localhost "$db_name"
    if [ $? -ne 0 ]; then echo "Erro ao executar bloco de comandos MySQL."; exit 1; fi
}

# Comandos Iniciais (Criação de BD e Uso)
INIT_CMDS="CREATE DATABASE IF NOT EXISTS \`$MYSQL_DB_NAME\`;"
exec_mysql_block "$INIT_CMDS" "" # Executa sem selecionar um BD específico inicialmente

# Comandos DDL e DML que não precisam de exportação individual de SELECTs limitados
# (as verificações serão feitas por SELECTs separados direcionados a arquivos)
DDL_DML_CMDS=$(cat <<EOF
USE \`$MYSQL_DB_NAME\`;

-- 11) Criando uma tabela para armazenar os dados do BLAST [cite: 63]
CREATE TABLE IF NOT EXISTS result_blast (
    cds VARCHAR(15), -- [cite: 65]
    subject VARCHAR(50), -- [cite: 66]
    identity DOUBLE(5,2), -- [cite: 66]
    evalue VARCHAR(10), -- [cite: 67]
    score INT, -- [cite: 68]
    INDEX cds_idx (cds) -- [cite: 68]
);

-- 13) Carregando os dados do arquivo para a tabela [cite: 71]
LOAD DATA LOCAL INFILE '$BLAST_TAB_FILE' INTO TABLE result_blast;

-- 16) Criando uma nova tabela com essas contagens [cite: 83]
DROP TABLE IF EXISTS hsa_count;
CREATE TABLE hsa_count AS
SELECT cds, COUNT(*) AS hits FROM result_blast GROUP BY cds; -- [cite: 83]

-- 18) Criando uma tabela para as descrições dos genes [cite: 89]
CREATE TABLE IF NOT EXISTS hsa_description (
    cds VARCHAR(15), -- [cite: 91]
    description VARCHAR(150), -- [cite: 91]
    INDEX cds_idx (cds) -- [cite: 92]
);

-- 20) Carregando as descrições na tabela [cite: 94]
LOAD DATA LOCAL INFILE '$MYSQL_DATA_SUBDIR/$HSA_DESCRIPTION_FILE' INTO TABLE hsa_description;

-- 22) Adicionando uma coluna de descrição na tabela hsa_count [cite: 101]
ALTER TABLE hsa_count ADD COLUMN IF NOT EXISTS description VARCHAR(150);

-- 24) Atualizando a tabela hsa_count com as descrições dos genes [cite: 107]
UPDATE hsa_count, hsa_description
SET hsa_count.description = hsa_description.description -- [cite: 107]
WHERE hsa_count.cds = hsa_description.cds; -- [cite: 107]

-- 27) Criando uma tabela relacionando CDS e KO (Kegg Orthology) [cite: 118]
CREATE TABLE IF NOT EXISTS hsa_ko (
    cds VARCHAR(15), -- [cite: 120]
    ko VARCHAR(11), -- [cite: 121]
    hits BIGINT DEFAULT 0, -- [cite: 121]
    INDEX cds_idx (cds), -- [cite: 122]
    INDEX ko_idx (ko) -- [cite: 122]
);

-- 29) Carregando dados de mapeamento cds -> KO na tabela hsa_ko [cite: 126]
LOAD DATA LOCAL INFILE '$MYSQL_DATA_SUBDIR/$HSA_KO_LIST_FILE'
INTO TABLE hsa_ko
FIELDS TERMINATED BY '\t'
(cds, ko);

-- 30) Atualizando a contagem de hits na tabela hsa_ko [cite: 129]
UPDATE hsa_ko, hsa_count
SET hsa_ko.hits = hsa_count.hits -- [cite: 129]
WHERE hsa_ko.cds = hsa_count.cds; -- [cite: 129]

-- 32) Removendo os pares em que o CDS não teve hits [cite: 137]
DELETE FROM hsa_ko WHERE hits = 0;

-- 35) Criando uma tabela de agregação por KO [cite: 146]
DROP TABLE IF EXISTS ko_hits;
CREATE TABLE ko_hits AS
SELECT
    ko,
    COUNT(DISTINCT cds) AS total_cds, -- [cite: 148]
    SUM(hits) AS total_hits -- [cite: 148]
FROM hsa_ko
GROUP BY ko; -- [cite: 146]

-- 37) Criando uma tabela com descrições dos KOs [cite: 152]
CREATE TABLE IF NOT EXISTS ko_description (
    ko VARCHAR(11) PRIMARY KEY, -- [cite: 152]
    description VARCHAR(150) -- [cite: 152]
);

-- 38) Populando a tabela de descrições dos KOs [cite: 155]
LOAD DATA LOCAL INFILE '$MYSQL_DATA_SUBDIR/$KO_DESC_FILE' INTO TABLE ko_description;

-- 40) Adicionando coluna de descrição à tabela ko_hits [cite: 160]
ALTER TABLE ko_hits ADD COLUMN IF NOT EXISTS ko_desc VARCHAR(150);

-- 41) Atualizando a tabela ko_hits com descrições [cite: 164]
UPDATE ko_hits, ko_description
SET ko_hits.ko_desc = ko_description.description -- [cite: 164]
WHERE ko_hits.ko = ko_description.ko; -- [cite: 164]

-- 45) Criando uma tabela que relaciona KOs e vias metabólicas [cite: 179]
CREATE TABLE IF NOT EXISTS KOmap (
    path VARCHAR(25), -- [cite: 181]
    ko VARCHAR(25), -- [cite: 182]
    path_desc VARCHAR(150) -- [cite: 182]
);

-- 46) Carregando os dados de via KEGG para a tabela KOmap [cite: 184]
LOAD DATA LOCAL INFILE '$MYSQL_DATA_SUBDIR/$K02MAP_FILE' INTO TABLE KOmap;
EOF
)
exec_mysql_block "$DDL_DML_CMDS" "$MYSQL_DB_NAME"
echo "Comandos DDL e DML principais executados."

# Consultas SELECT com saída para arquivos
echo "Executando consultas SELECT e salvando resultados..."
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; DESC result_blast;" "12_desc_result_blast.txt" "$MYSQL_DB_NAME" # [cite: 69]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT * FROM result_blast LIMIT 10;" "14_result_blast_amostra.txt" "$MYSQL_DB_NAME" # [cite: 76]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT cds, COUNT(*) AS n_hits FROM result_blast GROUP BY cds ORDER BY n_hits DESC LIMIT 10;" "15_result_blast_contagem_cds_top10.txt" "$MYSQL_DB_NAME" # [cite: 79]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT * FROM hsa_count LIMIT 10;" "17_hsa_count_amostra.txt" "$MYSQL_DB_NAME" # [cite: 87]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT * FROM hsa_description LIMIT 10;" "21_hsa_description_amostra.txt" "$MYSQL_DB_NAME" # [cite: 97]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT * FROM hsa_count LIMIT 10;" "25_hsa_count_com_descricao_amostra.txt" "$MYSQL_DB_NAME" # [cite: 112]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT * FROM hsa_count ORDER BY hits DESC LIMIT 10;" "26_hsa_count_mais_hits_top10.txt" "$MYSQL_DB_NAME" # [cite: 114]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT COUNT(*) AS 'Total_CDS_KO_antes_filtro' FROM hsa_ko;" "31_hsa_ko_contagem_total_antes_filtro.txt" "$MYSQL_DB_NAME" # [cite: 133]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT COUNT(*) AS 'Total_CDS_KO_apos_filtro' FROM hsa_ko;" "33_hsa_ko_contagem_total_apos_filtro.txt" "$MYSQL_DB_NAME" # [cite: 140]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT * FROM hsa_ko ORDER BY hits DESC LIMIT 10;" "34_hsa_ko_gene_mais_expresso_top10.txt" "$MYSQL_DB_NAME" # [cite: 143]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT * FROM ko_hits LIMIT 10;" "36_ko_hits_amostra.txt" "$MYSQL_DB_NAME" # [cite: 150]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT * FROM ko_description LIMIT 10;" "39_ko_description_amostra.txt" "$MYSQL_DB_NAME" # [cite: 158]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT * FROM ko_hits LIMIT 10;" "42_ko_hits_com_descricao_amostra.txt" "$MYSQL_DB_NAME" # [cite: 167]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT * FROM ko_hits ORDER BY total_hits DESC LIMIT 10;" "43_ko_hits_mais_hits_top10.txt" "$MYSQL_DB_NAME" # [cite: 170]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT * FROM ko_hits WHERE ko_desc LIKE '%tumor%' LIMIT 10;" "44a_ko_hits_busca_tumor_top10.txt" "$MYSQL_DB_NAME" # [cite: 174]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT * FROM ko_hits WHERE ko_desc LIKE '%catalase%' LIMIT 10;" "44b_ko_hits_busca_catalase_top10.txt" "$MYSQL_DB_NAME" # [cite: 175]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT ko_hits.*, KOmap.path, KOmap.path_desc FROM ko_hits INNER JOIN KOmap ON ko_hits.ko = KOmap.ko ORDER BY total_hits DESC LIMIT 10;" "47_join_ko_hits_komap_top10.txt" "$MYSQL_DB_NAME" # [cite: 187]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SELECT ko_hits.*, KOmap.path, KOmap.path_desc FROM ko_hits INNER JOIN KOmap ON ko_hits.ko = KOmap.ko WHERE ko_hits.ko_desc LIKE '%tumor%' ORDER BY total_hits DESC LIMIT 10;" "BONUS_join_ko_hits_komap_filtro_tumor_top10.txt" "$MYSQL_DB_NAME" # [cite: 193]
exec_mysql_query "USE \`$MYSQL_DB_NAME\`; SHOW TABLES;" "SHOW_TABLES_final.txt" "$MYSQL_DB_NAME"

echo ""
echo "Operações MySQL e exportação de consultas concluídas com sucesso."
echo "Os arquivos de resultado estão em: '$WORK_DIR_NAME/$MYSQL_RESULTS_DIR'"
echo ""
echo "-----------------------------------------------------------------"
echo "Script de Análise de Transcriptoma Concluído."
echo "Resultados principais estão no diretório '$WORK_DIR_NAME' (atual: $(pwd)) e no banco de dados MySQL '$MYSQL_DB_NAME'."
echo "Resultados de consultas específicas estão em '$WORK_DIR_NAME/$MYSQL_RESULTS_DIR'."
cd .. # Retorna ao diretório onde o script foi lançado
