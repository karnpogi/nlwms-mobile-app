class AccomplishmentLogItem {
  final int id;
  final String dutyTitle;
  final String remarks;
  final DateTime activityDate;
  final int quantity;
  final String status;
  final List<FeedbackEntry> feedbackEntries;

  const AccomplishmentLogItem({
    required this.id,
    required this.dutyTitle,
    required this.remarks,
    required this.activityDate,
    required this.quantity,
    required this.status,
    this.feedbackEntries = const [],
  });

  AccomplishmentLogItem copyWith({
    int? id,
    String? dutyTitle,
    String? remarks,
    DateTime? activityDate,
    int? quantity,
    String? status,
    List<FeedbackEntry>? feedbackEntries,
  }) {
    return AccomplishmentLogItem(
      id: id ?? this.id,
      dutyTitle: dutyTitle ?? this.dutyTitle,
      remarks: remarks ?? this.remarks,
      activityDate: activityDate ?? this.activityDate,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      feedbackEntries: feedbackEntries ?? this.feedbackEntries,
    );
  }
}

class FeedbackEntry {
  final int id;
  final String userName;
  final String text;
  final DateTime createdAt;
  final bool isEdited;

  const FeedbackEntry({
    required this.id,
    required this.userName,
    required this.text,
    required this.createdAt,
    this.isEdited = false,
  });

  FeedbackEntry copyWith({
    int? id,
    String? userName,
    String? text,
    DateTime? createdAt,
    bool? isEdited,
  }) {
    return FeedbackEntry(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}