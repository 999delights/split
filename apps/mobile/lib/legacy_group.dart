part of 'main.dart';

// Layout and terminology follow the original Swift GroupView, StatsView,
// ActivityView2, CreatedUserView and PaymentView. Money remains integer cents.
String legacyAmount(dynamic value) => money(value, '');
String memberName(Map group, dynamic id) {
  if (id == group['my_member_id']) return 'Me';
  for (final member in group['members'] as List) {
    if (member['id'] == id) return member['name'] as String;
  }
  return 'Participant';
}

Widget memberAvatar(
  Map member,
  Map group, {
  double size = 55,
  bool neutral = false,
}) => Builder(
  builder: (context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xff1c1c1e)
          : const Color(0xffe8e8ea),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(
      member['id'] == group['my_member_id'] && member['name'] == 'Me'
          ? ''
          : (member['name'] as String).isEmpty
          ? ''
          : (member['name'] as String).characters.first.toUpperCase(),
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: neutral || member['id'] == group['my_member_id']
            ? Theme.of(context).colorScheme.onSurface
            : splitPurple,
      ),
    ),
  ),
);
Map memberById(Map group, dynamic id) =>
    (group['members'] as List).cast<Map>().firstWhere(
      (m) => m['id'] == id,
      orElse: () => {'id': id, 'name': 'Participant'},
    );
int personalSpent(Map group, String id) =>
    (group['expenses'] as List).fold<int>(
      0,
      (sum, expense) => sum + ((expense['shares'][id] ?? 0) as num).toInt(),
    );

/// debtor -> creditor, after cancelling reciprocal debts and transferring
/// chains (the Swift smartTransferDebts behavior). No sub-unit debt is hidden.
Map<String, Map<String, int>> groupDebts(Map group) {
  final ids = (group['members'] as List).map((m) => m['id'] as String).toList()
    ..sort();
  final debts = {
    for (final a in ids) a: {for (final b in ids) b: 0},
  };
  for (final expense in group['expenses'] as List) {
    for (final share in (expense['shares'] as Map).entries) {
      if (share.key != expense['payer']) {
        debts[share.key]![expense['payer']] =
            debts[share.key]![expense['payer']]! + (share.value as num).toInt();
      }
    }
  }
  for (final payment in group['settlements'] as List? ?? []) {
    // A repayment is the reverse of the original obligation.
    debts[payment['receiver']]![payment['sender']] =
        debts[payment['receiver']]![payment['sender']]! +
        (payment['amount'] as num).toInt();
  }
  void cancel() {
    for (final a in ids) {
      for (final b in ids.where((b) => b != a)) {
        final x = debts[a]![b]!;
        final y = debts[b]![a]!;
        final common = x < y ? x : y;
        debts[a]![b] = x - common;
        debts[b]![a] = y - common;
      }
    }
  }

  cancel();
  // Each transfer strictly decreases the sum of debt edges. Stop when no
  // participant both receives and owes, retaining the original pairings where possible.
  bool changed;
  do {
    changed = false;
    for (final via in ids) {
      for (final from in ids.where((id) => id != via)) {
        for (final to in ids.where((id) => id != via && id != from)) {
          final incoming = debts[from]![via]!;
          final outgoing = debts[via]![to]!;
          final transfer = incoming < outgoing ? incoming : outgoing;
          if (transfer == 0) continue;
          debts[from]![via] = incoming - transfer;
          debts[via]![to] = outgoing - transfer;
          debts[from]![to] = debts[from]![to]! + transfer;
          changed = true;
        }
      }
    }
    cancel();
  } while (changed);
  return debts;
}

