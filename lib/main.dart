import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FindItApp());
}

// ── COLORS ────────────────────────────────────────────────────
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

// ── PUDUCHERRY ZONES ──────────────────────────────────────────
const List<Map<String, dynamic>> puducherryZones = [
  {'id': 'zone1', 'name': 'Zone 1', 'areas': 'Town & White Town',
   'lat': 11.9350, 'lng': 79.8340, 'color': 0xFFFF6B6B},
  {'id': 'zone2', 'name': 'Zone 2', 'areas': 'Lawspet & Mudaliarpet',
   'lat': 11.9620, 'lng': 79.8180, 'color': 0xFF4F8EF7},
  {'id': 'zone3', 'name': 'Zone 3', 'areas': 'Oulgaret & Villianur',
   'lat': 11.9800, 'lng': 79.7900, 'color': 0xFF5BDE8A},
  {'id': 'zone4', 'name': 'Zone 4', 'areas': 'Ariyankuppam & Bahour',
   'lat': 11.8900, 'lng': 79.8100, 'color': 0xFFF0C040},
];

// ── PUDUCHERRY LANDMARKS ──────────────────────────────────────
const List<String> puducherryLandmarks = [
  'Promenade Beach', 'White Town', 'Auroville',
  'Manakula Vinayagar Temple', 'Bus Stand', 'Railway Station',
  'Jawaharlal Nehru Street', 'Ousteri Lake', 'Botanical Garden',
  'Saram', 'Mudaliarpet Market', 'Lawspet Junction',
  'Oulgaret', 'Villianur Temple', 'Ariyankuppam',
];

// ── DATA MODELS ───────────────────────────────────────────────
class Item {
  final String id, type, title, category, location, contact, desc, postedBy;
  final bool isUrgent;
  final String? imageUrl, zone, landmark;
  final double? lat, lng;
  final int? timestamp;

  Item({
    required this.id, required this.type, required this.title,
    required this.category, required this.location, required this.contact,
    required this.desc, required this.postedBy,
    this.isUrgent = false, this.imageUrl, this.zone,
    this.landmark, this.lat, this.lng, this.timestamp,
  });
}

class AppNotification {
  final String id, title, body, type, zone;
  final int timestamp;
  bool isRead;

  AppNotification({
    required this.id, required this.title, required this.body,
    required this.type, required this.zone, required this.timestamp,
    this.isRead = false,
  });
}

// ── NOTIFICATION MANAGER ──────────────────────────────────────
class NotificationManager {
  static final List<AppNotification> _notifications = [];
  static String _userZone = 'zone1';

  static void setUserZone(String zone) => _userZone = zone;
  static String get userZone => _userZone;

