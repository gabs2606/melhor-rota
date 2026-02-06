class StringFormatter {
  /// Remove caracteres especiais, espaços extras e normaliza o texto
  static String limpar(String texto) {
    if (texto.isEmpty) return '';

    // Remove espaços múltiplos
    texto = texto.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Remove caracteres especiais perigosos, mantém números e letras
    texto = texto.replaceAll(RegExp(r'[^\w\s\-.,ãáàâäéèêëíìîïóòôöõúùûüç]', unicode: true), '');

    // Capitaliza primeira letra de cada palavra
    texto = _capitalizarPalavras(texto);

    return texto.trim();
  }

  /// Capitaliza a primeira letra de cada palavra
  static String _capitalizarPalavras(String texto) {
    return texto.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Monta string de busca otimizada para Nominatim
  static String montarBuscaNominatim(String logradouro, String numero, String bairro, String cidade, String uf) {
    List<String> partes = [];

    if (logradouro.isNotEmpty) partes.add(logradouro);
    if (numero.isNotEmpty) partes.add(numero);
    if (bairro.isNotEmpty) partes.add(bairro);
    if (cidade.isNotEmpty) partes.add(cidade);
    if (uf.isNotEmpty) partes.add(uf);

    return partes.join(', ');
  }
}