class GroupPage extends StatefulWidget {
  final Map<String, dynamic> group;
  final String? perspectiveId;
  const GroupPage({super.key, required this.group, this.perspectiveId});
  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late Map<String, dynamic> g = widget.group;
  final pages = PageController();
  int tab = 0;
  String? get me => widget.perspectiveId ?? g['my_member_id'];
  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    try {
      final state = await Api().call('/state');
      final matches = (state['groups'] as List).where(
        (x) => x['id'] == g['id'],
      );
      if (!mounted) return;
      if (matches.isEmpty) {
        Navigator.pop(context);
        return;
      }
      setState(() => g = Map<String, dynamic>.from(matches.first));
    } catch (e) {
      if (mounted) message(context, e);
    }
  }

  Future<void> spend() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ExpenseForm(group: g, initialPayer: me),
      ),
    );
    await refresh();
  }

  Future<void> openMember(Map member) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => FractionallySizedBox(
        heightFactor: .985,
        child: GroupPage(group: g, perspectiveId: member['id']),
      ),
    );
    await refresh();
  }

  Future<void> payment(Map expense) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => FractionallySizedBox(
        heightFactor: .985,
        child: PaymentDetails(
          group: g,
          expense: Map<String, dynamic>.from(expense),
        ),
      ),
    );
    await refresh();
  }

  Future<void> settleWith(Map member, int net) async {
    if (net == 0 || me == null) return;
    final sender = net > 0 ? member['id'] : me;
    final receiver = net > 0 ? me : member['id'];
    final confirmed = await showModalBottomSheet<bool>(
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
                  'Payment has been made',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${memberName(g, sender)} → ${memberName(g, receiver)}',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
              Text(
                legacyAmount(net.abs()),
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: net < 0 ? debtRed : creditGreen,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Confirm'),
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
    if (confirmed != true) return;
    try {
      await Api().call('/groups/${g['id']}/settlements', {
        'sender': sender,
        'receiver': receiver,
        'amount': net.abs(),
      });
      await refresh();
    } catch (e) {
      if (mounted) message(context, e);
    }
  }

  @override
  Widget build(BuildContext c) {
    final members = g['members'] as List;
    final debt = groupDebts(g);
    final person = me;
    final balance = (g['balances'][person] as num?)?.toInt() ?? 0;
    final others = members.where((m) => m['id'] != person).toList();
    final primary = Theme.of(c).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: widget.perspectiveId == null ? 66 : 60,
        leadingWidth: 58,
        centerTitle: false,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        leading: widget.perspectiveId == null
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(CupertinoIcons.chevron_left, size: 28),
                onPressed: () => Navigator.pop(c),
              )
            : null,
        title: widget.perspectiveId == null
            ? Text(
                g['name'],
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: memberName(g, person),
                        style: const TextStyle(color: splitPurple),
                      ),
                      const TextSpan(text: "'s stats"),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        actions: [
          if (widget.perspectiveId != null)
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text('Cancel', style: TextStyle(color: primary)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Group settings',
                iconSize: 35,
                icon: avatar(
                  g['name'],
                  asset: 'group${g['icon']}',
                  color: g['color'],
                  size: 35,
                ),
                onPressed: () async {
                  await Navigator.push(
                    c,
                    MaterialPageRoute(builder: (_) => GroupSettings(group: g)),
                  );
                  await refresh();
                },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (person != null) ...[
                  _summaryLine(
                    balance == 0
                        ? 'settled'
                        : balance < 0
                        ? 'You owe'
                        : "You're owed",
                    balance == 0 ? null : legacyAmount(balance.abs()),
                    balance < 0 ? debtRed : creditGreen,
                    key: const ValueKey('personal-balance'),
                  ),
                  const SizedBox(height: 9),
                  _summaryLine(
                    'Spent',
                    legacyAmount(personalSpent(g, person)),
                    debtRed,
                    key: const ValueKey('personal-spent'),
                  ),
                ] else
                  const Text(
                    'Your participant has not been linked to this group.',
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: members.length < 2 || person == null
                        ? null
                        : spend,
                    child: const Text(
                      'Spend',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.perspectiveId == null) ...[
            const SizedBox(height: 26),
            Row(
              children: [
                for (int i = 0; i < 2; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => pages.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 230),
                        curve: Curves.easeInOut,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 51,
                            child: Center(
                              child: Text(
                                i == 0 ? 'stats' : 'activity',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: tab == i ? primary : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 1,
                            color: tab == i ? primary : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ] else
            const SizedBox(height: 16),
          Expanded(
            child: PageView(
              controller: pages,
              onPageChanged: (i) => setState(() => tab = i),
              physics: widget.perspectiveId == null
                  ? null
                  : const NeverScrollableScrollPhysics(),
              children: [
                RefreshIndicator(
                  onRefresh: refresh,
                  child: others.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 70),
                            Center(child: Text("You're the only one here")),
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: others.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                mainAxisExtent: 180,
                              ),
                          itemBuilder: (c, i) {
                            final m = others[i];
                            final net = person == null
                                ? 0
                                : (debt[m['id']]?[person] ?? 0) -
                                      (debt[person]?[m['id']] ?? 0);
                            return InkWell(
                              key: ValueKey('stats-${m['id']}'),
                              borderRadius: BorderRadius.circular(15),
                              onTap: widget.perspectiveId == null
                                  ? () => openMember(m)
                                  : () => settleWith(m, net),
                              onLongPress: () => settleWith(m, net),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: primary.withValues(alpha: .3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 14),
                                    memberAvatar(m, g),
                                    const SizedBox(height: 8),
                                    Text(
                                      memberName(g, m['id']),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      net == 0
                                          ? 'we good'
                                          : net > 0
                                          ? 'owes you'
                                          : 'is owed',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      net == 0
                                          ? 'Settled Up'
                                          : legacyAmount(net.abs()),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: net == 0
                                            ? primary
                                            : net > 0
                                            ? creditGreen.withValues(alpha: .75)
                                            : Colors.red.withValues(alpha: .5),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (widget.perspectiveId == null)
                  RefreshIndicator(
                    onRefresh: refresh,
                    child: ActivityList(group: g, onExpense: payment),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _summaryLine(String label, String? amount, Color color, {Key? key}) =>
    Row(
      key: key,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'CupertinoSystemDisplay',
          ),
        ),
        if (amount != null) ...[
          const SizedBox(width: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'CupertinoSystemDisplay',
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ],
    );

class ActivityList extends StatelessWidget {
  final Map group;
  final void Function(Map) onExpense;
  const ActivityList({super.key, required this.group, required this.onExpense});
  @override
  Widget build(BuildContext c) {
    final me = group['my_member_id'];
    final entries =
        [
          for (final e in group['expenses'] as List)
            if (e['payer'] == me || (e['shares'][me] ?? 0) > 0)
              {...e, '_expense': true},
          for (final s in group['settlements'] as List? ?? [])
            if (s['sender'] == me || s['receiver'] == me)
              {...s, '_expense': false},
        ]..sort(
          (a, b) => (b['created'] as String).compareTo(a['created'] as String),
        );
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      children: [
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Text('no payments yet', textAlign: TextAlign.center),
          ),
        for (final e in entries)
          if (e['_expense'] == true)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
              child: InkWell(
                onTap: () => onExpense(e),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 80),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: e['payer'] == me
                          ? splitBlue
                          : Theme.of(c).colorScheme.onSurface,
                    ),
                  ),
                  child: Row(
                    children: [
                      memberAvatar(
                        memberById(group, e['payer']),
                        group,
                        size: 45,
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    e['name'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      height: 1,
                                      fontFamily: 'CupertinoSystemDisplay',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  legacyAmount(e['amount']),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (e['payer'] == me) ...[
                              _activityMoney(
                                'You get back',
                                (e['amount'] as num).toInt() -
                                    ((e['shares'][me] ?? 0) as num).toInt(),
                                creditGreen.withValues(alpha: .75),
                              ),
                              const SizedBox(height: 8),
                              _activityMoney(
                                'Spent',
                                e['shares'][me] ?? 0,
                                debtRed,
                              ),
                            ] else
                              _activityMoney(
                                'You owe',
                                e['shares'][me] ?? 0,
                                debtRed,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ListTile(
              leading: const Icon(
                CupertinoIcons.check_mark_circled,
                color: creditGreen,
              ),
              title: const Text('Settled Up'),
              subtitle: Text(
                '${memberName(group, e['sender'])} → ${memberName(group, e['receiver'])}',
              ),
              trailing: Text(legacyAmount(e['amount'])),
            ),
      ],
    );
  }
}

Widget _activityMoney(String label, dynamic amount, Color color) => Text.rich(
  TextSpan(
    children: [
      TextSpan(text: '$label '),
      TextSpan(
        text: legacyAmount(amount),
        style: const TextStyle(fontSize: 15),
      ),
    ],
  ),
  style: TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: color,
    height: 1,
  ),
);

class BanknoteIcon extends StatelessWidget {
  const BanknoteIcon({super.key});
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: 22,
      height: 15,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(border: Border.all(color: color, width: 1.8)),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: color)),
        alignment: Alignment.center,
        child: Container(
          width: 5,
          height: 8,
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class PaymentSummary extends StatelessWidget {
  final Map group, expense;
  final bool review;
  final ValueChanged<String>? onPayerChanged;
  const PaymentSummary({
    super.key,
    required this.group,
    required this.expense,
    this.review = false,
    this.onPayerChanged,
  });
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: review
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Transform.flip(flipX: true, child: const Icon(CupertinoIcons.tag)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                expense['name'],
                style: TextStyle(
                  fontSize: review ? 20 : 25,
                  fontFamily: 'CupertinoSystemDisplay',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: review ? 8 : 18),
        Row(
          mainAxisAlignment: review
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            const BanknoteIcon(),
            const SizedBox(width: 8),
            Text(
              legacyAmount(expense['amount']),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        SizedBox(height: review ? 12 : 20),
        Row(
          children: [
            if (review)
              Expanded(
                child: Text(
                  '@${group['name']}',
                  style: const TextStyle(fontSize: 20),
                ),
              )
            else
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'by ',
                        style: TextStyle(color: splitBlue),
                      ),
                      TextSpan(
                        text: expense['payer'] == group['my_member_id']
                            ? 'me'
                            : memberName(group, expense['payer']),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              'with ${(expense['shares'] as Map).length}',
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
        if (onPayerChanged != null)
          Align(
            alignment: Alignment.centerLeft,
            child: PopupMenuButton<String>(
              tooltip: 'Who paid?',
              onSelected: onPayerChanged,
              itemBuilder: (_) => [
                for (final m in group['members'] as List)
                  PopupMenuItem(
                    value: m['id'],
                    child: Text(memberName(group, m['id'])),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'by ${memberName(group, expense['payer'])} ⌄',
                  style: const TextStyle(
                    color: splitBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(height: review ? 16 : 28),
      ],
    ),
  );
}

class PaymentShares extends StatelessWidget {
  final Map group, expense;
  const PaymentShares({super.key, required this.group, required this.expense});
  @override
  Widget build(BuildContext c) {
    final me = group['my_member_id'];
    final ownShare = ((expense['shares'][me] ?? 0) as num).toInt();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        for (final m in group['members'] as List)
          if ((expense['shares'] as Map).containsKey(m['id']))
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Theme.of(c).colorScheme.onSurface.withValues(alpha: .03),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  memberAvatar(m, group, size: 30, neutral: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      memberName(group, m['id']),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: m['id'] == expense['payer'] ? splitBlue : null,
                      ),
                    ),
                  ),
                  Text(
                    legacyAmount(expense['shares'][m['id']]),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: m['id'] == me
                          ? CupertinoColors.systemRed.withValues(alpha: .5)
                          : expense['payer'] == me
                          ? CupertinoColors.systemGreen
                          : null,
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 20),
        if (expense['payer'] == me)
          Row(
            children: [
              const Expanded(child: Divider()),
              const SizedBox(width: 12),
              Text(
                legacyAmount(
                  expense['payer'] == me
                      ? (expense['amount'] as num).toInt() - ownShare
                      : 0,
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemGreen,
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
      ],
    );
  }
}

class PaymentDetails extends StatelessWidget {
  final Map<String, dynamic> group, expense;
  const PaymentDetails({super.key, required this.group, required this.expense});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: Text(
        shortDate(expense['created']),
        style: const TextStyle(fontSize: 15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: Text(
            'Cancel',
            style: TextStyle(color: Theme.of(c).colorScheme.onSurface),
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '@${group['name']}',
              style: const TextStyle(fontSize: 15, height: 1.2),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: CupertinoColors.systemRed,
                backgroundColor: CupertinoColors.systemRed.withValues(
                  alpha: .3,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                minimumSize: const Size(0, 42),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                textStyle: const TextStyle(fontSize: 13),
              ),
              onPressed: () async {
                await Navigator.push(
                  c,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => ExpenseForm(group: group, expense: expense),
                  ),
                );
                if (c.mounted) Navigator.pop(c);
              },
              child: const Text('Edit'),
            ),
          ),
        ),
        const SizedBox(height: 28),
        PaymentSummary(group: group, expense: expense),
        Expanded(
          child: PaymentShares(group: group, expense: expense),
        ),
      ],
    ),
  );
}

String shortDate(dynamic raw) {
  final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
  if (date == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}, ${two(date.hour)}:${two(date.minute)}';
}

String groupDate(Map group) {
  try {
    final legacy = jsonDecode(group['date_json'] ?? 'null');
    if (legacy is Map && legacy['seconds'] is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (legacy['seconds'] as num).toInt() * 1000,
        isUtc: true,
      ).toIso8601String();
    }
  } catch (_) {
    /* Groups created after migration use created_at. */
  }
  return group['created_at']?.toString() ?? '';
}
