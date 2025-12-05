import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manefic Realms Creator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9C27B0), // Manefic Purple
          secondary: Color(0xFF03DAC5),
          background: Color(0xFF121212),
          surface: Color(0xFF1E1E1E),
          error: Color(0xFFCF6679),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: Colors.white,
          onSurface: Colors.white,
          onError: Colors.black,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: const CardTheme(
          color: Color(0xFF1E1E1E),
          elevation: 4,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const CharacterCreatorScreen(),
      },
    );
  }
}

// --- DATA MODELS ---

enum StatType {
  STR('Fizikum', 'STR'),
  DEX('Ügyesség', 'DEX'),
  CON('Egészség', 'CON'),
  INT('Tudás', 'INT'),
  SOUL('Lélek', 'SOUL'),
  CHA('Karizma', 'CHA'),
  WIZ('Bölcsesség', 'WIZ');

  final String label;
  final String abbr;
  const StatType(this.label, this.abbr);
}

enum Race {
  HUMAN('Ember', 'A Végzet Akarata. +1 mindenre.', {}), // Handled specially in constructor or getter
  DWARF('Kristály-szemű Törp', 'Mágia Rezisztencia. +2 CON, +1 SOUL.', {StatType.CON: 2, StatType.SOUL: 1}),
  ELF('Sorvadt Tünde', 'Vér-rituálé. +2 DEX, +1 INT.', {StatType.DEX: 2, StatType.INT: 1}),
  MANEFICBORN('Manefic-Szülött', 'Instabil Erő. +2 STR, +1 CON.', {StatType.STR: 2, StatType.CON: 1});

  final String title;
  final String description;
  final Map<StatType, int> _specificBonuses;

  const Race(this.title, this.description, this._specificBonuses);

  Map<StatType, int> get bonuses {
    if (this == Race.HUMAN) {
      return {for (var stat in StatType.values) stat: 1};
    }
    return _specificBonuses;
  }
}

enum CharClass {
  MAGE('Elemi Mágus', 6),
  METAMORPH('Metamorf', 10),
  SACRIFICER('Áldozár', 8),
  SUMMONER('Idéző', 6),
  MONK('Szerzetes', 10),
  ILLUSIONIST('Illuzionista', 6),
  RANGER('Vadonjáró', 8),
  INQUISITOR('Inkvizítor', 10);

  final String title;
  final int baseHp;
  const CharClass(this.title, this.baseHp);
}

// --- SCREEN ---

class CharacterCreatorScreen extends StatefulWidget {
  const CharacterCreatorScreen({super.key});

  @override
  State<CharacterCreatorScreen> createState() => _CharacterCreatorScreenState();
}

class _CharacterCreatorScreenState extends State<CharacterCreatorScreen> {
  // --- STATE ---
  String charName = "";
  Race selectedRace = Race.HUMAN;
  CharClass selectedClass = CharClass.INQUISITOR;

  // Stats State
  final Map<StatType, int> baseStats = {
    for (var stat in StatType.values) stat: 10
  };

  // Magic System State
  final TextEditingController _spellCostController = TextEditingController(text: "1");
  String simulationLog = "Készen áll a dobásra...";
  int fatigueLevel = 0;

  @override
  void dispose() {
    _spellCostController.dispose();
    super.dispose();
  }

  // --- HELPERS ---
  int getMod(int score) => ((score - 10) / 2).floor();

  int getFinalScore(StatType stat) {
    return (baseStats[stat] ?? 10) + (selectedRace.bonuses[stat] ?? 0);
  }

