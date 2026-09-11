import 'dart:convert';
import 'identity/app_auth.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

part 'legacy_group.dart';

const apiBase = String.fromEnvironment(
  'SPLIT_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:3400',
);
const useApplicationIdentity = bool.fromEnvironment('APP_AUTH_V2');
final identity = AppAuth(product: 'split', baseUrl: apiBase);
const devToken = String.fromEnvironment('SPLIT_DEV_TOKEN');
const green = Color(0xff2bc653);
const debtRed = Color(0xffc34742);
const creditGreen = Color(0xff649767);
const splitPurple = Color(0xffaf52de);
const splitBlue = Color(0xff007aff);
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
    textTheme:
        (b == Brightness.light
                ? Typography.blackCupertino
                : Typography.whiteCupertino)
            .apply(
              bodyColor: b == Brightness.light ? Colors.black : Colors.white,
              displayColor: b == Brightness.light ? Colors.black : Colors.white,
            ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: green,
      brightness: b,
    ).copyWith(onSurface: b == Brightness.light ? Colors.black : Colors.white),
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
      final token = useApplicationIdentity
          ? await identity.accessToken()
          : devToken;
      if (token == null || token.isEmpty) {
        throw Exception('Sign in to continue.');
      }
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
        color: legacyColors[color] ?? const Color(0xffe8e8ea),
        shape: asset == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: asset == null ? null : BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: asset != null
          ? Image.asset('assets/$asset.png', fit: BoxFit.contain)
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
              ? Colors.white
              : Colors.black,
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
        try {
          if (await identity.accessToken() != null && mounted) await enter();
        } catch (e) {
          if (mounted) message(context, e);
        }
      });
    } else if (const bool.fromEnvironment('SPLIT_OPEN_PREVIEW')) {
      WidgetsBinding.instance.addPostFrameCallback((_) => enter());
    }
  }

  Future<void> providerLogin(String provider) async {
    if (provider == 'Email') {
      final signedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (c) => AppAuthScreen(
            auth: identity,
            title: 'split paper',
            onSignedIn: () => Navigator.pop(c, true),
          ),
        ),
      );
      if (signedIn == true && mounted) await enter();
      return;
    }
    setState(() => busy = true);
    try {
      if (provider == 'Google') {
        await identity.google();
      } else {
        await identity.apple();
      }
      if (identity.session != null && mounted) await enter();
    } catch (e) {
      if (mounted) message(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
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
                    onPressed: busy
                        ? null
                        : useApplicationIdentity
                        ? () => providerLogin(provider)
                        : () => message(
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
    final groups = List<Map<String, dynamic>>.from(data['groups'])
      ..sort((a, b) => groupDate(b).compareTo(groupDate(a)));
    final totals = <String, int>{};
    for (final g in groups) {
      final me = g['my_member_id'];
      if (me == null) continue;
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
                        : '${e.value < 0 ? 'You owe' : "You're owed"}\n${money(e.value.abs(), totals.length == 1 ? '' : e.key)}',
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
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: const Text(
        'new group',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
      ],
    ),
    body: LayoutBuilder(
      builder: (c, bounds) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (bounds.maxHeight - 40).clamp(0, double.infinity),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 5,
                childAspectRatio: (MediaQuery.sizeOf(c).width - 88) / 5 / 52,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (int i = 1; i <= 20; i++)
                    InkWell(
                      onTap: () => setState(() => icon = i),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: icon == i
                              ? Border.all(
                                  color: Theme.of(c).colorScheme.onSurface,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Image.asset('assets/group$i.png'),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 35),
                  const Text(
                    'What is the group name?',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: name,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 25, color: splitPurple),
                    decoration: const InputDecoration(
                      filled: false,
                      border: UnderlineInputBorder(),
                    ),
                  ),
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
                    onPressed: busy || name.text.trim().isEmpty
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
            ],
          ),
        ),
      ),
    ),
  );
}

