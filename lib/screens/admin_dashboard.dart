import 'package:bodylog/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _handleLogOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
            (route) => false,
      );
    }
  }

  static Future<bool> showReplyDialog(
      BuildContext context,
      String table,
      String id,
      ) async {
    final controller = TextEditingController();
    bool isSaving = false;
    bool didSave = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Send Reply'),
            content: TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Type your reply...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                  if (controller.text.trim().isEmpty) return;
                  setDialogState(() => isSaving = true);

                  try {
                    await Supabase.instance.client
                        .from(table)
                        .update({
                      'admin_reply': controller.text.trim(),
                    })
                        .eq('id', id);

                    didSave = true;

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reply sent successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    setDialogState(() => isSaving = false);
                  }
                },
                child: isSaving
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Send'),
              ),
            ],
          );
        },
      ),
    );

    return didSave;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Console',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogOut,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _UserDirectoryView(),
          _TicketsView(),
          _RatingsView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: isDarkMode ? Colors.grey[500] : Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Center',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_rate),
            label: 'Ratings',
          ),
        ],
      ),
    );
  }
}

class _UserDirectoryView extends StatelessWidget {
  const _UserDirectoryView();

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: client.from('profiles').select().order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildError(snapshot.error.toString());
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.redAccent),
          );
        }

        final users = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final isAdmin = user['is_admin'] == true;
            final date = user['created_at']?.toString().split('T')[0] ?? '';

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: isAdmin
                      ? Colors.redAccent.withOpacity(0.2)
                      : Colors.deepPurple.withOpacity(0.2),
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: isAdmin ? Colors.redAccent : Colors.deepPurple,
                  ),
                ),
                title: Text(
                  user['username'] ?? 'Unknown User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['email'] ?? 'No email',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Joined: $date',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: isAdmin
                    ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class _TicketsView extends StatefulWidget {
  const _TicketsView();

  @override
  State<_TicketsView> createState() => _TicketsViewState();
}

class _TicketsViewState extends State<_TicketsView> {
  late Future<List<Map<String, dynamic>>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() {
    final client = Supabase.instance.client;
    _ticketsFuture = client
        .from('support_center')
        .select('*, profiles(username, email)')
        .order('created_at', ascending: false);
  }

  Future<void> _refreshTickets() async {
    setState(() {
      _loadTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ticketsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildError(snapshot.error.toString());
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.redAccent),
          );
        }
        if (snapshot.data!.isEmpty) {
          return _buildEmptyState(Icons.inbox_outlined, 'No messages yet.');
        }

        final tickets = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            final profile = ticket['profiles'];
            final date = ticket['created_at']?.toString().split('T')[0] ?? '';

            return Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blueAccent.withOpacity(0.15),
                          child: const Icon(
                            Icons.support_agent,
                            size: 20,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile != null
                                    ? (profile['username'] ?? 'Unknown')
                                    : 'Unknown User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (profile != null && profile['email'] != null)
                                Text(
                                  profile['email'],
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ticket['message'] ?? '',
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                    if (ticket['admin_reply'] != null &&
                        ticket['admin_reply'].toString().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Admin Reply:\n${ticket['admin_reply']}",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final didSave =
                            await _AdminDashboardPageState.showReplyDialog(
                              context,
                              'support_center',
                              ticket['id'].toString(),
                            );

                            if (didSave) {
                              await _refreshTickets();
                            }
                          },
                          icon: const Icon(
                            Icons.reply,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          label: const Text(
                            'Reply',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RatingsView extends StatefulWidget {
  const _RatingsView();

  @override
  State<_RatingsView> createState() => _RatingsViewState();
}

class _RatingsViewState extends State<_RatingsView> {
  late Future<List<Map<String, dynamic>>> _ratingsFuture;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  void _loadRatings() {
    final client = Supabase.instance.client;
    _ratingsFuture = client
        .from('app_ratings')
        .select('*, profiles(username)')
        .order('created_at', ascending: false);
  }

  Future<void> _refreshRatings() async {
    setState(() {
      _loadRatings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ratingsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildError(snapshot.error.toString());
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.redAccent),
          );
        }
        if (snapshot.data!.isEmpty) {
          return _buildEmptyState(Icons.star_border_rounded, 'No ratings yet.');
        }

        final ratings = snapshot.data!;

        return RefreshIndicator(
          onRefresh: _refreshRatings,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ratings.length,
            itemBuilder: (context, index) {
              final ratingItem = ratings[index];
              final profile = ratingItem['profiles'];
              final ratingValue = ratingItem['rating'] ?? 0;
              final date = ratingItem['created_at']?.toString().split('T')[0] ?? '';

              return Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.amber.withOpacity(0.15),
                                child: const Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                profile != null
                                    ? (profile['username'] ?? 'Unknown User')
                                    : 'Unknown User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            date,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: List.generate(5, (starIndex) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 2.0),
                            child: Icon(
                              starIndex < ratingValue
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 26,
                            ),
                          );
                        }),
                      ),
                      if (ratingItem['comment'] != null &&
                          ratingItem['comment'].toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[200]!,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.format_quote_rounded,
                                color: Colors.grey[400],
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ratingItem['comment'],
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[800],
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

Widget _buildError(String error) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Database Error',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildEmptyState(IconData icon, String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 64, color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        Text(
          message,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
