import 'package:flutter/material.dart';

// --- Models ---
class ReminderEntry {
  String id;
  String entryDate;
  String description;
  String daysBefore;
  String triggerTime;
  String reminderDateTime;
  String repeatOption;

  ReminderEntry({
    required this.id,
    required this.entryDate,
    required this.description,
    this.daysBefore = '',
    this.triggerTime = '08:00',
    required this.reminderDateTime,
    this.repeatOption = 'None',
  });
}

class InfoEntry {
  String id;
  String entryDate;
  String description;
  String infoDate;

  InfoEntry({
    required this.id,
    required this.entryDate,
    required this.description,
    required this.infoDate,
  });
}

class SubInformation {
  String id;
  String title;
  List<SubInformation> subCategories;
  List<InfoEntry> entries;

  SubInformation({
    required this.id,
    required this.title,
    List<SubInformation>? subCategories,
    List<InfoEntry>? entries,
  })  : subCategories = subCategories ?? [],
        entries = entries ?? [];
}

class RemindersInfoScreen extends StatefulWidget {
  const RemindersInfoScreen({super.key});

  @override
  State<RemindersInfoScreen> createState() => _RemindersInfoScreenState();
}

class _RemindersInfoScreenState extends State<RemindersInfoScreen> {
  List<SubInformation> rootGeneralInfo = [];
  List<InfoEntry> rootEntries = [];
  List<ReminderEntry> reminderEntries = [];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reminders & General Info', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.indigo.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.notifications), text: 'Reminders'),
              Tab(icon: Icon(Icons.info_outline), text: 'General Information'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. Reminders Tab
            RemindersContentSection(
              remindersList: reminderEntries,
              onStateChanged: () => setState(() {}),
            ),

            // 2. General Information Tab
            GeneralInfoContent(
              subInfoList: rootGeneralInfo,
              entriesList: rootEntries,
              onStateChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Reminders Section Widget
// -------------------------------------------------------------
class RemindersContentSection extends StatefulWidget {
  final List<ReminderEntry> remindersList;
  final VoidCallback onStateChanged;

  const RemindersContentSection({
    super.key,
    required this.remindersList,
    required this.onStateChanged,
  });

  @override
  State<RemindersContentSection> createState() => _RemindersContentSectionState();
}

class _RemindersContentSectionState extends State<RemindersContentSection> {
  void _showReminderDialog({ReminderEntry? existingReminder}) {
    final TextEditingController entryDateController = TextEditingController(
      text: existingReminder?.entryDate ?? _getTodayDateString(),
    );
    final TextEditingController descController = TextEditingController(
      text: existingReminder?.description ?? '',
    );
    final TextEditingController daysBeforeController = TextEditingController(
      text: existingReminder?.daysBefore ?? '',
    );
    final TextEditingController timeController = TextEditingController(
      text: existingReminder?.triggerTime ?? '08:00',
    );
    final TextEditingController reminderDateTimeController = TextEditingController(
      text: existingReminder?.reminderDateTime ?? '${_getTodayDateString()} 08:00',
    );

    String selectedRepeat = existingReminder?.repeatOption ?? 'None';
    List<String> repeatOptions = ['None', 'Every Day', 'Every Week', 'Every Month', 'Every Year'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingReminder == null ? 'Add Reminder Entry' : 'Edit Reminder Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: entryDateController,
                      decoration: const InputDecoration(
                        labelText: 'Entry Date (dd-mm-yyyy)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: daysBeforeController,
                      decoration: const InputDecoration(
                        labelText: 'No. of Days Before (Optional)',
                        hintText: 'e.g., 1d, 2d',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: 'Which Time (hh:mm) (Optional)',
                        hintText: 'e.g., 01:10 (Default 08:00 AM)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reminderDateTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Reminder Date & Time (dd-mm-yyyy hh:mm)',
                        hintText: 'dd-mm-yyyy hh:mm',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedRepeat,
                      decoration: const InputDecoration(
                        labelText: 'Repeat Alarm',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: repeatOptions.map((opt) {
                        return DropdownMenuItem(value: opt, child: Text(opt));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedRepeat = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (descController.text.trim().isNotEmpty) {
                      String finalTime = timeController.text.trim().isEmpty ? '08:00' : timeController.text.trim();

                      setState(() {
                        if (existingReminder == null) {
                          widget.remindersList.add(
                            ReminderEntry(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              entryDate: entryDateController.text.trim(),
                              description: descController.text.trim(),
                              daysBefore: daysBeforeController.text.trim(),
                              triggerTime: finalTime,
                              reminderDateTime: reminderDateTimeController.text.trim(),
                              repeatOption: selectedRepeat,
                            ),
                          );
                        } else {
                          existingReminder.entryDate = entryDateController.text.trim();
                          existingReminder.description = descController.text.trim();
                          existingReminder.daysBefore = daysBeforeController.text.trim();
                          existingReminder.triggerTime = finalTime;
                          existingReminder.reminderDateTime = reminderDateTimeController.text.trim();
                          existingReminder.repeatOption = selectedRepeat;
                        }
                      });
                      widget.onStateChanged();
                      Navigator.pop(context);
                    }
                  },
                  child: Text(existingReminder == null ? 'Save' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getTodayDateString() {
    DateTime now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.indigo.shade50,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade600, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add_alarm, size: 20),
                  label: const Text('Add Entry'),
                  onPressed: () => _showReminderDialog(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.remindersList.isEmpty
              ? const Center(
                  child: Text(
                    'No reminders added yet.\nClick "Add Entry" to create a reminder.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.remindersList.length,
                  itemBuilder: (context, index) {
                    final item = widget.remindersList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Icon(Icons.notifications_active, color: Colors.indigo.shade700),
                        ),
                        title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('⏰ Target: ${item.reminderDateTime}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo)),
                              const SizedBox(height: 2),
                              Text(
                                '📅 Entry: ${item.entryDate}${item.daysBefore.isNotEmpty ? ' | Before: ${item.daysBefore}' : ''} | Time: ${item.triggerTime}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (item.repeatOption != 'None')
                                Text('🔁 Repeat: ${item.repeatOption}', style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                              onPressed: () => _showReminderDialog(existingReminder: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () {
                                setState(() {
                                  widget.remindersList.removeAt(index);
                                });
                                widget.onStateChanged();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// General Information Content Widget
// -------------------------------------------------------------
class GeneralInfoContent extends StatefulWidget {
  final List<SubInformation> subInfoList;
  final List<InfoEntry> entriesList;
  final VoidCallback onStateChanged;

  const GeneralInfoContent({
    super.key,
    required this.subInfoList,
    required this.entriesList,
    required this.onStateChanged,
  });

  @override
  State<GeneralInfoContent> createState() => _GeneralInfoContentState();
}

class _GeneralInfoContentState extends State<GeneralInfoContent> {
  void _showSubInfoDialog({SubInformation? existingSub}) {
    final TextEditingController titleController = TextEditingController(
      text: existingSub?.title ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existingSub == null ? 'Add Sub Information' : 'Edit Sub Information'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Category Title',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  setState(() {
                    if (existingSub == null) {
                      widget.subInfoList.add(
                        SubInformation(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text.trim(),
                        ),
                      );
                    } else {
                      existingSub.title = titleController.text.trim();
                    }
                  });
                  widget.onStateChanged();
                  Navigator.pop(context);
                }
              },
              child: Text(existingSub == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  void _showEntryDialog({InfoEntry? existingEntry}) {
    final TextEditingController entryDateController = TextEditingController(
      text: existingEntry?.entryDate ?? _getTodayDateString(),
    );
    final TextEditingController descController = TextEditingController(
      text: existingEntry?.description ?? '',
    );
    final TextEditingController infoDateController = TextEditingController(
      text: existingEntry?.infoDate ?? _getTodayDateString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existingEntry == null ? 'Add Information Entry' : 'Edit Information Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: entryDateController,
                  decoration: const InputDecoration(
                    labelText: 'Entry Date (dd-mm-yyyy)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: infoDateController,
                  decoration: const InputDecoration(
                    labelText: 'Information Date (dd-mm-yyyy)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (descController.text.trim().isNotEmpty) {
                  setState(() {
                    if (existingEntry == null) {
                      widget.entriesList.add(
                        InfoEntry(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          entryDate: entryDateController.text.trim(),
                          description: descController.text.trim(),
                          infoDate: infoDateController.text.trim(),
                        ),
                      );
                    } else {
                      existingEntry.entryDate = entryDateController.text.trim();
                      existingEntry.description = descController.text.trim();
                      existingEntry.infoDate = infoDateController.text.trim();
                    }
                  });
                  widget.onStateChanged();
                  Navigator.pop(context);
                }
              },
              child: Text(existingEntry == null ? 'Save' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  String _getTodayDateString() {
    DateTime now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.indigo.shade50,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade600, foregroundColor: Colors.white),
                  icon: const Icon(Icons.create_new_folder, size: 18),
                  label: const Text('Add Sub Info'),
                  onPressed: () => _showSubInfoDialog(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add_task, size: 18),
                  label: const Text('Add Entry'),
                  onPressed: () => _showEntryDialog(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (widget.subInfoList.isNotEmpty) ...[
                const Text('📁 Sub Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo)),
                const SizedBox(height: 6),
                ...widget.subInfoList.map((subItem) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.folder, color: Colors.indigo),
                      title: Text(subItem.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Sub-categories: ${subItem.subCategories.length} | Entries: ${subItem.entries.length}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                            onPressed: () => _showSubInfoDialog(existingSub: subItem),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() {
                                widget.subInfoList.remove(subItem);
                              });
                              widget.onStateChanged();
                            },
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubInformationDetailPage(
                              subInfo: subItem,
                              onStateChanged: () {
                                setState(() {});
                                widget.onStateChanged();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
              ],
              const Text('📝 Entries List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal)),
              const SizedBox(height: 6),
              if (widget.subInfoList.isEmpty && widget.entriesList.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'No information or entries found.\nUse the buttons above to add.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else if (widget.entriesList.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No entries added here yet.', style: TextStyle(color: Colors.grey)),
                )
              else
                ...widget.entriesList.map((entry) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 2,
                    child: ListTile(
                      title: Text(entry.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Text('📅 Entry Date: ${entry.entryDate}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 10),
                            Text('ℹ️ Info Date: ${entry.infoDate}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                            onPressed: () => _showEntryDialog(existingEntry: entry),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() {
                                widget.entriesList.remove(entry);
                              });
                              widget.onStateChanged();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// Nested Sub Information Detail Page
// -------------------------------------------------------------
class SubInformationDetailPage extends StatefulWidget {
  final SubInformation subInfo;
  final VoidCallback onStateChanged;

  const SubInformationDetailPage({
    super.key,
    required this.subInfo,
    required this.onStateChanged,
  });

  @override
  State<SubInformationDetailPage> createState() => _SubInformationDetailPageState();
}

class _SubInformationDetailPageState extends State<SubInformationDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subInfo.title),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: GeneralInfoContent(
        subInfoList: widget.subInfo.subCategories,
        entriesList: widget.subInfo.entries,
        onStateChanged: widget.onStateChanged,
      ),
    );
  }
}