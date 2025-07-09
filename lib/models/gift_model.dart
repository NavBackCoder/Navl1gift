class Gift {
  final String id;
  final String userId;
  final String giftName;
  final String? assignedTo;
  final String? suggestedGifter;
  final String status;
  final DateTime? timestamp;
  final String teamId;

  Gift({
    required this.id,
    required this.userId,
    required this.giftName,
    this.assignedTo,
    this.suggestedGifter,
    required this.status,
    this.timestamp,
    required this.teamId,
  });

  factory Gift.fromMap(String id, Map<String, dynamic> data) {
    return Gift(
      id: id,
      userId: data['userId'],
      giftName: data['giftName'],
      assignedTo: data['assignedTo'],
      suggestedGifter: data['suggestedGifter'],
      status: data['status'] ?? 'pending',
      timestamp: data['timestamp']?.toDate(),
      teamId: data['teamId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'giftName': giftName,
      'assignedTo': assignedTo,
      'suggestedGifter': suggestedGifter,
      'status': status,
      'timestamp': timestamp,
      'teamId': teamId,
    };
  }
}
