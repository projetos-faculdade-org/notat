class Note {
  final String document;
  final String title;
  final String folder;
  final DateTime date;
  final String uid;
  final String
      searchableDocument; //This was originally created to allow search function
  Note(
      {required this.document,
      required this.searchableDocument,
      required this.title,
      required this.folder,
      required this.date,
      required this.uid});

  /// Nota montada a partir do que o usuario digitou no editor:
  /// titulo vazio vira 'untitled' e o texto buscavel fica em minusculas,
  /// sem as quebras de linha (que chegam como "\n" porque vem do jsonEncode).
  factory Note.fromEditor(
      {required String document,
      required String searchableDocument,
      required String title,
      required String folder,
      required DateTime date,
      required String uid}) {
    return Note(
        folder: folder,
        document: document,
        searchableDocument:
            searchableDocument.toLowerCase().replaceAll('\\n', ' '),
        date: date,
        uid: uid,
        title: title.isNotEmpty ? title : 'untitled');
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'folder': folder,
      'date': date,
      'uid': uid,
      'document': document,
      'searchableDocument': searchableDocument,
    };
  }
}