  static void addNotification(Item item) {
    _notifications.insert(0, AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: item.type == 'lost' ? '🔍 Lost: ${item.title}' : '📦 Found: ${item.title}',
      body: '${item.landmark ?? item.location} · by ${item.postedBy}',
      type: item.type,
      zone: item.zone ?? 'zone1',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  static List<AppNotification> getForZone(String zone) =>
    _notifications.where((n) => n.zone == zone).toList();

  static int unreadCount(String zone) =>
    _notifications.where((n) => n.zone == zone && !n.isRead).length;

  static void markAllRead(String zone) {
    for (var n in _notifications) { if (n.zone == zone) n.isRead = true; }
  }
}

// ── APP ───────────────────────────────────────────────────────
class FindItApp extends StatelessWidget {
  const FindItApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FindIt Puducherry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: accent, secondary: accent2, surface: surface),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// LOGIN SCREEN
// ══════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true, _obscure = true, _loading = false;
  String _error = '';
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();

  Future<void> _handleAuth() async {
    setState(() { _loading = true; _error = ''; });
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
        if (_nameCtrl.text.trim().isNotEmpty) {
          await cred.user?.updateDisplayName(_nameCtrl.text.trim());
        }
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()));
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
          child: Column(children: [
            const SizedBox(height: 40),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 13, height: 13,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 12)])),
              const SizedBox(width: 10),
              const Text('FindIt', style: TextStyle(fontWeight: FontWeight.w900,
                fontSize: 28, color: textCol, letterSpacing: -0.5)),
            ]),
            const SizedBox(height: 4),
            const Text('Puducherry Lost & Found',
              style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Find what matters in your city',
              style: TextStyle(color: muted, fontSize: 12)),
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
              controller: _passCtrl, obscureText: _obscure,
              style: const TextStyle(color: textCol),
              decoration: InputDecoration(
                hintText: 'Password', hintStyle: const TextStyle(color: muted),
                prefixIcon: const Icon(Icons.lock_outline, color: muted, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                    color: muted, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure)),
                filled: true, fillColor: surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: accent2)),
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(_error, style: const TextStyle(color: lostCol, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent, foregroundColor: bg,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
          ]),
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
          boxShadow: active ? [const BoxShadow(color: Colors.black26, blurRadius: 8)] : []),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: active ? textCol : muted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
      ),
    ));
  }

  Widget _inputField(String hint, IconData icon, TextEditingController ctrl) {
    return TextField(
      controller: ctrl, style: const TextStyle(color: textCol),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: muted),
        prefixIcon: Icon(icon, color: muted, size: 20),
        filled: true, fillColor: surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent2)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTab = 0;
  String _filter = 'all', _search = '';
  List<Item> _items = [];
  String _userZone = 'zone1';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    FirebaseDatabase.instance.ref('items').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) { setState(() => _items = []); return; }
      final items = data.entries.map((e) {
        final v = Map<String, dynamic>.from(e.value as Map);
        return Item(
          id: e.key.toString(), type: v['type'] ?? 'lost',
          title: v['title'] ?? '', category: v['category'] ?? '',
          location: v['location'] ?? '', contact: v['contact'] ?? '',
          desc: v['desc'] ?? '', postedBy: v['postedBy'] ?? '',
          isUrgent: v['isUrgent'] ?? false, imageUrl: v['imageUrl'],
          zone: v['zone'] ?? 'zone1', landmark: v['landmark'],
          lat: (v['lat'] as num?)?.toDouble(),
          lng: (v['lng'] as num?)?.toDouble(),
          timestamp: (v['timestamp'] as num?)?.toInt(),
        );
      }).toList();
      setState(() => _items = items);
    });
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: textCol, fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to logout?',
          style: TextStyle(color: muted, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: muted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: lostCol, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  List<Item> get filteredItems => _items.where((item) {
    final matchFilter = _filter == 'all' || item.type == _filter;
    final matchSearch = _search.isEmpty ||
      item.title.toLowerCase().contains(_search.toLowerCase()) ||
      item.category.toLowerCase().contains(_search.toLowerCase()) ||
      item.location.toLowerCase().contains(_search.toLowerCase()) ||
      (item.landmark ?? '').toLowerCase().contains(_search.toLowerCase());
    return matchFilter && matchSearch;
  }).toList();

  int get _unreadCount => NotificationManager.unreadCount(_userZone);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(child: Column(children: [
        _buildHeader(),
        Expanded(child: IndexedStack(index: _currentTab, children: [
          _buildHomeTab(),
          _buildMapTab(),
          _buildNotificationsTab(),
          _buildProfileTab(),
        ])),
      ])),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentTab == 0
        ? FloatingActionButton.extended(
            onPressed: () => _showPostModal(context),
            backgroundColor: accent, foregroundColor: bg,
            icon: const Icon(Icons.add),
            label: const Text('Post Item', style: TextStyle(fontWeight: FontWeight.w700)))
        : null,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(color: surface,
        border: Border(top: BorderSide(color: border))),
      child: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) {
          setState(() => _currentTab = i);
          if (i == 2) { NotificationManager.markAllRead(_userZone); setState(() {}); }
        },
        backgroundColor: Colors.transparent, elevation: 0,
        selectedItemColor: accent, unselectedItemColor: muted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
            icon: Stack(children: [
              const Icon(Icons.notifications_outlined),
              if (_unreadCount > 0)
                Positioned(right: 0, top: 0, child: Container(
                  width: 14, height: 14,
                  decoration: const BoxDecoration(color: lostCol, shape: BoxShape.circle),
                  child: Center(child: Text('$_unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 8,
                      fontWeight: FontWeight.w800))))),
            ]),
            activeIcon: const Icon(Icons.notifications), label: 'Alerts'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64, padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: bg.withOpacity(0.92),
        border: const Border(bottom: BorderSide(color: border))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 10, height: 10,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 10)])),
            const SizedBox(width: 8),
            const Text('FindIt', style: TextStyle(fontWeight: FontWeight.w900,
              fontSize: 20, color: textCol, letterSpacing: -0.5)),
          ]),
          const Text('Puducherry', style: TextStyle(color: accent, fontSize: 9,
            fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ]),
        Row(children: [
          GestureDetector(
            onTap: () => setState(() => _currentTab = 3),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
              decoration: BoxDecoration(color: surface2, border: Border.all(color: border),
                borderRadius: BorderRadius.circular(100)),
              child: Row(children: [
                Container(width: 28, height: 28,
                  decoration: const BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: Center(child: Text(
                    (FirebaseAuth.instance.currentUser?.displayName ??
                     FirebaseAuth.instance.currentUser?.email ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: bg, fontWeight: FontWeight.w800, fontSize: 11)))),
                const SizedBox(width: 8),
                Text(
                  FirebaseAuth.instance.currentUser?.displayName ??
                  (FirebaseAuth.instance.currentUser?.email ?? 'User').split('@')[0],
                  style: const TextStyle(color: textCol, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _confirmLogout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(border: Border.all(color: border),
                borderRadius: BorderRadius.circular(7)),
              child: const Text('Logout', style: TextStyle(color: muted, fontSize: 12))),
          ),
        ]),
      ]),
    );
  }

  // ── HOME TAB ──────────────────────────────────────────────
  Widget _buildHomeTab() {
    return SingleChildScrollView(child: Column(children: [
      _buildHero(), _buildStats(), _buildZoneBanner(),
      _buildSearch(), _buildFilters(), _buildGrid(),
    ]));
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      child: Column(children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28,
              height: 1.1, letterSpacing: -1, color: textCol),
            children: [
              TextSpan(text: 'Reuniting Puducherry\nWith Their '),
              TextSpan(text: 'Lost Items', style: TextStyle(color: accent)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text('Post lost or found items across Puducherry.\nSmart zone alerts connect you instantly.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 13, height: 1.6)),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _heroCta('🔍 Report Lost', lostCol, () => setState(() => _filter = 'lost')),
          const SizedBox(width: 12),
          _heroCta('📦 Post Found', foundCol, () => setState(() => _filter = 'found')),
        ]),
      ]),
    );
  }

  Widget _heroCta(String label, Color col, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: col.withOpacity(0.12),
          border: Border.all(color: col.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(color: col, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }

  Widget _buildZoneBanner() {
    final zone = puducherryZones.firstWhere((z) => z['id'] == _userZone);
    final zoneColor = Color(zone['color'] as int);
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: zoneColor.withOpacity(0.08),
        border: Border.all(color: zoneColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(width: 10, height: 10,
          decoration: BoxDecoration(color: zoneColor, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: zoneColor.withOpacity(0.5), blurRadius: 6)])),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${zone['name']} — ${zone['areas']}',
            style: TextStyle(color: zoneColor, fontWeight: FontWeight.w700, fontSize: 13)),
          const Text('Your active zone · Alerts enabled',
            style: TextStyle(color: muted, fontSize: 11)),
        ])),
        GestureDetector(
          onTap: _showZonePicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: surface2, border: Border.all(color: border),
              borderRadius: BorderRadius.circular(6)),
            child: const Text('Change', style: TextStyle(color: muted, fontSize: 11))),
        ),
      ]),
    );
  }

  void _showZonePicker() {
    showModalBottomSheet(
      context: context, backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Select Your Zone', style: TextStyle(color: textCol,
            fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('You\'ll receive alerts for items in your zone',
            style: TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 20),
          ...puducherryZones.map((zone) {
            final zoneColor = Color(zone['color'] as int);
            final isSelected = _userZone == zone['id'];
            return GestureDetector(
              onTap: () {
                setState(() => _userZone = zone['id']);
                NotificationManager.setUserZone(zone['id']);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? zoneColor.withOpacity(0.1) : surface2,
                  border: Border.all(color: isSelected ? zoneColor : border),
                  borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(width: 12, height: 12,
                    decoration: BoxDecoration(color: zoneColor, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(zone['name']!, style: TextStyle(
                      color: isSelected ? zoneColor : textCol,
                      fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(zone['areas']!, style: const TextStyle(color: muted, fontSize: 12)),
                  ])),
                  if (isSelected) Icon(Icons.check_circle, color: zoneColor, size: 20),
                ]),
              ),
            );
          }),
        ]),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      decoration: BoxDecoration(color: surface, border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        _stat('${_items.length}', 'Total'),
        _stat('${_items.where((i) => i.type == 'lost').length}', 'Lost'),
        _stat('${_items.where((i) => i.type == 'found').length}', 'Found'),
        _stat('Puducherry', 'City'),
      ]),
    );
  }

  Widget _stat(String num, String label) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: border))),
      child: Column(children: [
        Text(num, style: const TextStyle(fontWeight: FontWeight.w800,
          fontSize: 13, color: accent), textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: muted, fontSize: 9, letterSpacing: 0.4),
          textAlign: TextAlign.center),
      ]),
    ));
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Container(
        decoration: BoxDecoration(color: surface, border: Border.all(color: border),
          borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Expanded(child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: textCol),
            decoration: const InputDecoration(
              hintText: 'Search items, landmarks, zones...',
              hintStyle: TextStyle(color: muted, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: muted),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          )),
          Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: accent2, borderRadius: BorderRadius.circular(9)),
            child: const Text('Search', style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w600, fontSize: 12)),
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
                borderRadius: BorderRadius.circular(100)),
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Recent Items', style: TextStyle(fontWeight: FontWeight.w700,
            fontSize: 16, color: textCol)),
          Text('${items.length} items', style: const TextStyle(color: muted, fontSize: 13)),
        ]),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(40),
            child: Column(children: [
              const Text('🔍', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text('No items yet. Be the first to post!',
                style: TextStyle(color: muted, fontSize: 14)),
            ])))
        else
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ItemCard(item: item))),
      ]),
    );
  }

  // ── MAP TAB ───────────────────────────────────────────────
  Widget _buildMapTab() {
    const puducherryCenter = LatLng(11.9416, 79.8083);
    final mappedItems = _items.where((i) => i.lat != null && i.lng != null).toList();
    Map<String, int> zoneCounts = {};
    for (var item in _items) {
      final z = item.zone ?? 'zone1';
      zoneCounts[z] = (zoneCounts[z] ?? 0) + 1;
    }

    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Puducherry Map', style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 16, color: textCol)),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: lostCol.withOpacity(0.1),
                border: Border.all(color: lostCol.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(20)),
              child: Text('${_items.where((i) => i.type == 'lost').length} lost',
                style: const TextStyle(color: lostCol, fontSize: 11, fontWeight: FontWeight.w600))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: foundCol.withOpacity(0.1),
                border: Border.all(color: foundCol.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(20)),
              child: Text('${_items.where((i) => i.type == 'found').length} found',
                style: const TextStyle(color: foundCol, fontSize: 11, fontWeight: FontWeight.w600))),
          ]),
        ]),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: puducherryCenter,
              initialZoom: 12.0, minZoom: 10.0, maxZoom: 18.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.findit'),
              // Heatmap circles
              CircleLayer(circles: puducherryZones.map((zone) {
                final count = zoneCounts[zone['id']] ?? 0;
                final zoneColor = Color(zone['color'] as int);
                return CircleMarker(
                  point: LatLng(zone['lat'] as double, zone['lng'] as double),
                  radius: count == 0 ? 600.0 : (600 + count * 150).toDouble(),
                  color: zoneColor.withOpacity(count == 0 ? 0.05 : 0.15),
                  borderColor: zoneColor.withOpacity(0.4),
                  borderStrokeWidth: 1.5,
                );
              }).toList()),
              // Zone labels
              MarkerLayer(markers: puducherryZones.map((zone) {
                final count = zoneCounts[zone['id']] ?? 0;
                final zoneColor = Color(zone['color'] as int);
                return Marker(
                  point: LatLng(zone['lat'] as double, zone['lng'] as double),
                  width: 90, height: 44,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: surface.withOpacity(0.88),
                      border: Border.all(color: zoneColor.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(8)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(zone['name']!, style: TextStyle(color: zoneColor,
                        fontSize: 10, fontWeight: FontWeight.w800)),
                      Text('$count items', style: const TextStyle(color: muted, fontSize: 9)),
                    ]),
                  ),
                );
              }).toList()),
              // Item pins
              MarkerLayer(markers: mappedItems.map((item) {
                final isLost = item.type == 'lost';
                return Marker(
                  point: LatLng(item.lat!, item.lng!),
                  width: 36, height: 36,
                  child: GestureDetector(
                    onTap: () => _showMapItemDetail(item),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isLost ? lostCol : foundCol,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(
                          color: (isLost ? lostCol : foundCol).withOpacity(0.5),
                          blurRadius: 6)]),
                      child: Center(child: Text(isLost ? '😔' : '📦',
                        style: const TextStyle(fontSize: 14))),
                    ),
                  ),
                );
              }).toList()),
            ],
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: surface,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🌡️ Heatmap: ', style: TextStyle(color: muted, fontSize: 11)),
          _heatDot(Colors.green.withOpacity(0.6)), const SizedBox(width: 4),
          const Text('Low  ', style: TextStyle(color: muted, fontSize: 11)),
          _heatDot(Colors.orange.withOpacity(0.6)), const SizedBox(width: 4),
          const Text('Medium  ', style: TextStyle(color: muted, fontSize: 11)),
          _heatDot(Colors.red.withOpacity(0.6)), const SizedBox(width: 4),
          const Text('High', style: TextStyle(color: muted, fontSize: 11)),
        ]),
      ),
    ]);
  }

  Widget _heatDot(Color col) => Container(width: 10, height: 10,
    decoration: BoxDecoration(color: col, shape: BoxShape.circle));

  void _showMapItemDetail(Item item) {
    showModalBottomSheet(
      context: context, backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: (item.type == 'lost' ? lostCol : foundCol).withOpacity(0.15),
                borderRadius: BorderRadius.circular(100)),
              child: Text(item.type.toUpperCase(),
                style: TextStyle(color: item.type == 'lost' ? lostCol : foundCol,
                  fontSize: 10, fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            Text(item.category, style: const TextStyle(color: muted, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          Text(item.title, style: const TextStyle(color: textCol,
            fontWeight: FontWeight.w700, fontSize: 18)),
          if (item.landmark != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.place, color: accent, size: 14),
              const SizedBox(width: 4),
              Text(item.landmark!, style: const TextStyle(color: accent, fontSize: 12)),
            ]),
          ],
          const SizedBox(height: 4),
          Text(item.desc, style: const TextStyle(color: muted, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: accent2,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)))),
        ]),
      ),
    );
  }

  // ── NOTIFICATIONS TAB ─────────────────────────────────────
  Widget _buildNotificationsTab() {
    final notifications = NotificationManager.getForZone(_userZone);
    final zone = puducherryZones.firstWhere((z) => z['id'] == _userZone);

    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Zone Alerts', style: TextStyle(fontWeight: FontWeight.w700,
              fontSize: 16, color: textCol)),
            Text('${zone['name']} — ${zone['areas']}',
              style: const TextStyle(color: muted, fontSize: 11)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: accent.withOpacity(0.1),
              border: Border.all(color: accent.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(20)),
            child: Text('${notifications.length} alerts',
              style: const TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
      ),
      Expanded(child: notifications.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🔔', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text('No alerts yet for your zone',
              style: TextStyle(color: muted, fontSize: 14)),
            const SizedBox(height: 6),
            const Text('Post an item to trigger zone alerts',
              style: TextStyle(color: border, fontSize: 12)),
          ]))
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final notif = notifications[i];
              final isLost = notif.type == 'lost';
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: notif.isRead ? surface : surface2,
                  border: Border.all(color: notif.isRead ? border
                    : (isLost ? lostCol : foundCol).withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: (isLost ? lostCol : foundCol).withOpacity(0.15),
                      shape: BoxShape.circle),
                    child: Center(child: Text(isLost ? '😔' : '📦',
                      style: const TextStyle(fontSize: 20)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(notif.title, style: TextStyle(
                      color: notif.isRead ? muted : textCol,
                      fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(notif.body, style: const TextStyle(color: muted, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(_timeAgo(notif.timestamp),
                      style: const TextStyle(color: border, fontSize: 10)),
                  ])),
                  if (!notif.isRead) Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: accent, shape: BoxShape.circle)),
                ]),
              );
            })),
    ]);
  }

  String _timeAgo(int timestamp) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── PROFILE TAB ───────────────────────────────────────────
  Widget _buildProfileTab() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? (user?.email ?? 'User').split('@')[0];
    final email = user?.email ?? '';
    final myItems = _items.where((i) =>
      i.postedBy == name || i.postedBy == email.split('@')[0]).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 80, height: 80,
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 20)]),
          child: Center(child: Text(name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: bg, fontWeight: FontWeight.w900, fontSize: 32)))),
        const SizedBox(height: 14),
        Text(name, style: const TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 22)),
        const SizedBox(height: 4),
        Text(email, style: const TextStyle(color: muted, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: foundCol.withOpacity(0.1),
            border: Border.all(color: foundCol.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20)),
          child: const Text('✅ Puducherry Member',
            style: TextStyle(color: foundCol, fontSize: 11, fontWeight: FontWeight.w600))),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(color: surface, border: Border.all(color: border),
            borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            _profileStat('${myItems.length}', 'Posts'),
            _profileStat('${myItems.where((i) => i.type == 'lost').length}', 'Lost'),
            _profileStat('${myItems.where((i) => i.type == 'found').length}', 'Found'),
          ]),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _showZonePicker,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: surface, border: Border.all(color: border),
              borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Container(width: 38, height: 38,
                decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.location_city, color: muted, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('My Zone', style: TextStyle(color: textCol,
                  fontWeight: FontWeight.w600, fontSize: 14)),
                Text(() {
                  final zone = puducherryZones.firstWhere((z) => z['id'] == _userZone);
                  return '${zone['name']} — ${zone['areas']}';
                }(), style: const TextStyle(color: muted, fontSize: 11)),
              ])),
              const Icon(Icons.chevron_right, color: muted, size: 18),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        _profileOption(Icons.notifications_outlined, 'Notification Preferences', 'Zone alert settings', () {}),
        _profileOption(Icons.shield_outlined, 'Privacy & Security', 'Account security', () {}),
        _profileOption(Icons.help_outline, 'Help & Support', 'Get help with FindIt', () {}),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: lostCol.withOpacity(0.15), foregroundColor: lostCol,
              side: BorderSide(color: lostCol.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0)),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _profileStat(String num, String label) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: border))),
      child: Column(children: [
        Text(num, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: accent)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: muted, fontSize: 10)),
      ]),
    ));
  }

  Widget _profileOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: surface, border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: muted, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: textCol, fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: muted, fontSize: 11)),
          ])),
          const Icon(Icons.chevron_right, color: muted, size: 18),
        ]),
      ),
    );
  }

  void _showPostModal(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => PostItemSheet(
        defaultZone: _userZone,
        onPosted: (item) { NotificationManager.addNotification(item); setState(() {}); },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ITEM CARD
// ══════════════════════════════════════════════════════════════
class _ItemCard extends StatelessWidget {
  final Item item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isLost = item.type == 'lost';
    final tagColor = isLost ? lostCol : foundCol;
    final zone = puducherryZones.firstWhere(
      (z) => z['id'] == item.zone, orElse: () => puducherryZones[0]);
    final zoneColor = Color(zone['color'] as int);

    return Container(
      decoration: BoxDecoration(color: surface, border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
              ? Image.network(item.imageUrl!, height: 140, width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _emojiPlaceholder())
              : _emojiPlaceholder()),
          Positioned(top: 8, left: 8, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: surface.withOpacity(0.85),
              border: Border.all(color: zoneColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(6)),
            child: Text(zone['name']!,
              style: TextStyle(color: zoneColor, fontSize: 9, fontWeight: FontWeight.w800)))),
          if (item.isUrgent)
            Positioned(top: 8, right: 8, child: _badge('URGENT', urgent, Colors.white)),
        ]),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _tag(item.type.toUpperCase(), tagColor),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: surface2, border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(6)),
                child: Text(item.category, style: const TextStyle(color: muted, fontSize: 11))),
            ]),
            const SizedBox(height: 8),
            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700,
              fontSize: 15, color: textCol)),
            if (item.landmark != null) ...[
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.place, color: accent, size: 12),
                const SizedBox(width: 3),
                Text(item.landmark!, style: const TextStyle(color: accent, fontSize: 11)),
              ]),
            ],
            const SizedBox(height: 4),
            Text(item.desc, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: muted, fontSize: 12, height: 1.5)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: border))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.location_on_outlined, color: muted, size: 12),
                    const SizedBox(width: 3),
                    Expanded(child: Text(item.location, maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 11))),
                  ]),
                  Text('by ${item.postedBy}', style: const TextStyle(color: muted, fontSize: 11)),
                ])),
                Row(children: [
                  _cardBtn('Contact', accent2, () => _showContact(context)),
                  const SizedBox(width: 5),
                  _cardBtn('Share', muted, () {}),
                ]),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _emojiPlaceholder() => Container(height: 140, color: surface2,
    child: Center(child: Text(
      item.category == 'Pets' ? '🐕' : item.category == 'Electronics' ? '📱' :
      item.category == 'Keys' ? '🔑' : item.category == 'Bags' ? '🎒' : '📦',
      style: const TextStyle(fontSize: 48))));

  void _showContact(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Contact ${item.postedBy}',
        style: const TextStyle(color: textCol, fontWeight: FontWeight.w700)),
      content: Row(children: [
        const Text('📧', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
          children: [
          const Text('Email', style: TextStyle(color: muted, fontSize: 11)),
          Text(item.contact, style: const TextStyle(color: textCol,
            fontSize: 14, fontWeight: FontWeight.w500)),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: muted))),
      ],
    ));
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
    child: Text(text, style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.w800)));

  Widget _tag(String text, Color col) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: col.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
    child: Text(text, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.w800)));

  Widget _cardBtn(String label, Color col, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: surface2,
        border: Border.all(color: col.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.w500))));
}

