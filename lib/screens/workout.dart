import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bodylog/models/workout_model.dart';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  final WorkoutService _workoutService = WorkoutService();
  String _filterLabel = 'Latest First';
  bool _isAscending = false;

  final List<String> _activities = ['Running', 'Cycling', 'Swimming', 'Hike', 'Gym', 'HIIT'];

  bool _needsDistance(String name) => ['Running', 'Cycling', 'Swimming', 'Hike'].contains(name);

  IconData _getIcon(String name) {
    switch (name) {
      case 'Running': return Icons.directions_run;
      case 'Cycling': return Icons.directions_bike;
      case 'Swimming': return Icons.pool;
      case 'Hike': return Icons.terrain;
      case 'Gym': return Icons.fitness_center;
      case 'HIIT': return Icons.bolt;
      default: return Icons.fitness_center;
    }
  }

  // --- FANCY DELETE CONFIRMATION ---
  void _confirmDelete(int workoutId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Delete Record?'),
          ],
        ),
        content: const Text('Are you sure you want to remove this workout? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              try {
                await _workoutService.deleteWorkout(workoutId);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workout record deleted'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                debugPrint("Delete error: $e");
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- NEW: FANCY EDIT CONFIRMATION ---
  void _confirmEdit(Workout updatedWorkout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Color(0xFF5A72EA)),
            SizedBox(width: 10),
            Text('Save Changes?'),
          ],
        ),
        content: Text('Do you want to update this ${updatedWorkout.name} record with the new details?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A72EA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              try {
                await _workoutService.updateWorkout(updatedWorkout);
                if (mounted) {
                  Navigator.pop(context); // Close confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workout updated successfully!'),
                      backgroundColor: Color(0xFF5A72EA),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                debugPrint("Update error: $e");
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showWorkoutDialog([Workout? workout]) {
    final isEdit = workout != null;
    String selectedActivity = workout?.name ?? _activities[0];
    final durCtrl = TextEditingController(text: workout?.duration.toString() ?? '');
    final calCtrl = TextEditingController(text: workout?.calories.toString() ?? '');
    final distCtrl = TextEditingController(text: workout?.distance?.toString() ?? '');
    final notesCtrl = TextEditingController(text: workout?.notes ?? '');
    DateTime selectedDate = workout?.workoutDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEdit ? 'Edit Record' : 'Add Workout'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedActivity,
                  decoration: const InputDecoration(labelText: 'Sport Activity'),
                  items: _activities.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (val) => setDialogState(() => selectedActivity = val!),
                ),
                TextField(controller: durCtrl, decoration: const InputDecoration(labelText: 'Duration (min)'), keyboardType: TextInputType.number),
                if (_needsDistance(selectedActivity))
                  TextField(controller: distCtrl, decoration: const InputDecoration(labelText: 'Distance (km)'), keyboardType: TextInputType.number),
                TextField(controller: calCtrl, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Add Notes'), maxLines: 2),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("Date: ${selectedDate.toLocal().toString().split(' ')[0]}"),
                  trailing: const Icon(Icons.calendar_today, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) return;

                int dur = int.tryParse(durCtrl.text) ?? 0;
                double? dist = _needsDistance(selectedActivity) ? double.tryParse(distCtrl.text) : null;

                double? calculatedPace;
                if (dist != null && dist > 0) {
                  calculatedPace = (dur / 60) / dist;
                }

                final item = Workout(
                  id: workout?.id,
                  userId: user.id,
                  name: selectedActivity,
                  duration: dur,
                  calories: int.tryParse(calCtrl.text) ?? 0,
                  distance: dist,
                  pace: calculatedPace,
                  notes: notesCtrl.text,
                  workoutDate: selectedDate,
                );

                if (isEdit) {
                  // If editing, close the input dialog first, then show confirmation
                  Navigator.pop(context);
                  _confirmEdit(item);
                } else {
                  await _workoutService.createWorkout(item);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: Text(isEdit ? 'Save Changes' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5A72EA), Color(0xFF8B51E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (Navigator.canPop(context))
                      GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back, color: Colors.white)
                      ),
                    if (Navigator.canPop(context)) const SizedBox(width: 15),

                    const Text('Activity', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                PopupMenuButton<bool>(
                  onSelected: (val) => setState(() {
                    _isAscending = val;
                    _filterLabel = val ? 'Oldest First' : 'Latest First';
                  }),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: false, child: Text('Latest First')),
                    const PopupMenuItem(value: true, child: Text('Oldest First')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_filterLabel, style: const TextStyle(color: Colors.white)),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Workout>>(
              stream: _workoutService.getWorkoutsStream(ascending: _isAscending),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final list = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _buildCard(list[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B51E5),
        onPressed: () => _showWorkoutDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCard(Workout w) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                  child: Icon(_getIcon(w.name), color: Colors.blueAccent),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("${w.workoutDate.day}/${w.workoutDate.month}/${w.workoutDate.year}", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                if (w.notes != null && w.notes!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.notes, size: 20, color: Colors.grey),
                    onPressed: () => _showNotes(w.notes!),
                  ),
                IconButton(onPressed: () => _showWorkoutDialog(w), icon: const Icon(Icons.edit_outlined, size: 20)),

                IconButton(
                    onPressed: () => _confirmDelete(w.id!),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20)
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (w.distance != null) _statItem("DIST", "${w.distance}km"),
                  _statItem("DUR", "${w.duration}m"),
                  if (w.pace != null) _statItem("SPEED", w.displaySpeed),
                  _statItem("KCAL", "${w.calories}"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showNotes(String notes) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Workout Notes'),
        content: Text(notes),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
      ),
    );
  }

  Widget _statItem(String l, String v) => Column(children: [Text(l, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)), Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))]);
}
