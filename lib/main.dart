import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p1p1_dracailles/theme/colors.dart';
import 'package:p1p1_dracailles/theme/fantasy_theme.dart';
import 'package:p1p1_dracailles/theme/themes.dart';
import 'package:p1p1_dracailles/widgets/devmeup_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Polices Cinzel et Roboto embarquées (assets/google_fonts) : l'app ne télécharge rien.
  GoogleFonts.config.allowRuntimeFetching = false;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: FantasyPalette.obsidian,
      systemNavigationBarDividerColor: FantasyPalette.obsidian,
    ),
  );
  runApp(const P1P1App());
}

// ---------------------------------------------------------------------------
// Données
// ---------------------------------------------------------------------------

/// Un set de draft proposé dans l'app (assets/sets/sets.json).
class SetInfo {
  final String id, name, code, tierNote;
  SetInfo.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      name = j['name'],
      code = j['code'],
      tierNote = j['tierNote'];

  static Future<List<SetInfo>> loadAll() async {
    final j = jsonDecode(await rootBundle.loadString('assets/sets/sets.json'));
    return [for (final s in j) SetInfo.fromJson(s)];
  }
}

class CardInfo {
  final String name, id, rarity, type, hero, reason, setId;
  final int pitch, score;
  CardInfo.fromJson(Map<String, dynamic> j, this.setId)
    : name = j['name'],
      id = j['id'],
      rarity = j['rarity'],
      type = j['type'],
      hero = j['hero'],
      reason = j['reason'],
      pitch = j['pitch'],
      score = j['score'];

  String get image => 'assets/sets/$setId/cards/$id.webp';
  bool get flexible => hero == 'Tous';
  String get heroLabel => flexible ? 'Tous les héros' : hero;

  /// Couleur du héros, prise dans les couleurs par défaut des joueurs de l'app Dracailles.
  Color get heroColor => switch (hero) {
    'Levia' => ThemeColors.colorsPlayerGame[0],
    'Malice' => ThemeColors.colorsPlayerGame[11],
    'Viserai' => ThemeColors.colorsPlayerGame[27],
    _ => ThemeColors.secondary,
  };
  bool get majestic => rarity == 'mythic';

  /// Nom sans la couleur entre parenthèses, la couleur est affichée à part.
  String get title => name.replaceAll(RegExp(r' \((red|yellow|blue)\)$'), '');
  Tier get tier => Tier.of(score);
}

/// Tier S/A/B/C/D, le même vocabulaire que les tier lists.
enum Tier {
  s('S', 88, FantasyPalette.gold),
  a('A', 76, Color(0xFF2E9D63)),
  b('B', 64, Color(0xFF2F7FB0)),
  c('C', 52, Color(0xFF7C7F87)),
  d('D', 0, Color(0xFFB4413C));

  final String label;
  final int min;
  final Color color;
  const Tier(this.label, this.min, this.color);
  static Tier of(int score) => Tier.values.firstWhere((t) => score >= t.min);
}

const pitchColor = {
  1: Color(0xFFD93A3A),
  2: Color(0xFFE8B923),
  3: Color(0xFF2F80C0),
};
const pitchName = {1: 'rouge', 2: 'jaune', 3: 'bleue'};

class PackCard {
  final CardInfo card;
  final bool foil;
  PackCard(this.card, this.foil);
}

class Layout {
  final String name;
  final int weight;
  final List<(int, String)> slots;
  Layout(this.name, this.weight, this.slots);
}

class SetData {
  final SetInfo info;
  final Map<String, CardInfo> cards;
  final List<Layout> layouts;
  final Map<String, List<(int, String)>> sheets;
  SetData(this.info, this.cards, this.layouts, this.sheets);

  static Future<SetData> load(SetInfo info) async {
    final j = jsonDecode(
      await rootBundle.loadString('assets/sets/${info.id}/data.json'),
    );
    final cards = {
      for (final c in j['cards'])
        c['name'] as String: CardInfo.fromJson(c, info.id),
    };
    final layouts = [
      for (final l in j['layouts'])
        Layout(l['name'], l['w'], [
          for (final s in l['slots']) (s[0] as int, s[1] as String),
        ]),
    ];
    final sheets = {
      for (final e in (j['sheets'] as Map<String, dynamic>).entries)
        e.key: [for (final s in e.value) (s[0] as int, s[1] as String)],
    };
    return SetData(info, cards, layouts, sheets);
  }

