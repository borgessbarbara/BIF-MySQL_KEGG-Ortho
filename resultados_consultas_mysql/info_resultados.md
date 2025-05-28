### Descrição dos Arquivos Gerados pelas Consultas MySQL

Os seguintes arquivos são gerados no subdiretório `resultados_consultas_mysql` dentro do seu diretório de trabalho principal (`WORK_DIR_NAME`). Eles contêm os resultados das consultas SQL executadas durante o pipeline de análise.

* **`12_desc_result_blast.txt`**:
    * Conteúdo: Estrutura da tabela `result_blast`.
    * Comando SQL: `DESC result_blast;`
    * Propósito: Permite verificar os nomes das colunas, tipos de dados e outros atributos da tabela que armazena os resultados brutos do BLAST.

* **`14_result_blast_amostra.txt`**:
    * Conteúdo: As primeiras 10 linhas da tabela `result_blast`.
    * Comando SQL: `SELECT * FROM result_blast LIMIT 10;`
    * Propósito: Verificação inicial para confirmar se os dados do BLAST foram carregados corretamente na tabela.

* **`15_result_blast_contagem_cds_top10.txt`**:
    * Conteúdo: Os 10 CDS (sequências query) com o maior número de hits (alinhamentos) na tabela `result_blast`.
    * Comando SQL: `SELECT cds, COUNT(*) AS n_hits FROM result_blast GROUP BY cds ORDER BY n_hits DESC LIMIT 10;`
    * Propósito: Identificação preliminar dos genes mais representados nos resultados do BLAST.

* **`17_hsa_count_amostra.txt`**:
    * Conteúdo: As primeiras 10 linhas da tabela `hsa_count` após sua criação (contendo `cds` e `hits`).
    * Comando SQL: `SELECT * FROM hsa_count LIMIT 10;`
    * Propósito: Verificar a criação e o conteúdo inicial da tabela que armazena a contagem de hits por CDS.

* **`21_hsa_description_amostra.txt`**:
    * Conteúdo: As primeiras 10 linhas da tabela `hsa_description`.
    * Comando SQL: `SELECT * FROM hsa_description LIMIT 10;`
    * Propósito: Verificar se as descrições dos genes foram carregadas corretamente.

* **`25_hsa_count_com_descricao_amostra.txt`**:
    * Conteúdo: As primeiras 10 linhas da tabela `hsa_count` após a adição da coluna `description` e sua atualização.
    * Comando SQL: `SELECT * FROM hsa_count LIMIT 10;`
    * Propósito: Confirmar que as descrições dos genes foram corretamente incorporadas à tabela `hsa_count`.

* **`26_hsa_count_mais_hits_top10.txt`**:
    * Conteúdo: Os 10 genes (CDS) com maior número de hits, ordenados de forma decrescente, incluindo suas descrições.
    * Comando SQL: `SELECT * FROM hsa_count ORDER BY hits DESC LIMIT 10;`
    * Propósito: Listar os genes potencialmente mais expressos com base na contagem de hits.

* **`31_hsa_ko_contagem_total_antes_filtro.txt`**:
    * Conteúdo: Contagem total de pares CDS-KO na tabela `hsa_ko` antes da remoção de entradas com zero hits.
    * Comando SQL: `SELECT COUNT(*) AS 'Total_CDS_KO_antes_filtro' FROM hsa_ko;`
    * Propósito: Avaliar a cobertura inicial do mapeamento funcional CDS para KO.

* **`33_hsa_ko_contagem_total_apos_filtro.txt`**:
    * Conteúdo: Contagem total de pares CDS-KO na tabela `hsa_ko` após a remoção de entradas onde o CDS não teve hits.
    * Comando SQL: `SELECT COUNT(*) AS 'Total_CDS_KO_apos_filtro' FROM hsa_ko;`
    * Propósito: Avaliar a cobertura funcional dos genes que foram efetivamente detectados (com hits).

* **`34_hsa_ko_gene_mais_expresso_top10.txt`**:
    * Conteúdo: Os 10 principais registros da tabela `hsa_ko` (CDS, KO, hits) ordenados pelo número de hits, mostrando a quais KOs os genes mais expressos pertencem.
    * Comando SQL: `SELECT * FROM hsa_ko ORDER BY hits DESC LIMIT 10;`
    * Propósito: Identificar os grupos de ortologia KEGG (KO) associados aos genes com maior número de hits.

