import 'dart:convert';
import 'identity/app_auth.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const apiBase = String.fromEnvironment(
  'SPLIT_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:3400',
);
const useApplicationIdentity = bool.fromEnvironment('APP_AUTH_V2');
final identity = AppAuth(product: 'split', baseUrl: apiBase);
const devToken = String.fromEnvironment('SPLIT_DEV_TOKEN');
const green = Color(0xff2bc653);
const legacyColors = <String, Color>{
  'Cgroup11': Color(0xff8b8b8a),
  'Cgroup10': Color(0xff46c691),
  'Cgroup8': Color(0xff5fbcac),
  'Cgroup9': Color(0xff089be1),
  'Cgroup2': Color(0xff568070),
  'Cgroup3': Color(0xff986449),
  'Cgroup5': Color(0xff649767),
  'Cgroup4': Color(0xffbd7780),
  'Cgroup16': Color(0xffaa7942),
  'Cgroup1': Color(0xff829bb2),
  'Cgroup12': Color(0xff3f667e),
  'Cgroup13': Color(0xffbfbc77),
  'Cgroup15': Color(0xff009193),
  'Cgroup14': Color(0xff4b4e12),
  'Cgroup6': Color(0xffa7ac00),
  'Cgroup7': Color(0xff88a3ff),
};
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
      final token = useApplicationIdentity ? await identity.accessToken() : devToken;
      if (token == null || token.isEmpty) throw Exception('Sign in to continue.');
      request.headers.set('Authorization', 'Bearer $token');
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
    '${((n as num) / 100).toStringAsFixed(2).replaceFirst(RegExp(r"\.?0+$"), "")} $currency'
        .trim();