// ══════════════════════════════════════════════════════════════
// POST ITEM SHEET
// ══════════════════════════════════════════════════════════════
class PostItemSheet extends StatefulWidget {
  final String defaultZone;
  final Function(Item) onPosted;
  const PostItemSheet({super.key, required this.defaultZone, required this.onPosted});
  @override
  State<PostItemSheet> createState() => _PostItemSheetState();
}

class _PostItemSheetState extends State<PostItemSheet> {
  String _type = 'lost', _category = 'Electronics';
  bool _isUrgent = false;
  String? _selectedZone, _selectedLandmark;
  File? _pickedImage;
  double? _selectedLat, _selectedLng;

  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _contactCtrl  = TextEditingController();

  final List<String> _categories = [
    'Electronics', 'Pets', 'Keys', 'Bags',
    'Accessories', 'Documents', 'Clothing', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _selectedZone = widget.defaultZone;
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context, backgroundColor: surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.camera_alt, color: accent),
          title: const Text('Take Photo', style: TextStyle(color: textCol)),
          onTap: () async {
            Navigator.pop(context);
            final img = await ImagePicker().pickImage(
              source: ImageSource.camera, imageQuality: 80);
            if (img != null) setState(() => _pickedImage = File(img.path));
          }),
        ListTile(
          leading: const Icon(Icons.photo_library, color: accent),
          title: const Text('Choose from Gallery', style: TextStyle(color: textCol)),
          onTap: () async {
            Navigator.pop(context);
            final img = await ImagePicker().pickImage(
              source: ImageSource.gallery, imageQuality: 80);
            if (img != null) setState(() => _pickedImage = File(img.path));
          }),
        const SizedBox(height: 8),
      ])),
    );
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
      context, MaterialPageRoute(builder: (_) => const LocationPickerScreen()));
    if (result != null) {
      setState(() {
        _selectedLat = result.latitude;
        _selectedLng = result.longitude;
        if (_locationCtrl.text.isEmpty) {
          _locationCtrl.text = _selectedLandmark ??
            '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}';
        }
      });
    }
  }

  Future<void> _postItem(BuildContext ctx) async {
    if (_titleCtrl.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    final ref = FirebaseDatabase.instance.ref('items').push();
    final postedBy = user?.displayName ?? (user?.email ?? 'User').split('@')[0];

    await ref.set({
      'type': _type, 'title': _titleCtrl.text.trim(),
      'category': _category, 'desc': _descCtrl.text.trim(),
      'location': _locationCtrl.text.trim().isEmpty
        ? (_selectedLandmark ?? 'Puducherry') : _locationCtrl.text.trim(),
      'contact': _contactCtrl.text.trim().isEmpty
        ? (user?.email ?? '') : _contactCtrl.text.trim(),
      'postedBy': postedBy, 'isUrgent': _isUrgent,
      'zone': _selectedZone ?? 'zone1',
      'landmark': _selectedLandmark,
      'timestamp': ServerValue.timestamp,
      if (_selectedLat != null) 'lat': _selectedLat,
      if (_selectedLng != null) 'lng': _selectedLng,
      'imageUrl': '',
    });

    widget.onPosted(Item(
      id: ref.key ?? '', type: _type, title: _titleCtrl.text.trim(),
      category: _category, location: _locationCtrl.text.trim(),
      contact: _contactCtrl.text.trim(), desc: _descCtrl.text.trim(),
      postedBy: postedBy, zone: _selectedZone ?? 'zone1',
      landmark: _selectedLandmark,
    ));

    if (ctx.mounted) {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: const Text('✅ Item posted! Zone alert sent.'),
        backgroundColor: foundCol, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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

            // Photo
            _formLabel('Photo'),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity, height: 130,
                decoration: BoxDecoration(color: surface2, border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(12)),
                child: _pickedImage != null
                  ? Stack(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12),
                        child: Image.file(_pickedImage!, width: double.infinity,
                          height: 130, fit: BoxFit.cover)),
                      Positioned(top: 8, right: 8, child: GestureDetector(
                        onTap: () => setState(() => _pickedImage = null),
                        child: Container(padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.black54,
                            borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                    ])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.add_photo_alternate_outlined, color: muted, size: 30),
                      const SizedBox(height: 6),
                      const Text('Tap to add photo', style: TextStyle(color: muted, fontSize: 12)),
                    ]),
              ),
            ),
            const SizedBox(height: 14),

            _formLabel('Item Title'),
            _formInput('e.g. Black iPhone 15 Pro', _titleCtrl),
            const SizedBox(height: 14),

            _formLabel('Category'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: surface2, border: Border.all(color: border),
                borderRadius: BorderRadius.circular(9)),
              child: DropdownButton<String>(
                value: _category, dropdownColor: surface2,
                isExpanded: true, underline: const SizedBox(),
                style: const TextStyle(color: textCol, fontSize: 14),
                items: _categories.map((c) => DropdownMenuItem(value: c,
                  child: Text(c, style: const TextStyle(color: textCol)))).toList(),
                onChanged: (v) => setState(() => _category = v!)),
            ),
            const SizedBox(height: 14),

            _formLabel('Zone'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: surface2, border: Border.all(color: border),
                borderRadius: BorderRadius.circular(9)),
              child: DropdownButton<String>(
                value: _selectedZone, dropdownColor: surface2,
                isExpanded: true, underline: const SizedBox(),
                style: const TextStyle(color: textCol, fontSize: 14),
                items: puducherryZones.map((z) => DropdownMenuItem(
                  value: z['id'] as String,
                  child: Text('${z['name']} — ${z['areas']}',
                    style: const TextStyle(color: textCol, fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _selectedZone = v)),
            ),
            const SizedBox(height: 14),

            _formLabel('Landmark'),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: puducherryLandmarks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final lm = puducherryLandmarks[i];
                  final selected = _selectedLandmark == lm;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedLandmark = selected ? null : lm;
                      if (!selected) _locationCtrl.text = lm;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? accent.withOpacity(0.15) : surface2,
                        border: Border.all(color: selected ? accent : border),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(lm, style: TextStyle(
                        color: selected ? accent : muted, fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            _formLabel('Description'),
            TextField(
              controller: _descCtrl, maxLines: 3,
              style: const TextStyle(color: textCol),
              decoration: InputDecoration(
                hintText: 'Describe the item in detail...',
                hintStyle: const TextStyle(color: muted),
                filled: true, fillColor: surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: accent2))),
            ),
            const SizedBox(height: 14),

            _formLabel('Location'),
            Row(children: [
              Expanded(child: _formInput('Where was it lost/found?',
                _locationCtrl, Icons.location_on_outlined)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _pickLocation,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _selectedLat != null ? accent2.withOpacity(0.15) : surface2,
                    border: Border.all(color: _selectedLat != null ? accent2 : border),
                    borderRadius: BorderRadius.circular(9)),
                  child: Icon(Icons.map_outlined,
                    color: _selectedLat != null ? accent2 : muted, size: 22))),
            ]),
            if (_selectedLat != null)
              Padding(padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: foundCol, size: 14),
                  const SizedBox(width: 4),
                  Text('Pin: ${_selectedLat!.toStringAsFixed(3)}, ${_selectedLng!.toStringAsFixed(3)}',
                    style: const TextStyle(color: foundCol, fontSize: 11)),
                ])),
            const SizedBox(height: 14),

            _formLabel('Contact Info'),
            _formInput('Your email or phone', _contactCtrl, Icons.contact_mail_outlined),
            const SizedBox(height: 14),

            GestureDetector(
              onTap: () => setState(() => _isUrgent = !_isUrgent),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: urgent.withOpacity(0.07),
                  border: Border.all(color: urgent.withOpacity(0.25)),
                  borderRadius: BorderRadius.circular(9)),
                child: Row(children: [
                  Checkbox(value: _isUrgent, onChanged: (v) => setState(() => _isUrgent = v!),
                    activeColor: urgent, side: const BorderSide(color: muted)),
                  const SizedBox(width: 6),
                  const Expanded(child: Text('Mark as Urgent — notify all zones',
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
                  backgroundColor: accent, foregroundColor: bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Post ${_type == 'lost' ? 'Lost' : 'Found'} Item →',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
            ),
            const SizedBox(height: 10),
          ]),
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

  Widget _formLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(label.toUpperCase(),
      style: const TextStyle(color: muted, fontSize: 11,
        fontWeight: FontWeight.w600, letterSpacing: 0.4)));

  Widget _formInput(String hint, TextEditingController ctrl, [IconData? icon]) {
    return TextField(
      controller: ctrl, style: const TextStyle(color: textCol),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: muted),
        prefixIcon: icon != null ? Icon(icon, color: muted, size: 20) : null,
        filled: true, fillColor: surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: accent2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)));
  }
}

