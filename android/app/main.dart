import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FindItApp());
}

const bg       = Color(0xFF0D0F14);
const surface  = Color(0xFF161920);
const surface2 = Color(0xFF1E2230);
const border   = Color(0xFF2A2F3E);
const accent   = Color(0xFFF0C040);
const accent2  = Color(0xFF4F8EF7);
const lostCol  = Color(0xFFFF6B6B);
const foundCol = Color(0xFF5BDE8A);
const urgent   = Color(0xFFFF9900);
const textCol  = Color(0xFFEEF0F6);
const muted    = Color(0xFF7A8097);

class Item {
  final String id, type, title, category, location, contact, desc, postedBy;
  final bool isUrgent;
  Item({required this.id, required this.type, required this.title,
    required this.category, required this.location, required this.contact,
    required this.desc, required this.postedBy,
    this.isUrgent = false});
}

class FindItApp extends StatelessWidget {
  const FindItApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FindIt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accent2,
          surface: surface,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _obscure = true;
  bool _loading = false;
  String _error = '';
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();

  Future<void> _handleAuth() async {
    setState(() { _loading = true; _error = ''; });
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 13, height: 13,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 12)])),
                const SizedBox(width: 10),
                const Text('FindIt', style: TextStyle(fontWeight: FontWeight.w900,
                  fontSize: 28, color: textCol, letterSpacing: -0.5)),
              ]),
              const SizedBox(height: 6),
              const Text('Lost & Found — Anywhere, Anytime',
                style: TextStyle(color: muted, fontSize: 13)),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.all(4),
                child: Row(children: [
                  _tab('Sign In', _isLogin, () => setState(() => _isLogin = true)),
                  _tab('Create Account', !_isLogin, () => setState(() => _isLogin = false)),
                ]),
              ),
              const SizedBox(height: 24),
              if (!_isLogin) ...[
                _inputField('Full Name', Icons.person_outline, _nameCtrl),
                const SizedBox(height: 14),
              ],
              _inputField('Email Address', Icons.email_outlined, _emailCtrl),
              const SizedBox(height: 14),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: textCol),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: muted),
                  prefixIcon: const Icon(Icons.lock_outline, color: muted, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: muted, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true, fillColor: surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: accent2)),
                ),
              ),
              const SizedBox(height: 12),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error, style: const TextStyle(color: lostCol, fontSize: 12)),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: bg,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(_isLogin ? 'Sign In →' : 'Create Account →',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => setState(() => _isLogin = !_isLogin),
                child: RichText(text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: muted),
                  children: [
                    TextSpan(text: _isLogin ? "Don't have an account? " : 'Already have an account? '),
                    TextSpan(text: _isLogin ? 'Create one free' : 'Sign In',
                      style: const TextStyle(color: accent2, fontWeight: FontWeight.w600)),
                  ],
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? surface : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: active ? [const BoxShadow(color: Colors.black26, blurRadius: 8)] : [],
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: active ? textCol : muted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
      ),
    ));
  }

  Widget _inputField(String hint, IconData icon, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: textCol),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: muted),
        prefixIcon: Icon(icon, color: muted, size: 20),
        filled: true, fillColor: surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: accent2)),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _filter = 'all';
  String _search = '';
  List<Item> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    final ref = FirebaseDatabase.instance.ref('items');
    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        setState(() => _items = []);
        return;
      }
      final items = data.entries.map((e) {
        final v = Map<String, dynamic>.from(e.value as Map);
        return Item(
          id: e.key.toString(),
          type: v['type'] ?? 'lost',
          title: v['title'] ?? '',
          category: v['category'] ?? '',
          location: v['location'] ?? '',
          contact: v['contact'] ?? '',
          desc: v['desc'] ?? '',
          postedBy: v['postedBy'] ?? '',
          isUrgent: v['isUrgent'] ?? false,
        );
      }).toList();
      setState(() => _items = items);
    });
  }

  List<Item> get filteredItems {
    return _items.where((item) {
      final matchFilter = _filter == 'all' || item.type == _filter;
      final matchSearch = _search.isEmpty ||
        item.title.toLowerCase().contains(_search.toLowerCase()) ||
        item.category.toLowerCase().contains(_search.toLowerCase()) ||
        item.location.toLowerCase().contains(_search.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHero(),
                    _buildStats(),
                    _buildSearch(),
                    _buildFilters(),
                    _buildGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPostModal(context),
        backgroundColor: accent,
        foregroundColor: bg,
        icon: const Icon(Icons.add),
        label: const Text('Post Item', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.92),
        border: const Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(width: 10, height: 10,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 10)])),
            const SizedBox(width: 8),
            const Text('FindIt', style: TextStyle(fontWeight: FontWeight.w900,
              fontSize: 20, color: textCol, letterSpacing: -0.5)),
          ]),
          Row(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
              decoration: BoxDecoration(
                color: surface2, border: Border.all(color: border),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(children: [
                Container(width: 28, height: 28,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: Center(child: Text(
                    (FirebaseAuth.instance.currentUser?.email ?? 'U').split('@')[0][0].toUpperCase(),
                    style: const TextStyle(color: bg, fontWeight: FontWeight.w800, fontSize: 11),
                  ))),
                const SizedBox(width: 8),
                Text(
                  (FirebaseAuth.instance.currentUser?.email ?? 'User').split('@')[0],
                  style: const TextStyle(color: textCol, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: border), borderRadius: BorderRadius.circular(7)),
                child: const Text('Logout', style: TextStyle(color: muted, fontSize: 12)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32,
                height: 1.1, letterSpacing: -1, color: textCol),
              children: [
                TextSpan(text: 'Reuniting People\nWith Their '),
                TextSpan(text: 'Lost Items', style: TextStyle(color: accent)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Post lost or found items. Smart matching connects\nyou with the right person instantly.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 14, height: 1.6)),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _heroCta('🔍 Report Lost', lostCol, () => setState(() => _filter = 'lost')),
            const SizedBox(width: 12),
            _heroCta('📦 Post Found', foundCol, () => setState(() => _filter = 'found')),
          ]),
        ],
      ),
    );
  }

  Widget _heroCta(String label, Color col, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: col.withOpacity(0.12),
          border: Border.all(color: col.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(color: col, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: surface, border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        _stat('${_items.length}', 'Items Posted'),
        _stat('${_items.where((i) => i.type == 'lost').length}', 'Lost'),
        _stat('${_items.where((i) => i.type == 'found').length}', 'Found'),
        _stat('4.8★', 'Rating'),
      ]),
    );
  }

  Widget _stat(String num, String label) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(border: Border(right: BorderSide(color: border))),
      child: Column(children: [
        Text(num, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: accent)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: muted, fontSize: 9, letterSpacing: 0.4),
          textAlign: TextAlign.center),
      ]),
    ));
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: surface, border: Border.all(color: border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Expanded(child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: textCol),
            decoration: const InputDecoration(
              hintText: 'Search items, locations, categories...',
              hintStyle: TextStyle(color: muted, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: muted),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          )),
          Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: accent2, borderRadius: BorderRadius.circular(9)),
            child: const Text('Search', style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ]),
      ),
    );
  }

  Widget _buildFilters() {
    final chips = ['all', 'lost', 'found', 'Electronics', 'Pets', 'Keys', 'Bags'];
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = chips[i];
          final active = _filter == chip;
          return GestureDetector(
            onTap: () => setState(() => _filter = chip),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? accent.withOpacity(0.1) : Colors.transparent,
                border: Border.all(color: active ? accent : border),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(chip == 'all' ? 'All Items' : chip,
                style: TextStyle(color: active ? accent : muted,
                  fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid() {
    final items = filteredItems;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Recent Items', style: TextStyle(fontWeight: FontWeight.w700,
              fontSize: 16, color: textCol)),
            Text('${items.length} items', style: const TextStyle(color: muted, fontSize: 13)),
          ]),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(children: [
                const Text('🔍', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text('No items posted yet. Be the first!',
                  style: TextStyle(color: muted, fontSize: 14)),
              ]),
            ))
          else
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ItemCard(item: item),
            )),
        ],
      ),
    );
  }

  void _showPostModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const PostItemSheet(),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Item item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isLost = item.type == 'lost';
    final tagColor = isLost ? lostCol : foundCol;

    return Container(
      decoration: BoxDecoration(
        color: surface, border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: surface2,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Center(child: Text(
                  item.category == 'Pets' ? '🐕' :
                  item.category == 'Electronics' ? '📱' :
                  item.category == 'Keys' ? '🔑' :
                  item.category == 'Bags' ? '🎒' : '📦',
                  style: const TextStyle(fontSize: 48))),
              ),
              Positioned(top: 8, right: 8, child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item.isUrgent) _badge('URGENT', urgent, Colors.white),
                ],
              )),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _tag(item.type.toUpperCase(), tagColor),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: surface2, border: Border.all(color: border),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(item.category, style: const TextStyle(color: muted, fontSize: 11)),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(item.title, style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15, color: textCol)),
                const SizedBox(height: 4),
                Text(item.desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 12, height: 1.5)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: border))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.location_on_outlined, color: muted, size: 12),
                            const SizedBox(width: 3),
                            Expanded(child: Text(item.location, maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: muted, fontSize: 11))),
                          ]),
                          const SizedBox(height: 2),
                          Text('by ${item.postedBy}',
                            style: const TextStyle(color: muted, fontSize: 11)),
                        ],
                      )),
                      Row(children: [
                        _cardBtn('Contact', accent2, () => _showContact(context)),
                        const SizedBox(width: 5),
                        _cardBtn('Share', muted, () {}),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContact(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Contact ${item.postedBy}',
        style: const TextStyle(color: textCol, fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _contactRow('📧', 'Email', item.contact),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: muted))),
      ],
    ));
  }

  Widget _contactRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: muted, fontSize: 11)),
          Text(value, style: const TextStyle(color: textCol, fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }

  Widget _tag(String text, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: col.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
      child: Text(text, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _cardBtn(String label, Color col, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: surface2, border: Border.all(color: col.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class PostItemSheet extends StatefulWidget {
  const PostItemSheet({super.key});
  @override
  State<PostItemSheet> createState() => _PostItemSheetState();
}

class _PostItemSheetState extends State<PostItemSheet> {
  String _type = 'lost';
  bool _isUrgent = false;
  String _category = 'Electronics';
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _contactCtrl  = TextEditingController();

  final List<String> _categories = [
    'Electronics', 'Pets', 'Keys', 'Bags', 'Accessories',
    'Documents', 'Clothing', 'Other'
  ];

  Future<void> _postItem(BuildContext context) async {
    if (_titleCtrl.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    final ref = FirebaseDatabase.instance.ref('items').push();
    await ref.set({
      'type': _type,
      'title': _titleCtrl.text.trim(),
      'category': _category,
      'desc': _descCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'contact': _contactCtrl.text.trim().isEmpty
          ? (user?.email ?? '')
          : _contactCtrl.text.trim(),
      'postedBy': (user?.email ?? 'User').split('@')[0],
      'isUrgent': _isUrgent,
      'timestamp': ServerValue.timestamp,
    });
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Item posted successfully!'),
          backgroundColor: foundCol,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Post an Item', style: TextStyle(fontWeight: FontWeight.w800,
                  fontSize: 20, color: textCol)),
                GestureDetector(onTap: () => Navigator.pop(context),
                  child: Container(width: 32, height: 32,
                    decoration: BoxDecoration(border: Border.all(color: border),
                      borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close, color: muted, size: 18))),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                _typeBtn('lost', '😔 Lost', lostCol),
                const SizedBox(width: 10),
                _typeBtn('found', '🎉 Found', foundCol),
              ]),
              const SizedBox(height: 16),
              _formLabel('Item Title'),
              _formInput('e.g. Black iPhone 15 Pro', _titleCtrl),
              const SizedBox(height: 14),
              _formLabel('Category'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: surface2, border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(9)),
                child: DropdownButton<String>(
                  value: _category,
                  dropdownColor: surface2,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: const TextStyle(color: textCol, fontSize: 14),
                  items: _categories.map((c) => DropdownMenuItem(value: c,
                    child: Text(c, style: const TextStyle(color: textCol)))).toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
              ),
              const SizedBox(height: 14),
              _formLabel('Description'),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                style: const TextStyle(color: textCol),
                decoration: InputDecoration(
                  hintText: 'Describe the item in detail...',
                  hintStyle: const TextStyle(color: muted),
                  filled: true, fillColor: surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: accent2)),
                ),
              ),
              const SizedBox(height: 14),
              _formLabel('Location'),
              _formInput('Where was it lost/found?', _locationCtrl, Icons.location_on_outlined),
              const SizedBox(height: 14),
              _formLabel('Contact Info'),
              _formInput('Your email or phone', _contactCtrl, Icons.contact_mail_outlined),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => setState(() => _isUrgent = !_isUrgent),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: urgent.withOpacity(0.07),
                    border: Border.all(color: urgent.withOpacity(0.25)),
                    borderRadius: BorderRadius.circular(9)),
                  child: Row(children: [
                    Checkbox(value: _isUrgent, onChanged: (v) => setState(() => _isUrgent = v!),
                      activeColor: urgent, side: const BorderSide(color: muted)),
                    const SizedBox(width: 6),
                    const Expanded(child: Text('Mark as Urgent — notify more people',
                      style: TextStyle(color: muted, fontSize: 13))),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _postItem(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Post ${_type == 'lost' ? 'Lost' : 'Found'} Item',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBtn(String type, String label, Color col) {
    final active = _type == type;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? col.withOpacity(0.12) : Colors.transparent,
          border: Border.all(color: active ? col : border),
          borderRadius: BorderRadius.circular(9)),
        child: Center(child: Text(label,
          style: TextStyle(color: active ? col : muted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400, fontSize: 14))),
      ),
    ));
  }

  Widget _formLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label.toUpperCase(),
        style: const TextStyle(color: muted, fontSize: 11,
          fontWeight: FontWeight.w600, letterSpacing: 0.4)),
    );
  }

  Widget _formInput(String hint, TextEditingController ctrl, [IconData? icon]) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: textCol),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: muted),
        prefixIcon: icon != null ? Icon(icon, color: muted, size: 20) : null,
        filled: true, fillColor: surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: accent2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
