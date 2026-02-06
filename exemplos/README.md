# Exemplos de Planilhas Suportadas

O aplicativo **Melhor Rota** aceita os seguintes formatos:

## ✅ Formatos Suportados

- **CSV** (`.csv`) - Vírgula, ponto-e-vírgula ou tabulação
- **Excel 2007+** (`.xlsx`)
- **Excel 97-2003** (`.xls`)
- **OpenDocument** (`.ods`)

## 📋 Estrutura Requerida

A planilha deve conter as seguintes colunas (em qualquer ordem):

| Coluna      | Aliases Aceitos            | Obrigatório |
|-------------|---------------------------|-------------|
| Logradouro  | rua, avenida, logradouro  | ✅ Sim      |
| Número      | numero, nº, num           | ⚠️ Opcional |
| Bairro      | bairro                    | ⚠️ Opcional |
| Cidade      | cidade, municipio         | ✅ Sim      |
| UF/Estado   | uf, estado                | ⚠️ Opcional |

## 💡 Exemplos Válidos

### Exemplo 1: CSV Padrão
```csv
logradouro,numero,bairro,cidade,uf
Avenida Paulista,1578,Bela Vista,São Paulo,SP
```

### Exemplo 2: CSV com ponto-e-vírgula
```csv
rua;nº;bairro;cidade;estado
Avenida Paulista;1578;Bela Vista;São Paulo;São Paulo
```

### Exemplo 3: Excel simplificado
```
| Rua               | Número | Cidade      |
|-------------------|--------|-------------|
| Avenida Paulista  | 1578   | São Paulo   |
```

## 🔧 Dicas

- **Cabeçalho**: Obrigatório na primeira linha
- **UF**: Aceita "SP" ou "São Paulo"
- **Campos vazios**: Linhas incompletas são ignoradas
- **Delimitador CSV**: Detectado automaticamente (`,`, `;` ou `Tab`)

## 🚀 Como Usar

1. Prepare sua planilha seguindo a estrutura acima
2. Abra o app **Melhor Rota**
3. Clique em **"Importar Planilha"**
4. Selecione seu arquivo (CSV, XLSX, XLS ou ODS)
5. Aguarde a geocodificação dos endereços
6. Clique em **"Iniciar Navegação"**

## ⚠️ Problemas Comuns

**Endereços não encontrados?**
- Verifique se o nome da rua está completo
- Adicione o nome da cidade
- Teste com e sem acentos

**Formato não reconhecido?**
- Certifique-se que o cabeçalho está na primeira linha
- Use uma das colunas obrigatórias: "logradouro" ou "rua"
