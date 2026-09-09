import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const apiBase = String.fromEnvironment(
  'SPLIT_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:3400',
);
const devToken = String.fromEnvironment('SPLIT_DEV_TOKEN');
const green = Color(0xff2bc653);
final appearance = ValueNotifier<ThemeMode>(ThemeMode.system);
void main() => runApp(const SplitApp());

class SplitApp extends StatelessWidget {
  const SplitApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: appearance,
    builder: (c, mode, _) => MaterialApp(
      title: 'split paper',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: const Welcome(),
    ),
  );
  ThemeData theme(Brightness b) => ThemeData(
    brightness: b,
    useMaterial3: false,
    scaffoldBackgroundColor: b == Brightness.light
        ? Colors.white
        : Colors.black,
    primaryColor: green,
    colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: b),
    appBarTheme: AppBarTheme(
      backgroundColor: b == Brightness.light ? Colors.white : Colors.black,
      foregroundColor: b == Brightness.light ? Colors.black : Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: b == Brightness.light
          ? const Color(0xffdedee0)
          : const Color(0xff292929),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 44),
      ),
    ),
  );
}

class Api {
  Future<Map<String, dynamic>> call(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.openUrl(
        body == null ? 'GET' : 'POST',
        Uri.parse('$apiBase/api/v1$path'),
      );
      request.headers.set('Authorization', 'Bearer $devToken');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final value =
          jsonDecode(await response.transform(utf8.decoder).join())
              as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw Exception(value['error'] ?? 'Request failed');
      }
      return value;
    } finally {
      client.close(force: true);
    }
  }
}

String money(dynamic n, [String currency = 'RON']) =>
    '${((n as num) / 100).toStringAsFixed(2)} $currency';
void message(BuildContext c, Object e) => ScaffoldMessenger.of(c).showSnackBar(
  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
);
Widget avatar(String text, {String? asset, double size = 70}) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    color: const Color(0xffe9e6f2),
    shape: asset == null ? BoxShape.circle : BoxShape.rectangle,
    borderRadius: asset == null ? null : BorderRadius.circular(10),
  ),
  alignment: Alignment.center,
  child: asset != null
      ? Padding(
          padding: const EdgeInsets.all(3),
          child: Image.asset('assets/$asset.png', fit: BoxFit.contain),
        )
      : Text(
          text.isEmpty ? '?' : text[0].toUpperCase(),
          style: TextStyle(fontSize: size * .4, color: Colors.black),
        ),
);
Widget tile(BuildContext c, List<Widget> children, {VoidCallback? tap}) =>
    InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(c).brightness == Brightness.light
              ? const Color(0xfffafafa)
              : const Color(0xff151515),
          border: Border.all(
            color: Theme.of(c).colorScheme.onSurface,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );

class Welcome extends StatefulWidget {
  const Welcome({super.key});
  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  bool signIn = false, busy = false;
  @override
  void initState() {
    super.initState();
    if (const bool.fromEnvironment('SPLIT_OPEN_PREVIEW')) {
      WidgetsBinding.instance.addPostFrameCallback((_) => enter());
    }
  }