  // --- OVERLOAD LOGIC ---
  void performOverloadCheck(int cost, int soulMod) {
    // 1. Calculate DC: 10 + Spell Cost
    final dc = 10 + cost;

    // 2. Roll Stability Save: d20 + Soul Mod + Proficiency (Assumed +2 at lvl1)
    final random = Random();
    final d20 = random.nextInt(20) + 1; // 1..20
    final totalSave = d20 + soulMod + 2;

    setState(() {
      if (totalSave >= dc) {
        // Success: Spell works, gain 1 fatigue
        fatigueLevel++;
        simulationLog =
            "MENTŐ SIKER! ($totalSave vs DC $dc)\nVarázslat létrejött.\n+1 Fáradtság szint.";
      } else {
        // Failure: Roll on Overload Table
        final chaosRoll = random.nextInt(20) + 1; // 1..20
        String effect;
        if (chaosRoll == 1) {
          effect = "Manefic Robbanás (HALÁL)";
        } else if (chaosRoll >= 2 && chaosRoll <= 5) {
          effect = "Testi Mutáció (Maradandó hiba)";
        } else if (chaosRoll >= 6 && chaosRoll <= 10) {
          effect = "Lélek-vérzés (Max HP csökken)";
        } else if (chaosRoll >= 11 && chaosRoll <= 15) {
          effect = "Ájulás";
        } else if (chaosRoll >= 16 && chaosRoll <= 19) {
          effect = "Őrület";
        } else {
          // chaosRoll == 20
          effect = "Tökéletes Rezonancia (Nincs negatív hatás!)";
        }

        simulationLog =
            "MENTŐ BUKÁS! ($totalSave < $dc)\nTáblázat dobás: $chaosRoll\nEredmény: $effect";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- CALCULATIONS ---
    final soulScore = getFinalScore(StatType.SOUL);
    final soulMod = getMod(soulScore);
    final maxMp = soulScore + (1 * 2); // Level 1 assumed
    final conScore = getFinalScore(StatType.CON);
    final maxHp = selectedClass.baseHp + getMod(conScore);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manefic Realms: Karakter & Mágia"),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Race Selection
            Text("Faj", style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: Race.values.map((race) {
                return ChoiceChip(
                  label: Text(race.title.length > 3 ? race.title.substring(0, 3) : race.title),
                  selected: selectedRace == race,
                  onSelected: (selected) {
                    if (selected) setState(() => selectedRace = race);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(selectedRace.description, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),

            const SizedBox(height: 24),

            // Class Selection
            Text("Hivatás", style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: CharClass.values.map((cls) {
                return ChoiceChip(
                  label: Text(cls.title.length > 4 ? cls.title.substring(0, 4) : cls.title),
                  selected: selectedClass == cls,
                  onSelected: (selected) {
                    if (selected) setState(() => selectedClass = cls);
                  },
                );
              }).toList(),
            ),

            const Divider(height: 32, color: Colors.grey),

            // Stats UI
            ...StatType.values.map((stat) {
              final value = baseStats[stat]!;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${stat.abbr}: $value",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: value > 1
                          ? () => setState(() => baseStats[stat] = value - 1)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: value < 20
                          ? () => setState(() => baseStats[stat] = value + 1)
                          : null,
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // --- CHARACTER SHEET CARD ---
            Card(
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Input (Implicit in original, making explicit here or just display)
                    // Original had: var charName by remember { mutableStateOf("") }
                    // And: Text(if (charName.isEmpty()) "Névtelen" else charName, ...)
                    // I'll add a simple TextField for name editing to be more useful, or keep it simple.
                    // Let's stick to the display logic but maybe add an edit field above or just display "Névtelen".
                    // Actually, let's make it editable via a TextField since it's a "Creator".
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Karakter Neve",
                        hintText: "Névtelen",
                        border: InputBorder.none,
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                      onChanged: (val) => setState(() => charName = val),
                    ),
                    Text(
                      "${selectedRace.title} - ${selectedClass.title}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatBadge(label: "HP", value: "$maxHp", color: const Color(0xFFB00020)),
                        _StatBadge(label: "MP", value: "$maxMp", color: theme.colorScheme.primary),
                        _StatBadge(label: "Lélek Mod", value: "+$soulMod", color: Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 32, color: Color(0xFF9C27B0)), // Primary color

            // --- OVERLOAD SIMULATOR ---
            Text(
              "Túlterhelés Szimulátor",
              style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 4),
            Text(
              "Ha nincs elég MP-d, dobj Stabilitás Mentőt.\nDC = 10 + Varázslat költsége.",
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            Card(
              color: const Color(0xFF2B1212),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.colorScheme.error, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fatigue Tracker
                    Row(
                      children: [
                        Text(
                          "Fáradtság Szint: $fatigueLevel",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onPressed: () => setState(() => fatigueLevel = 0),
                            child: const Text("Reset", style: TextStyle(fontSize: 10, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Spell Cost Input
                    TextField(
                      controller: _spellCostController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Varázslat költsége (MP)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // The "Roll" Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final cost = int.tryParse(_spellCostController.text) ?? 0;
                          performOverloadCheck(cost, soulMod);
                        },
                        child: const Text("Túlterhelés Dobás (Stabilitás Mentő)"),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Result Log
                    Text(
                      simulationLog,
                      style: const TextStyle(
                        color: Color(0xFFFFCC80),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ],
    );
  }
}