void message(BuildContext c, Object e) => ScaffoldMessenger.of(c).showSnackBar(
  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
);
Widget avatar(String text, {String? asset, String? color, double size = 70}) =>
    Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: legacyColors[color] ?? const Color(0xffe9e6f2),
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
    if (useApplicationIdentity) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {if (await identity.accessToken() != null && mounted) await enter();}
        catch (e) {if (mounted) message(context, e);}
      });
    } else if (const bool.fromEnvironment('SPLIT_OPEN_PREVIEW')) {
      WidgetsBinding.instance.addPostFrameCallback((_) => enter());
    }
  }

  Future<void> providerLogin(String provider) async {
    if (provider == 'Email') {
      final signedIn = await Navigator.push<bool>(context, MaterialPageRoute(builder: (c) => AppAuthScreen(auth: identity, title: 'split paper', onSignedIn: () => Navigator.pop(c, true))));
      if (signedIn == true && mounted) await enter();
      return;
    }
    setState(() => busy = true);
    try {
      if (provider == 'Google') {await identity.google();} else {await identity.apple();}
      if (identity.session != null && mounted) await enter();
    } catch (e) {if (mounted) message(context, e);}
    finally {if (mounted) setState(() => busy = false);}
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
                    onPressed: busy ? null : useApplicationIdentity ? () => providerLogin(provider) : () => message(
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
              if (!useApplicationIdentity && devToken.isNotEmpty)
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
                            color: g['color'],
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
                              onTap: () async {
                                await Navigator.push(
                                  c,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PaymentDetails(group: g, expense: e),
                                  ),
                                );
                                await refresh();
                              },
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

class PaymentDetails extends StatelessWidget {
  final Map<String, dynamic> group, expense;
  const PaymentDetails({super.key, required this.group, required this.expense});
  @override
  Widget build(BuildContext c) {
    final members = group['members'] as List;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (expense['created'] as String).split('T')[0],
          style: const TextStyle(fontSize: 15),
        ),
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
          Align(
            alignment: Alignment.centerRight,
            child: Text('@${group['name']}'),
          ),
          const SizedBox(height: 30),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                await Navigator.push(
                  c,
                  MaterialPageRoute(
                    builder: (_) => ExpenseForm(group: group, expense: expense),
                  ),
                );
                if (c.mounted) Navigator.pop(c);
              },
              child: const Text('Edit', style: TextStyle(color: Colors.red)),
            ),
          ),
          Row(
            children: [
              const Icon(CupertinoIcons.tag),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  expense['name'],
                  style: const TextStyle(fontSize: 25),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(CupertinoIcons.money_dollar),
              const SizedBox(width: 12),
              Text(
                money(expense['amount'], group['currency']),
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'by ${members.firstWhere((m) => m['id'] == expense['payer'])['name']}',
          ),
          const SizedBox(height: 20),
          Text(
            'with ${(expense['shares'] as Map).values.where((v) => v > 0).length}',
          ),
          const SizedBox(height: 12),
          for (final m in members)
            if ((expense['shares'][m['id']] ?? 0) > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  title: Text(m['name']),
                  trailing: Text(
                    money(expense['shares'][m['id']], group['currency']),
                  ),
                ),
              ),
        ],
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
    text: widget.expense == null ? '' : money(widget.expense!['amount'], ''),
  );
  late String payer =
      widget.expense?['payer'] ?? widget.group['members'][0]['id'];
  late final Map<String, TextEditingController> shares = {
    for (final m in widget.group['members'])
      m['id']: TextEditingController(
        text: widget.expense == null
            ? ''
            : money(widget.expense!['shares'][m['id']] ?? 0, ''),
      ),
  };
  late final Set<String> selected = widget.expense == null
      ? <String>{}
      : (widget.expense!['shares'] as Map).entries
            .where((e) => (e.value as num) > 0)
            .map((e) => e.key.toString())
            .toSet();
  final Set<String> manual = {};
  int step = 0;
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

  int get total => parseMinor(amount.text);
  int get assigned => shares.entries
      .where((e) => selected.contains(e.key))
      .fold(
        0,
        (n, e) => n + (e.value.text.isEmpty ? 0 : parseMinor(e.value.text)),
      );
  bool get validSplit {
    try {
      return selected.isNotEmpty && assigned == total && total > 0;
    } catch (_) {
      return false;
    }
  }

  void redistribute() {
    try {
      final fixed = {
        for (final id in manual.where(selected.contains))
          id: shares[id]!.text.isEmpty ? 0 : parseMinor(shares[id]!.text),
      };
      final result = allocateShares(total, selected.toList(), fixed);
      for (final e in shares.entries) {
        if (!manual.contains(e.key)) {
          e.value.text = selected.contains(e.key)
              ? money(result[e.key] ?? 0, '')
              : '';
        }
      }
    } catch (_) {
      /* Keep entered values visible; confirmation stays disabled. */
    }
  }

  void toggle(String id) {
    setState(() {
      if (!selected.add(id)) {
        selected.remove(id);
        shares[id]!.clear();
      }
      manual.remove(id);
      redistribute();
    });
  }

  void next() {
    try {
      if (step == 0 && name.text.trim().isEmpty) return;
      if (step == 1 && total <= 0) return;
      if (step == 1) {
        manual.clear();
        redistribute();
      }
      if (step == 2 && !validSplit) return;
      FocusScope.of(context).unfocus();
      setState(() => step++);
    } catch (e) {
      message(context, e);
    }
  }

  Widget action(String label, VoidCallback? press) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
    child: SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: press,
        child: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
  Widget heading(Widget child) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
    child: Align(
      alignment: Alignment.centerLeft,
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        child: child,
      ),
    ),
  );
  Future<void> save() async {
    if (!validSplit) return;
    setState(() => busy = true);
    try {
      await Api().call(
        '/groups/${widget.group['id']}/expenses${widget.expense == null ? '' : '/${widget.expense!['id']}'}',
        {
          'name': name.text,
          'amount': total,
          'payer': payer,
          'shares': {
            for (final id in selected) id: parseMinor(shares[id]!.text),
          },
        },
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) message(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      leadingWidth: 80,
      leading: TextButton(
        onPressed: () {
          if (step == 0) {
            Navigator.pop(c);
          } else {
            setState(() => step--);
          }
        },
        child: const Text('Back', style: TextStyle(color: Colors.grey)),
      ),
      title: Text(
        step == 3 ? 'split review' : 'split bill',
        style: const TextStyle(fontSize: 17),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
      ],
    ),
    body: SafeArea(
      child: step < 2
          ? Column(
              children: [
                const Spacer(),
                heading(
                  step == 0
                      ? const Text('What is this for?')
                      : Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'How much was\n'),
                              TextSpan(
                                text: name.text.trim(),
                                style: const TextStyle(color: Colors.purple),
                              ),
                              const TextSpan(text: '?'),
                            ],
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    key: ValueKey(step),
                    controller: step == 0 ? name : amount,
                    autofocus: true,
                    keyboardType: step == 0
                        ? TextInputType.text
                        : const TextInputType.numberWithOptions(decimal: true),
                    textAlign: step == 0 ? TextAlign.left : TextAlign.center,
                    style: TextStyle(
                      fontSize: step == 0 ? 25 : 30,
                      color: Colors.purple,
                      fontWeight: step == 0 ? FontWeight.w500 : FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      hintText: step == 0 ? "ex.'Groceries'" : '0',
                      border: step == 0
                          ? const UnderlineInputBorder()
                          : InputBorder.none,
                      suffixIcon: step == 0
                          ? IconButton(
                              onPressed: () {
                                name.clear();
                                setState(() {});
                              },
                              icon: const Icon(
                                CupertinoIcons.clear_circled_solid,
                                color: Colors.grey,
                                size: 18,
                              ),
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                action(
                  'Continue',
                  (step == 0
                          ? name.text.trim().isNotEmpty
                          : amount.text.isNotEmpty)
                      ? next
                      : null,
                ),
              ],
            )
          : step == 2
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: heading(
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Splitting '),
                              TextSpan(
                                text: amount.text,
                                style: const TextStyle(color: Colors.purple),
                              ),
                              const TextSpan(text: '\nwith'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: CupertinoSwitch(
                        value: selected.length == shares.length,
                        onChanged: (v) {
                          setState(() {
                            selected.clear();
                            manual.clear();
                            if (v) selected.addAll(shares.keys);
                            redistribute();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio:
                        (MediaQuery.sizeOf(c).width - 52) / 2 / 180,
                    children: [
                      for (final m in widget.group['members'])
                        GestureDetector(
                          onTap: () => toggle(m['id']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: selected.contains(m['id'])
                                  ? Colors.blue.withValues(alpha: .15)
                                  : Colors.white.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: .3),
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        m['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 40,
                                        ),
                                        child: TextField(
                                          controller: shares[m['id']],
                                          enabled: selected.contains(m['id']),
                                          textAlign: TextAlign.center,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.purple,
                                          ),
                                          decoration: const InputDecoration(
                                            filled: false,
                                            hintText: '0',
                                            isDense: true,
                                            contentPadding: EdgeInsets.only(
                                              top: 12,
                                              bottom: 8,
                                            ),
                                            border: UnderlineInputBorder(),
                                          ),
                                          onChanged: (_) {
                                            setState(() {
                                              manual.add(m['id']);
                                              redistribute();
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  right: 16,
                                  bottom: 25,
                                  child: Text(
                                    '.',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w600,
                                      color: manual.contains(m['id'])
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                action(
                  'Split with ${selected.isEmpty ? '' : selected.length}',
                  validSplit ? next : null,
                ),
              ],
            )
          : Column(
              children: [
                const SizedBox(height: 35),
                heading(Text(name.text)),
                Text(
                  money(total, widget.group['currency']),
                  style: const TextStyle(fontSize: 25, color: Colors.purple),
                ),
                Text('@${widget.group['name']}'),
                Text('with ${selected.length}'),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: DropdownButtonFormField<String>(
                    initialValue: payer,
                    decoration: const InputDecoration(labelText: 'by'),
                    items: [
                      for (final m in widget.group['members'])
                        DropdownMenuItem<String>(
                          value: m['id'],
                          child: Text(m['name']),
                        ),
                    ],
                    onChanged: (v) => setState(() => payer = v!),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final m in widget.group['members'])
                        if (selected.contains(m['id']))
                          ListTile(
                            title: Text(m['name']),
                            trailing: Text(
                              shares[m['id']]!.text,
                              style: const TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                action(busy ? 'Saving…' : 'Confirm', busy ? null : save),
              ],
            ),
    ),
  );
}

int parseMinor(String raw) {
  final v = raw.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+([.]\d{1,2})?$').hasMatch(v)) {
    throw const FormatException('Use up to two decimal places');
  }
  final p = v.split('.');
  return int.parse(p[0]) * 100 +
      (p.length == 1 ? 0 : int.parse(p[1].padRight(2, '0')));
}

Map<String, int> allocateShares(
  int total,
  List<String> selected,
  Map<String, int> fixed,
) {
  if (total <= 0 ||
      !fixed.keys.every(selected.contains) ||
      fixed.values.any((v) => v < 0)) {
    throw const FormatException('Invalid split');
  }
  final remaining = total - fixed.values.fold(0, (a, b) => a + b);
  final free = selected.where((id) => !fixed.containsKey(id)).toList();
  if (remaining < 0) throw const FormatException('Shares exceed total');
  final result = Map<String, int>.from(fixed);
  for (int i = 0; i < free.length; i++) {
    result[free[i]] =
        remaining ~/ free.length + (i < remaining % free.length ? 1 : 0);
  }
  return result;
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
          onTap: () async {
            try {
              if (useApplicationIdentity) await identity.logout();
              if (c.mounted) Navigator.popUntil(c, (r) => r.isFirst);
            } catch (e) {if (c.mounted) message(c, e);}
          },
        ),
      ],
    ),
  );
}
