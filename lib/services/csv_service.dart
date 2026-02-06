import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/endereco.dart';
import 'string_formatter.dart';
import 'package:flutter/foundation.dart';

class CsvService {
  static Future<List<Endereco>> importarPlanilha() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls', 'ods'],
        withData: true,
      );

      if (result == null) return [];

      final picked = result.files.single;
      final extensao = (picked.extension ?? '').toLowerCase();

      List<List<dynamic>> rows;

      if (extensao == 'csv') {
        rows = await _processarCSV(picked);
      } else if (extensao == 'xlsx' || extensao == 'xls' || extensao == 'ods') {
        rows = await _processarExcel(picked);
      } else {
        throw Exception('Formato de arquivo não suportado: $extensao');
      }

      return _processarLinhas(rows);
    } catch (e) {
      throw Exception('Erro ao importar arquivo: $e');
    }
  }

  static Future<List<List<dynamic>>> _processarCSV(PlatformFile picked) async {
    final conteudo = await _lerConteudoComoString(picked);
    final delimitador = _detectarDelimitador(conteudo);
    return const CsvToListConverter().convert(
      conteudo,
      fieldDelimiter: delimitador,
      eol: '\n',
    );
  }

  static Future<List<List<dynamic>>> _processarExcel(PlatformFile picked) async {
    final bytes = await _lerConteudoComoBytes(picked);
    final excel = Excel.decodeBytes(bytes);

    // Pega a primeira planilha
    var sheet = excel.tables[excel.tables.keys.first];

    if (sheet == null) {
      throw Exception('Planilha vazia ou inválida');
    }

    List<List<dynamic>> rows = [];

    // Converte as linhas do Excel para lista
    for (var row in sheet.rows) {
      List<dynamic> rowData = [];
      for (var cell in row) {
        rowData.add(cell?.value?.toString() ?? '');
      }
      rows.add(rowData);
    }

    return rows;
  }

  static Future<String> _lerConteudoComoString(PlatformFile picked) async {
    if (kIsWeb) {
      final bytes = picked.bytes ?? Uint8List(0);
      return String.fromCharCodes(bytes);
    }
    final path = picked.path!;
    return File(path).readAsString();
  }

  static Future<Uint8List> _lerConteudoComoBytes(PlatformFile picked) async {
    if (kIsWeb) {
      return picked.bytes ?? Uint8List(0);
    }
    final path = picked.path!;
    return File(path).readAsBytes();
  }

  /// Detecta automaticamente o delimitador usado no CSV
  static String _detectarDelimitador(String conteudo) {
    List<String> primeiraLinha = conteudo.split('\n')[0].split('');
    
    int virgulas = primeiraLinha.where((c) => c == ',').length;
    int pontoVirgulas = primeiraLinha.where((c) => c == ';').length;
    int tabs = primeiraLinha.where((c) => c == '\t').length;

    if (pontoVirgulas > virgulas && pontoVirgulas > tabs) {
      return ';';
    } else if (tabs > virgulas && tabs > pontoVirgulas) {
      return '\t';
    }
    return ','; // Padrão
  }

  /// Processa as linhas extraídas e converte em endereços
  static List<Endereco> _processarLinhas(List<List<dynamic>> rows) {
    List<Endereco> enderecos = [];

    if (rows.isEmpty) return enderecos;

    // Detecta índices das colunas (cabeçalho pode estar em qualquer ordem)
    Map<String, int> indices = _detectarColunas(rows[0]);

    // Processa a partir da segunda linha (ignora cabeçalho)
    for (int i = 1; i < rows.length; i++) {
      List<dynamic> row = rows[i];

      if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
        continue; // Ignora linhas vazias
      }

      try {
        String logradouro = _obterValor(row, indices['logradouro'] ?? 0);
        String numero = _obterValor(row, indices['numero'] ?? 1);
        String bairro = _obterValor(row, indices['bairro'] ?? 2);
        String cidade = _obterValor(row, indices['cidade'] ?? 3);
        String uf = _obterValor(row, indices['uf'] ?? 4);

        // Valida campos obrigatórios
        if (logradouro.isEmpty || cidade.isEmpty) {
          continue;
        }

        enderecos.add(Endereco(
          logradouro: StringFormatter.limpar(logradouro),
          numero: StringFormatter.limpar(numero),
          bairro: StringFormatter.limpar(bairro),
          cidade: StringFormatter.limpar(cidade),
          uf: _normalizarUF(StringFormatter.limpar(uf)),
        ));
      } catch (e) {
        // Ignora linhas com erro
        continue;
      }
    }

    return enderecos;
  }

  /// Detecta automaticamente as colunas baseado no cabeçalho
  static Map<String, int> _detectarColunas(List<dynamic> cabecalho) {
    Map<String, int> indices = {};

    for (int i = 0; i < cabecalho.length; i++) {
      String coluna = cabecalho[i].toString().toLowerCase().trim();

      if (coluna.contains('logradouro') || coluna.contains('rua') || coluna.contains('avenida')) {
        indices['logradouro'] = i;
      } else if (coluna.contains('numero') || coluna.contains('nº') || coluna.contains('num')) {
        indices['numero'] = i;
      } else if (coluna.contains('bairro')) {
        indices['bairro'] = i;
      } else if (coluna.contains('cidade') || coluna.contains('municipio')) {
        indices['cidade'] = i;
      } else if (coluna.contains('uf') || coluna.contains('estado')) {
        indices['uf'] = i;
      }
    }

    return indices;
  }

  /// Obtém valor de célula de forma segura
  static String _obterValor(List<dynamic> row, int index) {
    if (index >= row.length) return '';
    var valor = row[index];
    if (valor == null) return '';
    return valor.toString().trim();
  }

  /// Normaliza UF para 2 caracteres
  static String _normalizarUF(String uf) {
    if (uf.isEmpty) return 'SP'; // Padrão

    uf = uf.toUpperCase();

    // Se já estiver no formato correto
    if (uf.length == 2) return uf;

    // Mapa de estados por extenso
    Map<String, String> estados = {
      'SÃO PAULO': 'SP',
      'SAO PAULO': 'SP',
      'RIO DE JANEIRO': 'RJ',
      'MINAS GERAIS': 'MG',
      'BAHIA': 'BA',
      'PARANÁ': 'PR',
      'PARANA': 'PR',
      'RIO GRANDE DO SUL': 'RS',
      'PERNAMBUCO': 'PE',
      'CEARÁ': 'CE',
      'CEARA': 'CE',
      'PARÁ': 'PA',
      'PARA': 'PA',
      'SANTA CATARINA': 'SC',
      'GOIÁS': 'GO',
      'GOIAS': 'GO',
      'MARANHÃO': 'MA',
      'MARANHAO': 'MA',
      'PARAÍBA': 'PB',
      'PARAIBA': 'PB',
      'AMAZONAS': 'AM',
      'ESPÍRITO SANTO': 'ES',
      'ESPIRITO SANTO': 'ES',
      'MATO GROSSO': 'MT',
      'RIO GRANDE DO NORTE': 'RN',
      'PIAUÍ': 'PI',
      'PIAUI': 'PI',
      'ALAGOAS': 'AL',
      'DISTRITO FEDERAL': 'DF',
      'MATO GROSSO DO SUL': 'MS',
      'SERGIPE': 'SE',
      'RONDÔNIA': 'RO',
      'RONDONIA': 'RO',
      'TOCANTINS': 'TO',
      'ACRE': 'AC',
      'AMAPÁ': 'AP',
      'AMAPA': 'AP',
      'RORAIMA': 'RR',
    };

    return estados[uf] ?? uf.substring(0, 2);
  }
}