class ExpenseForm extends StatefulWidget {
  final Map<String, dynamic> group;
  final Map<String, dynamic>? expense;
  final String? initialPayer;
  const ExpenseForm({
    super.key,
    required this.group,
    this.expense,
    this.initialPayer,
  });
  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  late final name = TextEditingController(text: widget.expense?['name']);
  late final amount = TextEditingController(
    text: widget.expense == null ? '' : money(widget.expense!['amount'], ''),
  );
  late String? payer =
      widget.expense?['payer'] ??
      widget.initialPayer ??
      widget.group['my_member_id'];
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
  late int step = widget.expense == null ? 0 : 2;
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
      if (step == 1 && total <= 0) {
        message(context, 'Enter an amount greater than zero.');
        return;
      }
      if (step == 1 && !validSplit) {
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
    if (!validSplit || payer == null) return;
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
                                style: const TextStyle(color: splitPurple),
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
                      color: splitPurple,
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
                    onTap: () {
                      final controller = step == 0 ? name : amount;
                      controller.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: controller.text.length,
                      );
                    },
                    textInputAction: step == 0
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onSubmitted: (_) => next(),
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
                                style: const TextStyle(color: splitPurple),
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
                                  ? splitBlue.withValues(alpha: .15)
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
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          memberAvatar(
                                            m,
                                            widget.group,
                                            size: 65,
                                          ),
                                          if (selected.contains(m['id']))
                                            Positioned(
                                              right: -3,
                                              bottom: -3,
                                              child: Container(
                                                width: 25,
                                                height: 25,
                                                decoration: const BoxDecoration(
                                                  color: splitBlue,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  CupertinoIcons.check_mark,
                                                  color: Colors.white,
                                                  size: 15,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        memberName(widget.group, m['id']),
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
                                          key: ValueKey('share-${m['id']}'),
                                          controller: shares[m['id']],
                                          onTap: () {
                                            final value = shares[m['id']]!;
                                            value.selection = TextSelection(
                                              baseOffset: 0,
                                              extentOffset: value.text.length,
                                            );
                                          },
                                          enabled: selected.contains(m['id']),
                                          textAlign: TextAlign.center,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: splitPurple,
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
                const SizedBox(height: 45),
                PaymentSummary(
                  group: widget.group,
                  expense: {
                    'name': name.text.trim(),
                    'amount': total,
                    'payer': payer,
                    'shares': {
                      for (final id in selected)
                        id: parseMinor(shares[id]!.text),
                    },
                  },
                  review: true,
                  onPayerChanged: (id) => setState(() => payer = id),
                ),
                Expanded(
                  child: PaymentShares(
                    group: widget.group,
                    expense: {
                      'payer': payer,
                      'amount': total,
                      'shares': {
                        for (final id in selected)
                          id: parseMinor(shares[id]!.text),
                      },
                    },
                  ),
                ),
                action(
                  busy ? 'Saving…' : 'Confirm',
                  busy || payer == null ? null : save,
                ),
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

class GroupSettings extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupSettings({super.key, required this.group});
  @override
  State<GroupSettings> createState() => _GroupSettingsState();
}

class _GroupSettingsState extends State<GroupSettings> {
  late Map<String, dynamic> group = widget.group;
  Future<void> reload() async {
    final state = await Api().call('/state');
    if (mounted) {
      setState(
        () => group = Map<String, dynamic>.from(
          (state['groups'] as List).firstWhere((g) => g['id'] == group['id']),
        ),
      );
    }
  }

  Future<void> editIcon() async {
    final icon = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (int i = 1; i <= 20; i++)
                InkWell(
                  onTap: () => Navigator.pop(c, i),
                  child: Container(
                    decoration: BoxDecoration(
                      border: i == group['icon']
                          ? Border.all(
                              color: Theme.of(c).colorScheme.onSurface,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Image.asset('assets/group$i.png'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (icon == null) return;
    try {
      await Api().call('/groups/${group['id']}/settings', {
        'name': group['name'],
        'icon': icon,
      });
      await reload();
    } catch (e) {
      if (mounted) message(context, e);
    }
  }

  Future<void> createMember() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => NameEditor(
          title: 'new user',
          prompt: 'Throw his nickname',
          hint: "ex. 'John'",
          action: 'Create',
          save: (value) async {
            await Api().call('/groups/${group['id']}/members', {'name': value});
          },
        ),
      ),
    );
    try {
      await reload();
    } catch (e) {
      if (mounted) message(context, e);
    }
  }

  Future<void> remove() async {
    final yes = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Delete Group',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('This will delete group for all users involved'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Delete group'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
    if (yes != true) return;
    try {
      await Api().call('/groups/${group['id']}/delete', {});
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) message(context, e);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(CupertinoIcons.chevron_left),
        onPressed: () => Navigator.pop(c),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            shortDate(groupDate(group)),
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text("${group['expenses'].length} payments"),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text("${group['members'].length} users"),
        ),
        const SizedBox(height: 16),
        Center(
          child: InkWell(
            onTap: editIcon,
            child: avatar(
              group['name'],
              asset: 'group${group['icon']}',
              color: group['color'],
              size: 55,
            ),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () async {
              await Navigator.push(
                c,
                MaterialPageRoute(
                  builder: (_) => NameEditor(
                    title: 'Group name',
                    prompt: 'What is the group name?',
                    initial: group['name'],
                    save: (value) async {
                      await Api().call('/groups/${group['id']}/settings', {
                        'name': value,
                      });
                    },
                  ),
                ),
              );
              try {
                await reload();
              } catch (e) {
                if (c.mounted) message(c, e);
              }
            },
            child: Text(
              group['name'],
              style: TextStyle(
                color: Theme.of(c).colorScheme.onSurface,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _settingsCard(c, [
          ListTile(
            title: const Text('Push notifications'),
            trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
            onTap: () => showNotConnected(c, 'Push notifications'),
          ),
        ]),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => showNotConnected(c, 'Invitations'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(c).colorScheme.onSurface,
                  minimumSize: const Size(0, 42),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Invite',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(CupertinoIcons.paperplane, size: 17),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: createMember,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(c).colorScheme.onSurface,
                  minimumSize: const Size(0, 42),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(CupertinoIcons.plus, size: 17),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        if (group['role'] == 'owner')
          Center(
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: CupertinoColors.systemRed.withValues(
                  alpha: .1,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              onPressed: remove,
              child: const Text(
                'Delete group',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ),
      ],
    ),
  );
}

class NameEditor extends StatefulWidget {
  final String title, prompt, hint, initial, action;
  final Future<void> Function(String) save;
  const NameEditor({
    super.key,
    required this.title,
    required this.prompt,
    required this.save,
    this.hint = '',
    this.initial = '',
    this.action = 'Save',
  });
  @override
  State<NameEditor> createState() => _NameEditorState();
}

class _NameEditorState extends State<NameEditor> {
  late final controller = TextEditingController(text: widget.initial);
  bool busy = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: Text(
        widget.title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.prompt,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontSize: 25, color: splitPurple),
              onChanged: (_) => setState(() {}),
              onTap: () => controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              ),
              decoration: InputDecoration(
                filled: false,
                hintText: widget.hint,
                border: const UnderlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(
                    CupertinoIcons.clear_circled_solid,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    controller.clear();
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
          Padding(
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
                onPressed: busy || controller.text.trim().isEmpty
                    ? null
                    : () async {
                        setState(() => busy = true);
                        try {
                          await widget.save(controller.text.trim());
                          if (c.mounted) Navigator.pop(c);
                        } catch (e) {
                          if (c.mounted) message(c, e);
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
                child: Text(busy ? 'Saving…' : widget.action),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _settingsCard(BuildContext c, List<Widget> rows) => Container(
  decoration: BoxDecoration(
    color: Theme.of(c).colorScheme.onSurface.withValues(alpha: .055),
    borderRadius: BorderRadius.circular(15),
  ),
  child: Column(children: rows),
);
void showNotConnected(BuildContext c, String feature) => showDialog<void>(
  context: c,
  builder: (d) => AlertDialog(
    title: Text(feature),
    content: Text(
      feature == 'Invitations'
          ? 'Group invitations are not available yet. You can add a participant using Create.'
          : 'This feature is not available yet.',
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(d), child: const Text('OK')),
    ],
  ),
);

class Settings extends StatefulWidget {
  final Map profile;
  const Settings({super.key, required this.profile});
  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late String nickname = widget.profile['nickname'];
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(CupertinoIcons.chevron_left),
        onPressed: () => Navigator.pop(c),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () async {
                  await Navigator.push(
                    c,
                    MaterialPageRoute(
                      builder: (_) => NameEditor(
                        title: 'Nickname',
                        prompt: 'Your nickname',
                        initial: nickname,
                        save: (value) async {
                          await Api().call('/profile', {'nickname': value});
                          if (mounted) setState(() => nickname = value);
                        },
                      ),
                    ),
                  );
                },
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '@$nickname ✎',
                    style: const TextStyle(fontSize: 25, color: splitBlue),
                  ),
                ),
              ),
            ),
            avatar(nickname, size: 55),
          ],
        ),
        for (final section in [
          'Notifications',
          'Appearance',
          'Make it better',
        ]) ...[
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Text(
              section,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          _settingsCard(
            c,
            section == 'Notifications'
                ? [
                    ListTile(
                      title: const Text('Push notifications'),
                      trailing: const Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                      ),
                      onTap: () => showNotConnected(c, 'Push notifications'),
                    ),
                    ListTile(
                      title: const Text('Email notifications'),
                      trailing: const Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                      ),
                      onTap: () => showNotConnected(c, 'Email notifications'),
                    ),
                  ]
                : section == 'Appearance'
                ? [
                    ListTile(
                      title: const Text('Theme'),
                      trailing: const Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                      ),
                      onTap: () => showModalBottomSheet(
                        context: c,
                        builder: (d) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final mode in ThemeMode.values)
                                ListTile(
                                  title: Text(
                                    mode == ThemeMode.system
                                        ? 'System'
                                        : mode == ThemeMode.light
                                        ? 'Light'
                                        : 'Dark',
                                  ),
                                  trailing: appearance.value == mode
                                      ? const Icon(CupertinoIcons.check_mark)
                                      : null,
                                  onTap: () {
                                    appearance.value = mode;
                                    Navigator.pop(d);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]
                : [
                    ListTile(
                      title: const Text('Report a problem'),
                      trailing: const Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                      ),
                      onTap: () => showNotConnected(c, 'Report a problem'),
                    ),
                  ],
          ),
        ],
        const SizedBox(height: 20),
        _settingsCard(c, [
          ListTile(
            title: const Text('Log Out'),
            onTap: () async {
              final yes = await showDialog<bool>(
                context: c,
                builder: (d) => AlertDialog(
                  title: const Text('Log Out'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(d, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(d, true),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );
              if (yes != true) return;
              try {
                if (useApplicationIdentity) await identity.logout();
                if (c.mounted) Navigator.popUntil(c, (r) => r.isFirst);
              } catch (e) {
                if (c.mounted) message(c, e);
              }
            },
          ),
        ]),
      ],
    ),
  );
}