  Future<void> enter() async {
    setState(() => busy = true);
    try {
      final data = await Api().call('/state');
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Home(initial: data)),
        );
      }
    } catch (e) {
      if (mounted) message(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset('assets/pic1.png', height: 240, fit: BoxFit.contain),
              const Text(
                'split paper',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Split expenses with any group.',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 35),
              for (final provider in ['Apple', 'Google', 'Email'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      foregroundColor: provider == 'Apple'
                          ? Colors.white
                          : Theme.of(c).colorScheme.onSurface,
                      backgroundColor: provider == 'Apple'
                          ? Colors.black
                          : null,
                      side: BorderSide(
                        color: Theme.of(c).colorScheme.onSurface,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => message(
                      c,
                      '$provider authentication will be connected after the v0 review. Use the local preview below.',
                    ),
                    child: Row(
                      children: [
                        provider == 'Apple'
                            ? const Icon(Icons.apple)
                            : Image.asset(
                                'assets/${provider == 'Google' ? 'google' : 'email'}.png',
                                width: 25,
                                height: 25,
                              ),
                        Expanded(
                          child: Text(
                            'Sign ${signIn ? 'in' : 'up'} with $provider',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    signIn
                        ? "Don't have an account?"
                        : 'Already have an account?',
                  ),
                  TextButton(
                    onPressed: () => setState(() => signIn = !signIn),
                    child: Text(
                      signIn ? 'Sign up.' : 'Sign in.',
                      style: const TextStyle(color: green),
                    ),
                  ),
                ],
              ),
              if (devToken.isNotEmpty)
                TextButton(
                  onPressed: busy ? null : enter,
                  child: Text(busy ? 'Loading…' : 'Open local v0 preview'),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class Home extends StatefulWidget {
  final Map<String, dynamic> initial;
  const Home({super.key, required this.initial});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Map<String, dynamic> data = widget.initial;
  Future<void> refresh() async {
    try {
      final v = await Api().call('/state');
      if (mounted) setState(() => data = v);
    } catch (e) {
      if (mounted) message(context, e);
    }
  }

  Future<void> create() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroup()),
    );
    await refresh();
  }

  @override
  Widget build(BuildContext c) {
    final groups = data['groups'] as List;
    final totals = <String, int>{};
    for (final g in groups) {
      final me = g['members'][0]['id'];
      totals[g['currency']] =
          (totals[g['currency']] ?? 0) + (g['balances'][me] as int);
    }
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 67,
        backgroundColor: Theme.of(c).brightness == Brightness.light
            ? const Color(0xfff5f5f5)
            : const Color(0xff151515),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(82),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in totals.entries)
                  Text(
                    e.value == 0
                        ? 'settled'
                        : '${e.value < 0 ? 'You owe' : 'You are owed'}\n${money(e.value.abs(), e.key)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: avatar(data['profile']['nickname'], size: 35),
          onPressed: () async {
            await Navigator.push(
              c,
              MaterialPageRoute(
                builder: (_) => Settings(profile: data['profile']),
              ),
            );
            await refresh();
          },
        ),
        actions: [
          if (groups.isNotEmpty)
            IconButton(
              icon: const Icon(CupertinoIcons.plus),
              onPressed: create,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: groups.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.sizeOf(c).height * .27),
                  Center(
                    child: IconButton(
                      iconSize: 65,
                      icon: const Icon(
                        CupertinoIcons.plus_circle,
                        color: green,
                      ),
                      onPressed: create,
                    ),
                  ),
                  const Center(child: Text('Create your first group')),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          mainAxisExtent: 180,
                        ),
                    itemCount: groups.length,
                    itemBuilder: (c, i) {
                      final g = groups[i];
                      return tile(
                        c,
                        [
                          Text(
                            g['name'],
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${g['members'].length} users',
                            style: const TextStyle(fontSize: 17),
                          ),
                          Text(
                            '${g['expenses'].length} payments',
                            style: const TextStyle(fontSize: 17),
                          ),
                          const SizedBox(height: 10),
                          avatar(
                            g['name'],
                            asset: 'group${g['icon']}',
                            size: 35,
                          ),
                        ],
                        tap: () async {
                          await Navigator.push(
                            c,
                            MaterialPageRoute(
                              builder: (_) => GroupPage(group: g),
                            ),
                          );
                          await refresh();
                        },
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class CreateGroup extends StatefulWidget {
  const CreateGroup({super.key});
  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  final name = TextEditingController();
  int icon = 1;
  String currency = 'RON';
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('new group'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 20,
            separatorBuilder: (_, i) => const SizedBox(width: 10),
            itemBuilder: (c, i) => GestureDetector(
              onTap: () => setState(() => icon = i + 1),
              child: Opacity(
                opacity: icon == i + 1 ? 1 : .4,
                child: avatar('', asset: 'group${i + 1}'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 35),
        const Text('What is the group name?', style: TextStyle(fontSize: 25)),
        const SizedBox(height: 16),
        TextField(controller: name, style: const TextStyle(fontSize: 25)),
        DropdownButton<String>(
          value: currency,
          items: [
            for (final x in ['RON', 'EUR', 'USD', 'GBP'])
              DropdownMenuItem(value: x, child: Text(x)),
          ],
          onChanged: (v) => setState(() => currency = v!),
        ),
        const SizedBox(height: 25),
        ElevatedButton(
          onPressed: busy
              ? null
              : () async {
                  setState(() => busy = true);
                  try {
                    await Api().call('/groups', {
                      'name': name.text,
                      'icon': icon,
                      'currency': currency,
                    });
                    if (c.mounted) Navigator.pop(c);
                  } catch (e) {
                    if (c.mounted) message(c, e);
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}

class GroupPage extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupPage({super.key, required this.group});
  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late Map<String, dynamic> g = widget.group;
  int tab = 0;
  Future<void> refresh() async {
    try {
      final s = await Api().call('/state');
      if (mounted) {
        setState(
          () => g = (s['groups'] as List).firstWhere((x) => x['id'] == g['id']),
        );
      }
    } catch (e) {
      if (mounted) message(context, e);
    }
  }

  Future<void> spend([Map<String, dynamic>? e]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseForm(group: g, expense: e),
      ),
    );
    await refresh();
  }

  @override
  Widget build(BuildContext c) {
    final members = g['members'] as List;
    final expenses = g['expenses'] as List;
    final balances = g['balances'] as Map;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          g['name'],
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.gear),
            onPressed: () async {
              await Navigator.push(
                c,
                MaterialPageRoute(builder: (_) => GroupSettings(group: g)),
              );
              await refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Spent', style: TextStyle(fontSize: 20)),
                    Text(
                      money(
                        expenses.fold<int>(
                          0,
                          (a, e) =>
                              a + ((e['shares'][members[0]['id']] ?? 0) as int),
                        ),
                        g['currency'],
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: members.length < 2 ? null : () => spend(),
                    child: const Text('Spend', style: TextStyle(fontSize: 17)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (int i = 0; i < 2; i++)
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => tab = i),
                          child: Text(
                            i == 0 ? 'Stats' : 'Activity',
                            style: TextStyle(
                              color: tab == i
                                  ? Theme.of(c).colorScheme.onSurface
                                  : Colors.grey,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: tab == 0
                  ? GridView.count(
                      padding: const EdgeInsets.all(16),
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1,
                      children: [
                        for (final m in members)
                          tile(c, [
                            avatar(m['name'], size: 50),
                            const SizedBox(height: 8),
                            Text(
                              m['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              balances[m['id']] == 0
                                  ? 'Settled Up'
                                  : balances[m['id']] > 0
                                  ? 'is owed'
                                  : 'owes',
                              style: const TextStyle(fontSize: 15),
                            ),
                            if (balances[m['id']] != 0)
                              Text(
                                money(
                                  (balances[m['id']] as int).abs(),
                                  g['currency'],
                                ),
                                style: const TextStyle(fontSize: 20),
                              ),
                          ], tap: () => settle(m)),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (expenses.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(30),
                            child: Text(
                              'No payments yet',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        for (final e in expenses)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(
                                  color: Theme.of(c).colorScheme.onSurface,
                                ),
                              ),
                              leading: avatar(e['name'], size: 45),
                              title: Text(
                                e['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'by ${members.firstWhere((m) => m['id'] == e['payer'])['name']}',
                              ),
                              trailing: Text(money(e['amount'], g['currency'])),
                              onTap: () => spend(e),
                            ),
                          ),
                        for (final s in g['settlements'])
                          ListTile(
                            leading: const Icon(
                              CupertinoIcons.check_mark_circled,
                              color: green,
                            ),
                            title: const Text('Settled Up'),
                            trailing: Text(money(s['amount'], g['currency'])),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> settle(Map m) async {
    final balances = g['balances'] as Map;
    final amount = balances[m['id']] as int;
    if (amount >= 0) {
      message(
        context,
        'Choose a participant who owes money to record a settlement.',
      );
      return;
    }
    final creditors = (g['members'] as List)
        .where((x) => balances[x['id']] > 0)
        .toList();
    await showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Confirm paid', style: TextStyle(fontSize: 25)),
            ),
            for (final receiver in creditors)
              ListTile(
                title: Text('${m['name']} → ${receiver['name']}'),
                subtitle: Text(
                  money(
                    (-amount).clamp(0, balances[receiver['id']]),
                    g['currency'],
                  ),
                ),
                trailing: const Icon(Icons.check),
                onTap: () async {
                  try {
                    await Api().call('/groups/${g['id']}/settlements', {
                      'sender': m['id'],
                      'receiver': receiver['id'],
                      'amount': (-amount).clamp(0, balances[receiver['id']]),
                    });
                    if (c.mounted) Navigator.pop(c);
                    await refresh();
                  } catch (e) {
                    if (c.mounted) message(c, e);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class ExpenseForm extends StatefulWidget {
  final Map<String, dynamic> group;
  final Map<String, dynamic>? expense;
  const ExpenseForm({super.key, required this.group, this.expense});
  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  late final name = TextEditingController(text: widget.expense?['name']);
  late final amount = TextEditingController(
    text: widget.expense == null
        ? ''
        : ((widget.expense!['amount'] as int) / 100).toStringAsFixed(2),
  );
  late String payer =
      widget.expense?['payer'] ?? widget.group['members'][0]['id'];
  late final Map<String, TextEditingController> shares = {
    for (final m in widget.group['members'])
      m['id']: TextEditingController(
        text: widget.expense == null
            ? ''
            : ((widget.expense!['shares'][m['id']] ?? 0) / 100).toStringAsFixed(
                2,
              ),
      ),
  };
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    for (final x in shares.values) {
      x.dispose();
    }
    super.dispose();
  }

  int parse(String v) {
    if (!RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(v.trim())) {
      throw const FormatException('Use an amount with up to two decimals');
    }
    final p = v.trim().replaceAll(',', '.').split('.');
    return int.parse(p[0]) * 100 +
        (p.length == 1 ? 0 : int.parse(p[1].padRight(2, '0')));
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(widget.expense == null ? 'Spend' : 'Edit payment'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '@${widget.group['name']}',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        const Text('What did you spend on?', style: TextStyle(fontSize: 25)),
        const SizedBox(height: 12),
        TextField(
          controller: name,
          decoration: const InputDecoration(
            prefixIcon: Icon(CupertinoIcons.tag),
            hintText: 'Payment name',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixIcon: const Icon(CupertinoIcons.money_dollar),
            hintText: 'Amount (${widget.group['currency']})',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: payer,
          decoration: const InputDecoration(labelText: 'Paid by'),
          items: [
            for (final m in widget.group['members'])
              DropdownMenuItem<String>(value: m['id'], child: Text(m['name'])),
          ],
          onChanged: (v) => setState(() => payer = v!),
        ),
        const SizedBox(height: 25),
        const Text('Splitting with', style: TextStyle(fontSize: 25)),
        TextButton(
          onPressed: () {
            try {
              final n = parse(amount.text);
              int i = 0;
              for (final field in shares.values) {
                field.text =
                    ((n ~/ shares.length + (i++ < n % shares.length ? 1 : 0)) /
                            100)
                        .toStringAsFixed(2);
              }
              setState(() {});
            } catch (e) {
              message(c, e);
            }
          },
          child: const Text('Split equally'),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1,
          children: [
            for (final m in widget.group['members'])
              tile(c, [
                avatar(m['name'], size: 45),
                Text(m['name'], style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                TextField(
                  controller: shares[m['id']],
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(hintText: '0'),
                ),
              ]),
          ],
        ),
        const SizedBox(height: 25),
        ElevatedButton(
          onPressed: busy
              ? null
              : () async {
                  try {
                    final values = {
                      for (final e in shares.entries)
                        e.key: e.value.text.trim().isEmpty
                            ? 0
                            : parse(e.value.text),
                    };
                    setState(() => busy = true);
                    await Api().call(
                      '/groups/${widget.group['id']}/expenses${widget.expense == null ? '' : '/${widget.expense!['id']}'}',
                      {
                        'name': name.text,
                        'amount': parse(amount.text),
                        'payer': payer,
                        'shares': values,
                      },
                    );
                    if (c.mounted) Navigator.pop(c);
                  } catch (e) {
                    if (c.mounted) message(c, e);
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: Text(busy ? 'Saving…' : 'Confirm'),
        ),
      ],
    ),
  );
}

class GroupSettings extends StatelessWidget {
  final Map<String, dynamic> group;
  const GroupSettings({super.key, required this.group});
  Future<void> edit(
    BuildContext c,
    String title,
    String path,
    String key,
  ) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: c,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null) {
      try {
        await Api().call(path, {key: value});
        if (c.mounted) message(c, 'Saved');
      } catch (e) {
        if (c.mounted) message(c, e);
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Group settings')),
    body: ListView(
      children: [
        const SizedBox(height: 20),
        Center(child: avatar(group['name'], asset: 'group${group['icon']}')),
        ListTile(
          title: Text(group['name']),
          trailing: const Icon(CupertinoIcons.pencil),
          onTap: () =>
              edit(c, 'Group name', '/groups/${group['id']}/settings', 'name'),
        ),
        ListTile(
          title: const Text('Create user'),
          subtitle: const Text('Add a participant without an account'),
          trailing: const Icon(CupertinoIcons.person_add),
          onTap: () =>
              edit(c, 'Name', '/groups/${group['id']}/members', 'name'),
        ),
        ListTile(
          title: const Text('Share With Friends'),
          onTap: () => message(
            c,
            'Invitations will be connected with account authentication after the v0 review.',
          ),
        ),
      ],
    ),
  );
}

class Settings extends StatelessWidget {
  final Map profile;
  const Settings({super.key, required this.profile});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(child: avatar(profile['nickname'], size: 100)),
        ListTile(
          title: Text(
            '@${profile['nickname']}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25),
          ),
          trailing: const Icon(CupertinoIcons.pencil),
          onTap: () => GroupSettings(
            group: const {},
          ).edit(c, 'Nickname', '/profile', 'nickname'),
        ),
        const SizedBox(height: 30),
        ListTile(
          title: const Text('Notifications'),
          trailing: const Icon(CupertinoIcons.bell),
          onTap: () =>
              message(c, 'Push notifications are not connected in local v0.'),
        ),
        ListTile(
          title: const Text('Appearance'),
          trailing: const Icon(CupertinoIcons.moon),
          onTap: () {
            appearance.value = Theme.of(c).brightness == Brightness.dark
                ? ThemeMode.light
                : ThemeMode.dark;
          },
        ),
        ListTile(
          title: const Text('Make it better'),
          onTap: () => showAboutDialog(
            context: c,
            applicationName: 'split paper',
            applicationVersion: 'Flutter v0',
          ),
        ),
        ListTile(
          title: const Text('Log out', style: TextStyle(color: Colors.red)),
          onTap: () => Navigator.popUntil(c, (r) => r.isFirst),
        ),
      ],
    ),
  );
}
