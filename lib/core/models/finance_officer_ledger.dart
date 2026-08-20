/// Data model untuk agregasi buku kas dan monitoring petugas keuangan
class FinanceOfficerLedgerItem {
  final String id;
  final String fullName;
  final String? email;
  final String? username;
  final String? phoneNumber;
  final bool isActive;
  final String? avatarUrl;
  final String assignedSchool;
  final String authorityLevel;
  final int totalCashInflow;
  final int totalCashOutflow;
  final int netCashHandled;
  final int totalTransactions;
  final int todayCashInflow;
  final int todayCashOutflow;
  final int todayNetCash;
  final int todayTxCount;
  final DateTime? createdAt;

  const FinanceOfficerLedgerItem({
    required this.id,
    required this.fullName,
    this.email,
    this.username,
    this.phoneNumber,
    this.isActive = true,
    this.avatarUrl,
    this.assignedSchool = 'Sekolah Digital',
    this.authorityLevel = 'L1',
    this.totalCashInflow = 0,
    this.totalCashOutflow = 0,
    this.netCashHandled = 0,
    this.totalTransactions = 0,
    this.todayCashInflow = 0,
    this.todayCashOutflow = 0,
    this.todayNetCash = 0,
    this.todayTxCount = 0,
    this.createdAt,
  });

  factory FinanceOfficerLedgerItem.fromJson(Map<String, dynamic> json) {
    return FinanceOfficerLedgerItem(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Petugas Keuangan',
      email: json['email']?.toString(),
      username: json['username']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      isActive: json['is_active'] != false,
      avatarUrl: json['avatar_url']?.toString(),
      assignedSchool: json['assigned_school']?.toString() ?? 'Sekolah Digital',
      authorityLevel: json['authority_level']?.toString() ?? 'L1',
      totalCashInflow: int.tryParse(json['total_cash_inflow']?.toString() ?? '0') ?? 0,
      totalCashOutflow: int.tryParse(json['total_cash_outflow']?.toString() ?? '0') ?? 0,
      netCashHandled: int.tryParse(json['net_cash_handled']?.toString() ?? '0') ?? 0,
      totalTransactions: int.tryParse(json['total_transactions']?.toString() ?? '0') ?? 0,
      todayCashInflow: int.tryParse(json['today_cash_inflow']?.toString() ?? '0') ?? 0,
      todayCashOutflow: int.tryParse(json['today_cash_outflow']?.toString() ?? '0') ?? 0,
      todayNetCash: int.tryParse(json['today_net_cash']?.toString() ?? '0') ?? 0,
      todayTxCount: int.tryParse(json['today_tx_count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'username': username,
        'phone_number': phoneNumber,
        'is_active': isActive,
        'avatar_url': avatarUrl,
        'assigned_school': assignedSchool,
        'authority_level': authorityLevel,
        'total_cash_inflow': totalCashInflow,
        'total_cash_outflow': totalCashOutflow,
        'net_cash_handled': netCashHandled,
        'total_transactions': totalTransactions,
        'today_cash_inflow': todayCashInflow,
        'today_cash_outflow': todayCashOutflow,
        'today_net_cash': todayNetCash,
        'today_tx_count': todayTxCount,
        'created_at': createdAt?.toIso8601String(),
      };
}

/// Item jurnal transaksi kas per petugas keuangan
class OfficerJournalEntry {
  final String id;
  final String? transactionId;
  final String type; // TOPUP, WITHDRAWAL, CORRECTION, ADJUSTMENT
  final String category; // INFLOW, OUTFLOW, ADJUSTMENT
  final int amount;
  final String targetName;
  final String targetRole;
  final String targetId;
  final String notes;
  final String method;
  final DateTime? createdAt;

  const OfficerJournalEntry({
    required this.id,
    this.transactionId,
    required this.type,
    required this.category,
    required this.amount,
    required this.targetName,
    this.targetRole = '',
    this.targetId = '',
    this.notes = '',
    this.method = 'Tunai',
    this.createdAt,
  });

  factory OfficerJournalEntry.fromJson(Map<String, dynamic> json) {
    return OfficerJournalEntry(
      id: json['id']?.toString() ?? '',
      transactionId: json['transaction_id']?.toString(),
      type: json['type']?.toString() ?? 'TOPUP',
      category: json['category']?.toString() ?? 'INFLOW',
      amount: int.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      targetName: json['target_name']?.toString() ?? 'Siswa',
      targetRole: json['target_role']?.toString() ?? '',
      targetId: json['target_id']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      method: json['method']?.toString() ?? 'Tunai',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaction_id': transactionId,
        'type': type,
        'category': category,
        'amount': amount,
        'target_name': targetName,
        'target_role': targetRole,
        'target_id': targetId,
        'notes': notes,
        'method': method,
        'created_at': createdAt?.toIso8601String(),
      };
}

/// Detail lengkap pembukuan kas petugas keuangan
class FinanceOfficerLedgerDetail {
  final FinanceOfficerLedgerItem officer;
  final List<OfficerJournalEntry> recentJournals;
  final List<int> weeklyInflow;
  final List<int> weeklyOutflow;

  const FinanceOfficerLedgerDetail({
    required this.officer,
    this.recentJournals = const [],
    this.weeklyInflow = const [],
    this.weeklyOutflow = const [],
  });

  factory FinanceOfficerLedgerDetail.fromJson(Map<String, dynamic> json) {
    final officerMap = json['officer'] as Map<String, dynamic>? ?? {};
    final journalsList = json['recent_journals'] as List<dynamic>? ?? [];
    final inList = json['weekly_inflow'] as List<dynamic>? ?? [];
    final outList = json['weekly_outflow'] as List<dynamic>? ?? [];

    return FinanceOfficerLedgerDetail(
      officer: FinanceOfficerLedgerItem.fromJson(officerMap),
      recentJournals: journalsList.map((e) => OfficerJournalEntry.fromJson(e as Map<String, dynamic>)).toList(),
      weeklyInflow: inList.map((e) => int.tryParse(e.toString()) ?? 0).toList(),
      weeklyOutflow: outList.map((e) => int.tryParse(e.toString()) ?? 0).toList(),
    );
  }
}
