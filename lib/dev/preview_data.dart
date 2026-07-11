import 'dart:async';

/// Fixed ids/names for the in-memory data [PreviewStore] serves when
/// `PreviewMode.enabled` is true — the login screen's debug bypass signs a
/// user into one of these identities instead of a real Supabase session.
abstract class PreviewIds {
  static const businessId = 'preview-business-1';

  static const client = 'preview-client-1';
  static const clientName = 'Jordan Alvarez';

  static const technician = 'preview-tech-1';
  static const technicianName = 'Sam Ortiz';

  static const owner = 'preview-owner-1';
  static const ownerName = 'Alex Rivera';
}

String _dateAt(int daysFromNow) {
  final now = DateTime.now();
  final date = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(Duration(days: daysFromNow));
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _time(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';

String _createdAt(int daysAgo) =>
    DateTime.now().subtract(Duration(days: daysAgo)).toIso8601String();

/// In-memory jobs/profiles that back every repository in preview mode, so
/// the Client, Technician, and Owner screens all show consistent,
/// interconnected sample data instead of three unrelated stubs. Mutating
/// methods (status changes, availability toggles, etc.) update these lists
/// and push through the broadcast streams so the UI reacts live, the same
/// way it would to a Supabase Realtime event.
class PreviewStore {
  PreviewStore._() {
    _jobs.addAll(_seedJobs());
    _profiles.addAll(_seedProfiles());
  }

  static final PreviewStore instance = PreviewStore._();

  final List<Map<String, dynamic>> _jobs = [];
  final List<Map<String, dynamic>> _profiles = [];

  final _jobsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _profilesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  List<Map<String, dynamic>> get jobs =>
      List.unmodifiable(_jobs.map(_withTechnician));

  List<Map<String, dynamic>> get profiles => List.unmodifiable(_profiles);

  Stream<List<Map<String, dynamic>>> watchJobs() async* {
    yield jobs;
    yield* _jobsController.stream;
  }

  Stream<List<Map<String, dynamic>>> watchProfiles() async* {
    yield profiles;
    yield* _profilesController.stream;
  }

  Map<String, dynamic> _withTechnician(Map<String, dynamic> job) {
    final techId = job['assigned_technician_id'] as String?;
    if (techId == null) return job;
    final tech = _profiles.firstWhere(
      (p) => p['id'] == techId,
      orElse: () => const {},
    );
    final name = tech['full_name'] as String?;
    if (name == null) return job;
    return {
      ...job,
      'technician': {'full_name': name},
    };
  }

  void _emitJobs() => _jobsController.add(jobs);

  void _emitProfiles() => _profilesController.add(profiles);

  String createJob(Map<String, dynamic> data) {
    final id =
        'preview-job-${_jobs.length + 1}-${DateTime.now().millisecondsSinceEpoch}';
    _jobs.add({
      ...data,
      'id': id,
      'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
    });
    _emitJobs();
    return id;
  }

  void updateJob(String id, Map<String, dynamic> patch) {
    final index = _jobs.indexWhere((j) => j['id'] == id);
    if (index == -1) return;
    _jobs[index] = {..._jobs[index], ...patch};
    _emitJobs();
  }

  void deleteJob(String id) {
    _jobs.removeWhere((j) => j['id'] == id);
    _emitJobs();
  }

  void updateProfile(String id, Map<String, dynamic> patch) {
    final index = _profiles.indexWhere((p) => p['id'] == id);
    if (index == -1) return;
    _profiles[index] = {..._profiles[index], ...patch};
    _emitProfiles();
    _emitJobs(); // technician-name embeds may have changed
  }

  List<Map<String, dynamic>> _seedProfiles() => [
    {
      'id': PreviewIds.client,
      'full_name': PreviewIds.clientName,
      'role': 'client',
      'business_id': PreviewIds.businessId,
    },
    {
      'id': 'preview-client-2',
      'full_name': 'Dana Kim',
      'role': 'client',
      'business_id': PreviewIds.businessId,
    },
    {
      'id': 'preview-client-3',
      'full_name': 'Chris Nolan',
      'role': 'client',
      'business_id': PreviewIds.businessId,
    },
    {
      'id': PreviewIds.technician,
      'full_name': PreviewIds.technicianName,
      'role': 'technician',
      'business_id': PreviewIds.businessId,
      'is_available': true,
      'is_active': true,
    },
    {
      'id': 'preview-tech-2',
      'full_name': 'Riley Chen',
      'role': 'technician',
      'business_id': PreviewIds.businessId,
      'is_available': false,
      'is_active': true,
    },
    {
      'id': 'preview-tech-3',
      'full_name': 'Morgan Blake',
      'role': 'technician',
      'business_id': PreviewIds.businessId,
      'is_available': true,
      'is_active': false,
    },
    {
      'id': 'preview-tech-4',
      'full_name': 'Taylor Reed',
      'role': 'technician',
      'business_id': null,
      'is_available': true,
      'is_active': true,
    },
    {
      'id': PreviewIds.owner,
      'full_name': PreviewIds.ownerName,
      'role': 'owner',
      'business_id': PreviewIds.businessId,
    },
  ];

  List<Map<String, dynamic>> _seedJobs() => [
    {
      'id': 'preview-job-1',
      'business_id': PreviewIds.businessId,
      'client_id': PreviewIds.client,
      'assigned_technician_id': PreviewIds.technician,
      'client_name': PreviewIds.clientName,
      'address': '123 Maple St, Springfield',
      'description': 'Leaking kitchen faucet, dripping steadily.',
      'scheduled_date': _dateAt(0),
      'scheduled_time': _time(10, 0),
      'status': 'in_progress',
      'photo_urls': <String>[],
      'technician_notes': null,
      'owner_notes': 'Client has a dog, use the side gate.',
      'created_at': _createdAt(3),
    },
    {
      'id': 'preview-job-2',
      'business_id': PreviewIds.businessId,
      'client_id': PreviewIds.client,
      'assigned_technician_id': null,
      'client_name': PreviewIds.clientName,
      'address': '77 Birch Ave, Springfield',
      'description': "AC not cooling, thermostat reads 78 and won't drop.",
      'scheduled_date': _dateAt(1),
      'scheduled_time': _time(13, 30),
      'status': 'pending',
      'photo_urls': <String>[],
      'created_at': _createdAt(1),
    },
    {
      'id': 'preview-job-3',
      'business_id': PreviewIds.businessId,
      'client_id': PreviewIds.client,
      'assigned_technician_id': 'preview-tech-2',
      'client_name': PreviewIds.clientName,
      'address': '9 Cedar Ln, Springfield',
      'description': 'Water heater install, 50 gal.',
      'scheduled_date': _dateAt(-5),
      'scheduled_time': _time(9, 0),
      'status': 'completed',
      'photo_urls': <String>[],
      'technician_notes': 'Installed new 50gal unit, tested for leaks.',
      'created_at': _createdAt(6),
    },
    {
      'id': 'preview-job-4',
      'business_id': PreviewIds.businessId,
      'client_id': 'preview-client-2',
      'assigned_technician_id': PreviewIds.technician,
      'client_name': 'Dana Kim',
      'address': '400 Oak Blvd, Springfield',
      'description': 'Clogged kitchen drain, backing up.',
      'scheduled_date': _dateAt(0),
      'scheduled_time': _time(14, 0),
      'status': 'pending',
      'photo_urls': <String>[],
      'created_at': _createdAt(0),
    },
    {
      'id': 'preview-job-5',
      'business_id': PreviewIds.businessId,
      'client_id': 'preview-client-2',
      'assigned_technician_id': PreviewIds.technician,
      'client_name': 'Dana Kim',
      'address': '15 Pine Ct, Springfield',
      'description': 'Circuit breaker tripping in garage panel.',
      'scheduled_date': _dateAt(0),
      'scheduled_time': _time(16, 0),
      'status': 'in_progress',
      'photo_urls': <String>[],
      'created_at': _createdAt(2),
    },
    {
      'id': 'preview-job-6',
      'business_id': PreviewIds.businessId,
      'client_id': 'preview-client-3',
      'assigned_technician_id': 'preview-tech-2',
      'client_name': 'Chris Nolan',
      'address': '221 Elm Way, Springfield',
      'description': 'Ceiling fan installation, two units.',
      'scheduled_date': _dateAt(-10),
      'scheduled_time': _time(11, 0),
      'status': 'completed',
      'photo_urls': <String>[],
      'created_at': _createdAt(12),
    },
    {
      'id': 'preview-job-7',
      'business_id': PreviewIds.businessId,
      'client_id': PreviewIds.client,
      'assigned_technician_id': 'preview-tech-3',
      'client_name': PreviewIds.clientName,
      'address': '58 Willow Dr, Springfield',
      'description': 'Replaced garbage disposal.',
      'scheduled_date': _dateAt(-20),
      'scheduled_time': _time(15, 0),
      'status': 'completed',
      'photo_urls': <String>[],
      'created_at': _createdAt(20),
    },
    {
      'id': 'preview-job-8',
      'business_id': PreviewIds.businessId,
      'client_id': 'preview-client-3',
      'assigned_technician_id': null,
      'client_name': 'Chris Nolan',
      'address': '5 Aspen Sq, Springfield',
      'description': 'Outlet not working in home office.',
      'scheduled_date': _dateAt(3),
      'scheduled_time': _time(9, 30),
      'status': 'pending',
      'photo_urls': <String>[],
      'created_at': _createdAt(0),
    },
  ];
}