  /// Tire un booster selon la répartition du fichier Draftmancer :
  /// un layout pondéré, puis chaque slot pioche dans sa feuille (pondérée par le nombre d'exemplaires), sans doublon.
  List<PackCard> openPack(Random rng) {
    final total = layouts.fold<int>(0, (a, l) => a + l.weight);
    var r = rng.nextInt(total);
    final layout = layouts.firstWhere((l) => (r -= l.weight) < 0);
    final pack = <PackCard>[];
    final taken = <String>{};
    for (final (n, sheet) in layout.slots) {
      for (var i = 0; i < n; i++) {
        final pool = sheets[sheet]!
            .where((e) => !taken.contains(e.$2))
            .toList();
        final sum = pool.fold<int>(0, (a, e) => a + e.$1);
        var x = rng.nextInt(sum);
        final pick = pool.firstWhere((e) => (x -= e.$1) < 0).$2;
        taken.add(pick);
        pack.add(PackCard(cards[pick]!, sheet.startsWith('RF')));
      }
    }
    return pack;
  }
}

// ---------------------------------------------------------------------------
// Verdict
// ---------------------------------------------------------------------------

enum Grade {
  best('Meilleur choix', Icons.workspace_premium, Color(0xFF2E9D63)),
  good('Bon choix', Icons.check_circle, Color(0xFF2F7FB0)),
  ok('Défendable', Icons.info, Color(0xFFD58A1E)),
  miss('Erreur', Icons.cancel, Color(0xFFC7433D));

  final String label;
  final IconData icon;
  final Color color;
  const Grade(this.label, this.icon, this.color);
  bool get counts => this == best || this == good;
}

class Verdict {
  final Grade grade;
  final CardInfo pick, best;
  final int rank, size;
  final List<String> tips;
  Verdict(this.grade, this.pick, this.best, this.rank, this.size, this.tips);
}

Verdict judge(CardInfo pick, List<CardInfo> pack) {
  final ranked = [...pack]..sort((a, b) => b.score.compareTo(a.score));
  final best = ranked.first;
  final rank = ranked.indexWhere((c) => c.name == pick.name) + 1;
  final gap = best.score - pick.score;
  final Grade grade;
  if (gap == 0) {
    grade = Grade.best;
  } else if (pick.tier == best.tier) {
    grade = Grade.good;
  } else if (gap <= 8) {
    grade = Grade.ok;
  } else {
    grade = Grade.miss;
  }

  final tips = <String>[];
  if (grade != Grade.best) {
    if (!pick.flexible && best.flexible) {
      tips.add(
        'En P1P1, une carte Shadow ou générique garde les 3 héros ouverts. '
        'Une carte de classe ne vaut le coup que si elle est nettement plus forte.',
      );
    } else if (pick.flexible && !best.flexible && grade == Grade.miss) {
      tips.add(
        'Rester ouvert a de la valeur, mais ${best.title} est assez forte pour t\'engager sur ${best.hero} dès maintenant.',
      );
    }
    if (pick.name.contains('Repentance')) {
      tips.add(
        'Les Repentance passent en grand nombre : on n\'en veut qu\'un, vers les picks 7 à 9 du pack 1.',
      );
    } else if (pick.name == 'Dark Arcanite Gloves') {
      tips.add(
        'Les Gloves remplacent les bras gratuits de ton héros : elles tournent jusqu\'au dernier pick.',
      );
    } else if (pick.pitch == 3 && best.pitch != 3 && grade == Grade.miss) {
      tips.add(
        'Les bonnes bleues à 3 de bloc se trouvent après les 4 à 6 premiers picks : pas besoin de les prendre maintenant.',
      );
    }
    if (best.majestic && !pick.majestic && grade == Grade.miss) {
      tips.add(
        'Une majestique de ce niveau ne revient jamais : prends-la quand elle est dans ton pack.',
      );
    }
  }
  return Verdict(grade, pick, best, rank, pack.length, tips);
}

