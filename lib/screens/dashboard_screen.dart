import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'team_members_screen.dart';

class DashboardScreen extends StatefulWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _giftController = TextEditingController();
  String? _teamId;
  bool _hasShownJoinReminder = false;

  @override
  void initState() {
    super.initState();
    _loadUserTeam();
  }

  Future<void> _loadUserTeam() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get();
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('teamId')) {
      setState(() {
        _teamId = doc['teamId'];
      });
    } else {
      setState(() {
        _teamId = null;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasShownJoinReminder && (_teamId == null || _teamId!.isEmpty)) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please join a team to start adding and claiming gifts!'),
            ),
          );
        }
      });
      _hasShownJoinReminder = true;
    }
  }

  Future<void> _addGift() async {
    final text = _giftController.text.trim();
    if (text.isEmpty || _teamId == null) return;

    await FirebaseFirestore.instance.collection('gifts').add({
      'userId': widget.user.uid,
      'giftName': text,
      'assignedTo': null,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'teamId': _teamId,
    });

    _giftController.clear();
  }

  Future<void> _joinTeamDialog() async {
    final teamController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Join a Team"),
        content: TextField(
          controller: teamController,
          decoration: const InputDecoration(labelText: 'Enter team name'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final teamName = teamController.text.trim();
              if (teamName.isEmpty) return;

              final teamDoc = await FirebaseFirestore.instance.collection('teams').doc(teamName).get();
              if (!teamDoc.exists) {
                await FirebaseFirestore.instance.collection('teams').doc(teamName).set({'createdAt': Timestamp.now()});
              }

              await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set(
                {'teamId': teamName},
                SetOptions(merge: true),
              );

              if (mounted) {
                setState(() => _teamId = teamName);
                Navigator.pop(context);
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  Future<void> _claimGift(String docId) async {
    await FirebaseFirestore.instance.collection('gifts').doc(docId).update({'assignedTo': widget.user.uid});
  }

  Future<void> _suggestGift(String docId) async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Suggest someone to gift this"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Enter email of teammate'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              await FirebaseFirestore.instance.collection('gifts').doc(docId).update({
                'suggestedGifter': email,
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Suggest"),
          )
        ],
      ),
    );
  }

  void _openTeamMembersScreen() {
    if (_teamId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TeamMembersScreen(teamId: _teamId!)),
    );
  }

  Widget _buildGiftList() {
    return Expanded(
      child: ListView(
        children: [
          const ListTile(title: Text("🎁 Your Gift List")),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('gifts')
                .where('userId', isEqualTo: widget.user.uid)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const ListTile(title: Text("No gifts added yet."));
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['giftName'] ?? ''),
                    subtitle: const Text("Added by you"),
                  );
                }).toList(),
              );
            },
          ),
          const Divider(),
          const ListTile(title: Text("🎁 Team Gifts to Claim")),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('gifts')
                .where('teamId', isEqualTo: _teamId)
                .where('userId', isNotEqualTo: widget.user.uid)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const ListTile(title: Text("No gifts from teammates."));
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final assignedTo = data['assignedTo'];
                  final alreadyClaimed = assignedTo != null && assignedTo != '';
                  final isClaimedByYou = assignedTo == widget.user.uid;
                  final suggestedGifter = data['suggestedGifter'];

                  return ListTile(
                    title: Text(data['giftName'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isClaimedByYou) const Text("✅ You're gifting this"),
                        if (!isClaimedByYou && alreadyClaimed) const Text("⛔ Already claimed"),
                        if (suggestedGifter != null) Text("💡 Suggested for: $suggestedGifter"),
                      ],
                    ),
                    trailing: !alreadyClaimed
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => _claimGift(doc.id),
                                child: const Text("Gift it"),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _suggestGift(doc.id),
                                child: const Icon(Icons.lightbulb_outline),
                              ),
                            ],
                          )
                        : null,
                  );
                }).toList(),
              );
            },
          ),
          const Divider(),
          const ListTile(title: Text("💡 Suggestions for You")),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('gifts')
                .where('suggestedGifter', isEqualTo: widget.user.email)
                .where('assignedTo', isNull: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const ListTile(title: Text("No suggestions made to you yet."));
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['giftName'] ?? ''),
                    subtitle: const Text("Suggested you gift this"),
                    trailing: ElevatedButton(
                      onPressed: () => _claimGift(doc.id),
                      child: const Text("Accept Gift"),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.user.email ?? 'User'} (${_teamId ?? "No Team"})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: _openTeamMembersScreen,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: _teamId == null
          ? Center(
              child: ElevatedButton(
                onPressed: _joinTeamDialog,
                child: const Text("Join or Change Team"),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _giftController,
                          decoration: const InputDecoration(labelText: 'Enter a gift'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addGift,
                        child: const Text('Add Gift'),
                      ),
                    ],
                  ),
                ),
                _buildGiftList(),
              ],
            ),
    );
  }
}