* **`36_ko_hits_amostra.txt`**:
    * Conteúdo: As primeiras 10 linhas da tabela `ko_hits` após sua criação (contendo `ko`, `total_cds`, `total_hits`).
    * Comando SQL: `SELECT * FROM ko_hits LIMIT 10;`
    * Propósito: Verificar a criação e o conteúdo inicial da tabela que agrega os hits por KO.

* **`39_ko_description_amostra.txt`**:
    * Conteúdo: As primeiras 10 linhas da tabela `ko_description`.
    * Comando SQL: `SELECT * FROM ko_description LIMIT 10;`
    * Propósito: Verificar se as descrições textuais dos KOs foram carregadas corretamente.

* **`42_ko_hits_com_descricao_amostra.txt`**:
    * Conteúdo: As primeiras 10 linhas da tabela `ko_hits` após a adição e atualização da coluna `ko_desc`.
    * Comando SQL: `SELECT * FROM ko_hits LIMIT 10;`
    * Propósito: Confirmar que as descrições dos KOs foram incorporadas à tabela `ko_hits`.

* **`43_ko_hits_mais_hits_top10.txt`**:
    * Conteúdo: Os 10 KOs com a maior soma total de hits (`total_hits`), incluindo suas descrições.
    * Comando SQL: `SELECT * FROM ko_hits ORDER BY total_hits DESC LIMIT 10;`
    * Propósito: Identificar os grupos funcionais (KOs) mais ativos ou representados na amostra.

* **`44a_ko_hits_busca_tumor_top10.txt`**:
    * Conteúdo: Os 10 KOs cujas descrições contêm a palavra "tumor", ordenados pelo total de hits.
    * Comando SQL: `SELECT * FROM ko_hits WHERE ko_desc LIKE '%tumor%' ORDER BY total_hits DESC LIMIT 10;`
    * Propósito: Encontrar grupos funcionais relevantes para o fenótipo de tumor.

* **`44b_ko_hits_busca_catalase_top10.txt`**:
    * Conteúdo: Os 10 KOs cujas descrições contêm a palavra "catalase", ordenados pelo total de hits.
    * Comando SQL: `SELECT * FROM ko_hits WHERE ko_desc LIKE '%catalase%' ORDER BY total_hits DESC LIMIT 10;`
    * Propósito: Exemplo de busca textual para encontrar KOs específicos de interesse.

* **`47_join_ko_hits_komap_top10.txt`**:
    * Conteúdo: Os 10 KOs com maior `total_hits`, mostrando a quais vias metabólicas do KEGG eles pertencem (incluindo o ID da via e sua descrição).
    * Comando SQL: `SELECT ko_hits.*, KOmap.path, KOmap.path_desc FROM ko_hits INNER JOIN KOmap ON ko_hits.ko = KOmap.ko ORDER BY total_hits DESC LIMIT 10;`
    * Propósito: Integrar a informação de expressão agregada por KO com o contexto de vias metabólicas.

* **`BONUS_join_ko_hits_komap_filtro_tumor_top10.txt`**:
    * Conteúdo: Similar ao arquivo anterior, mas filtrado para KOs cuja descrição (`ko_desc`) contém a palavra "tumor". Mostra as 10 principais vias metabólicas associadas a esses KOs relacionados a "tumor".
    * Comando SQL: `SELECT ko_hits.*, KOmap.path, KOmap.path_desc FROM ko_hits INNER JOIN KOmap ON ko_hits.ko = KOmap.ko WHERE ko_hits.ko_desc LIKE '%tumor%' ORDER BY total_hits DESC LIMIT 10;`
    * Propósito: Análise de enriquecimento funcional focada em vias metabólicas ativas em KOs relacionados a "tumor".

* **`SHOW_TABLES_final.txt`**:
    * Conteúdo: Lista de todas as tabelas criadas no banco de dados `$MYSQL_DB_NAME` ao final da execução do script.
    * Comando SQL: `SHOW TABLES;`
    * Propósito: Fornecer uma visão geral da estrutura final do banco de dados.
