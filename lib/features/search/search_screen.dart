import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Поиск', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Треки, исполнители, альбомы',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(onPressed: () { _controller.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded)),
            filled: true, fillColor: const Color(0xFF191B1F),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
        Text(_controller.text.isEmpty ? 'Популярные жанры' : 'Результаты демо-поиска', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        if (_controller.text.isEmpty)
          Wrap(spacing: 10, runSpacing: 10, children: const [
            _Genre('Альтернатива', Color(0xFF6A397A)), _Genre('Поп', Color(0xFF295E7B)),
            _Genre('Инди', Color(0xFF34654E)), _Genre('Электроника', Color(0xFF78452E)),
          ])
        else
          const Text('Подключение каталога будет добавлено на этапе интеграции API.', style: TextStyle(color: Colors.white60)),
      ]),
    ),
  );
}

class _Genre extends StatelessWidget {
  const _Genre(this.name, this.color);
  final String name;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
    child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}