// ══════════════════════════════════════════════════════════════
// LOCATION PICKER — Puducherry focused
// ══════════════════════════════════════════════════════════════
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng _selectedPoint = const LatLng(11.9416, 79.8083);
  bool _pinSet = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        title: const Text('Pick Location — Puducherry',
          style: TextStyle(color: textCol, fontWeight: FontWeight.w700, fontSize: 15)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textCol),
          onPressed: () => Navigator.pop(context)),
        actions: [
          if (_pinSet)
            TextButton(
              onPressed: () => Navigator.pop(context, _selectedPoint),
              child: const Text('Use This',
                style: TextStyle(color: accent, fontWeight: FontWeight.w700))),
        ],
      ),
      body: Stack(children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _selectedPoint,
            initialZoom: 12.0, minZoom: 10.0, maxZoom: 18.0,
            onTap: (_, point) => setState(() { _selectedPoint = point; _pinSet = true; })),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.findit'),
            if (_pinSet)
              MarkerLayer(markers: [
                Marker(point: _selectedPoint, width: 50, height: 50,
                  child: const Icon(Icons.location_pin, color: lostCol, size: 50)),
              ]),
          ],
        ),
        Positioned(top: 16, left: 16, right: 16, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: surface.withOpacity(0.92),
            border: Border.all(color: border), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.touch_app, color: accent, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              _pinSet ? '📍 Pin set! Tap "Use This" or move pin'
                : 'Tap on Puducherry map to drop a pin',
              style: const TextStyle(color: textCol, fontSize: 12))),
          ]),
        )),
        if (_pinSet)
          Positioned(bottom: 24, left: 24, right: 24,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selectedPoint),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent, foregroundColor: bg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('✅ Confirm Location',
                style: TextStyle(fontWeight: FontWeight.w800)))),
      ]),
    );
  }
}