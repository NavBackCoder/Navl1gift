import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GiftList extends StatelessWidget {
  final String? teamId;
  final User user;
  final Function(String) onClaimGift;
  final Function(String) onSuggestGift;

  const GiftList({
    super.key,
    required this.teamId,
    required this.user,
    required this.onClaimGift,
    required this.onSuggestGift,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        children: [
          const ListTile(title: Text("🎁 Your Gift List")),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('gifts')
                .where('userId', isEqualTo: user.uid)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const ListTile(title: Text("No gifts added yet."));
              }
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
                .where('teamId', isEqualTo: teamId)
                .where('userId', isNotEqualTo: user.uid)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const ListTile(title: Text("No gifts from teammates."));
              }
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final assignedTo = data['assignedTo'];
                  final alreadyClaimed = assignedTo != null && assignedTo != '';
                  final isClaimedByYou = assignedTo == user.uid;
                  final suggestedGifter = data['suggestedGifter'];

                  return ListTile(
                    title: Text(data['giftName'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isClaimedByYou) const Text("✅ You're gifting this"),
                        if (!isClaimedByYou && alreadyClaimed)
                          const Text("⛔ Already claimed"),
                        if (suggestedGifter != null)
                          Text("💡 Suggested for: $suggestedGifter"),
                      ],
                    ),
                    trailing: !alreadyClaimed
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => onClaimGift(doc.id),
                                child: const Text("Gift it"),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => onSuggestGift(doc.id),
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
                .where('suggestedGifter', isEqualTo: user.email)
                .where('assignedTo', isNull: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const ListTile(
                    title: Text("No suggestions made to you yet."));
              }
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['giftName'] ?? ''),
                    subtitle: const Text("Suggested you gift this"),
                    trailing: ElevatedButton(
                      onPressed: () => onClaimGift(doc.id),
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
}