// ---------------------------------------------------------------------------
// Thème
// ---------------------------------------------------------------------------

class P1P1App extends StatelessWidget {
  const P1P1App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'P1P1 Dracailles',
    debugShowCheckedModeBanner: false,
    theme: Themes.draft(),
    home: const PickScreen(),
  );
}

// ---------------------------------------------------------------------------
// Écran principal
// ---------------------------------------------------------------------------

class PickScreen extends StatefulWidget {
  const PickScreen({super.key});
  @override
  State<PickScreen> createState() => _PickScreenState();
}

class _PickScreenState extends State<PickScreen> {
  final _rng = Random();
  final _scroll = ScrollController();
  static const _prefSet = 'set';
  List<SetInfo> _sets = [];
  SetData? _data;
  List<PackCard> _pack = [];
  Verdict? _verdict;
  int _done = 0, _good = 0, _streak = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final sets = await SetInfo.loadAll();
    String? saved;
    try {
      saved = (await SharedPreferences.getInstance()).getString(_prefSet);
    } catch (_) {}
    _sets = sets;
    await _loadSet(
      sets.firstWhere((s) => s.id == saved, orElse: () => sets.first),
    );
  }

  /// Charge un set et repart de zéro : nouveau pack, compteur remis à 0.
  Future<void> _loadSet(SetInfo info) async {
    final d = await SetData.load(info);
    if (!mounted) return;
    setState(() {
      _data = d;
      _pack = d.openPack(_rng);
      _verdict = null;
      _done = _good = _streak = 0;
    });
    try {
      (await SharedPreferences.getInstance()).setString(_prefSet, info.id);
    } catch (_) {}
  }

  Future<void> _chooseSet() async {
    final picked = await showModalBottomSheet<SetInfo>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _SetSheet(sets: _sets, current: _data!.info),
    );
    if (picked != null && picked.id != _data!.info.id) _loadSet(picked);
  }

  void _nextPack() {
    setState(() {
      _pack = _data!.openPack(_rng);
      _verdict = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _take(CardInfo c) {
    final v = judge(c, _pack.map((p) => p.card).toList());
    setState(() {
      _verdict = v;
      _done++;
      if (v.grade.counts) {
        _good++;
        _streak++;
      } else {
        _streak = 0;
      }
    });
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _inspect(PackCard p) async {
    final take = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) =>
          _CardSheet(card: p.card, foil: p.foil, canTake: _verdict == null),
    );
    if (take == true) _take(p.card);
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final v = _verdict;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset('assets/logo_mark.png', width: 40, height: 40),
            const SizedBox(width: 10),
            Flexible(
              child: InkWell(
                onTap: _chooseSet,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PREMIER PICK · ${_data!.info.code}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.1,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _data!.info.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: fantasyDisplay(fontSize: 15),
                            ),
                          ),
                          Icon(
                            Icons.expand_more,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          _ScorePill(done: _done, good: _good, streak: _streak),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                if (v != null)
                  SliverToBoxAdapter(
                    child: _Readable(
                      child: _VerdictView(verdict: v, onZoom: _inspectCard),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      v == null
                          ? 'Touche une carte pour la lire, puis prends-la.'
                          : 'Le pack',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                _PackGrid(pack: _pack, verdict: v, onTap: _inspect),
                if (v != null)
                  SliverToBoxAdapter(
                    child: _Readable(
                      child: _Ranking(
                        pack: _pack.map((p) => p.card).toList(),
                        verdict: v,
                        note: _data!.info.tierNote,
                        onZoom: _inspectCard,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 28, bottom: 88),
                    child: _Credits(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: v == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: _nextPack,
                  icon: const Icon(Icons.style),
                  label: const Text('Pack suivant'),
                ),
              ),
            ),
    );
  }

  void _inspectCard(CardInfo c) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _CardSheet(card: c, foil: false, canTake: false),
  );
}

// ---------------------------------------------------------------------------
// Composants
// ---------------------------------------------------------------------------

class _ScorePill extends StatelessWidget {
  final int done, good, streak;
  const _ScorePill({
    required this.done,
    required this.good,
    required this.streak,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    if (done == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$good/$done',
            style: t.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (MediaQuery.sizeOf(context).width >= 420) ...[
            const SizedBox(width: 4),
            Text('bons picks', style: t.labelSmall),
          ] else ...[
            const SizedBox(width: 3),
            Icon(Icons.check, size: 15, color: Grade.best.color),
          ],
          if (streak >= 2) ...[
            const SizedBox(width: 8),
            Icon(Icons.local_fire_department, size: 16, color: Tier.s.color),
            Text(
              '$streak',
              style: t.labelLarge?.copyWith(
                color: Tier.s.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TierBadge extends StatelessWidget {
  final Tier tier;
  final double size;
  const TierBadge(this.tier, {super.key, this.size = 26});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: tier.color,
      borderRadius: BorderRadius.circular(size * 0.28),
    ),
    child: Text(
      tier.label,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: size * 0.55,
        height: 1,
      ),
    ),
  );
}

class _MetaChip extends StatelessWidget {
  final String text;
  final Color? dot;
  const _MetaChip(this.text, {this.dot});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(text, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

/// Fiche plein écran d'une carte : image lisible, tier masqué tant qu'on n'a pas pické.
class _CardSheet extends StatelessWidget {
  final CardInfo card;
  final bool foil, canTake;
  const _CardSheet({
    required this.card,
    required this.foil,
    required this.canTake,
  });
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final h = MediaQuery.of(context).size.height;
    final button = canTake
        ? FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.back_hand),
            label: const Text('Prendre cette carte'),
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Fermer'),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: h * 0.52),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(card.image, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  card.title,
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (card.pitch > 0)
                      _MetaChip(
                        pitchName[card.pitch]!,
                        dot: pitchColor[card.pitch],
                      ),
                    _MetaChip(card.heroLabel, dot: card.heroColor),
                    if (card.majestic) const _MetaChip('Majestique'),
                    if (foil) const _MetaChip('Foil'),
                  ],
                ),
                if (!canTake) ...[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TierBadge(card.tier),
                      const SizedBox(width: 10),
                      Expanded(child: Text(card.reason, style: t.bodyMedium)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: button,
          ),
        ),
      ],
    );
  }
}

class _PackGrid extends StatelessWidget {
  final List<PackCard> pack;
  final Verdict? verdict;
  final void Function(PackCard) onTap;
  const _PackGrid({
    required this.pack,
    required this.verdict,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverLayoutBuilder(
      builder: (context, c) {
        final w = c.crossAxisExtent;
        // Mobile : 3-4 colonnes. Ordinateur : des cartes d'environ 200 px de large, lisibles sans zoom.
        final cols = w < 420
            ? 3
            : (w < 640 ? 4 : (w / 200).floor().clamp(5, 7));
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              childAspectRatio: 600 / 838,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: pack.length,
            itemBuilder: (_, i) {
              final p = pack[i];
              final v = verdict;
              final isPick = v?.pick.name == p.card.name;
              final isBest = v != null && p.card.score == v.best.score;
              final ring = isPick
                  ? cs.primary
                  : (isBest ? Grade.best.color : null);
              return Semantics(
                button: true,
                label: p.card.title,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onTap(p),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: v != null && !isPick && !isBest ? 0.55 : 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: ring == null
                                ? null
                                : Border.all(color: ring, width: 3),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(ring == null ? 0 : 2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.asset(
                                p.card.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        if (p.foil)
                          const Positioned(
                            top: 5,
                            left: 5,
                            child: _Flag('Foil', Color(0xFF7B4BC4)),
                          ),
                        if (v != null)
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: TierBadge(p.card.tier, size: 24),
                          ),
                        if (isPick)
                          Positioned(
                            top: 5,
                            right: 5,
                            child: _Flag('Toi', cs.primary),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Flag extends StatelessWidget {
  final String text;
  final Color color;
  const _Flag(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _VerdictView extends StatelessWidget {
  final Verdict verdict;
  final void Function(CardInfo) onZoom;
  const _VerdictView({required this.verdict, required this.onZoom});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final v = verdict;
    final g = v.grade;
    final sub = g == Grade.best
        ? 'C\'est la meilleure carte du pack.'
        : 'Ta carte est ${v.rank}e sur ${v.size}. La meilleure était ${v.best.title}.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border(left: BorderSide(color: g.color, width: 5)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(g.icon, color: g.color, size: 28),
                const SizedBox(width: 10),
                Text(
                  g.label,
                  style: fantasyDisplay(fontSize: 24, color: g.color),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            _Compare(label: 'Ton pick', card: v.pick, onZoom: onZoom),
            if (g != Grade.best) ...[
              const SizedBox(height: 10),
              _Compare(
                label: 'Meilleur pick',
                card: v.best,
                onZoom: onZoom,
                highlight: Grade.best.color,
              ),
            ],
            if (v.tips.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final tip in v.tips)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb, size: 18, color: Tier.s.color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tip, style: t.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Compare extends StatelessWidget {
  final String label;
  final CardInfo card;
  final Color? highlight;
  final void Function(CardInfo) onZoom;
  const _Compare({
    required this.label,
    required this.card,
    required this.onZoom,
    this.highlight,
  });
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onZoom(card),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              card.image,
              width: 64,
              height: 89,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: t.labelSmall?.copyWith(
                    letterSpacing: 1.1,
                    color: highlight ?? cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    TierBadge(card.tier, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        card.title,
                        style: t.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(card.reason, style: t.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Ranking extends StatelessWidget {
  final List<CardInfo> pack;
  final Verdict verdict;
  final String note;
  final void Function(CardInfo) onZoom;
  const _Ranking({
    required this.pack,
    required this.verdict,
    required this.note,
    required this.onZoom,
  });
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ranked = [...pack]..sort((a, b) => b.score.compareTo(a.score));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ordre de pick du pack', style: fantasyDisplay(fontSize: 17)),
          const SizedBox(height: 4),
          Text(note, style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          for (final (i, c) in ranked.indexed)
            Material(
              color: c.name == verdict.pick.name
                  ? cs.primaryContainer.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onZoom(c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(
                          '${i + 1}',
                          style: t.labelLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          c.image,
                          width: 32,
                          height: 45,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      TierBadge(c.tier, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.title,
                              style: t.bodyMedium?.copyWith(
                                fontWeight: c.name == verdict.pick.name
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                if (c.pitch > 0) ...[
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: pitchColor[c.pitch],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                Text(
                                  c.heroLabel,
                                  style: t.labelSmall?.copyWith(
                                    color: c.heroColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (c.name == verdict.pick.name)
                        Text(
                          'Toi',
                          style: t.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Choix du set de draft : un set par ligne, le set courant coché.
class _SetSheet extends StatelessWidget {
  final List<SetInfo> sets;
  final SetInfo current;
  const _SetSheet({required this.sets, required this.current});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Set de draft', style: fantasyDisplay(fontSize: 18)),
          ),
          for (final s in sets)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Container(
                width: 44,
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.code,
                  style: t.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              title: Text(s.name),
              trailing: s.id == current.id
                  ? Icon(Icons.check_circle, color: cs.primary)
                  : null,
              onTap: () => Navigator.pop(context, s),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              "D'autres sets arriveront dans les prochaines versions.",
              style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const Padding(padding: EdgeInsets.only(top: 12), child: _Credits()),
        ],
      ),
    );
  }
}

/// Signature de l'app : logo Dracailles et lien DevMeUp.
class _Credits extends StatelessWidget {
  const _Credits();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/dracailles.png', width: 64, height: 64),
        const SizedBox(height: 6),
        Text(
          'Les Dracailles',
          style: fantasyDisplay(fontSize: 14, color: FantasyPalette.gold),
        ),
        const DevMeUpWidget(),
      ],
    );
  }
}

/// Garde le texte (verdict, classement) à une largeur de lecture confortable sur grand écran.
class _Readable extends StatelessWidget {
  final Widget child;
  const _Readable({required this.child});
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: child,
    ),
  );
}
