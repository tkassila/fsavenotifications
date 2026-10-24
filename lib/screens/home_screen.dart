import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../models/saved_notification.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  late TabController _tabController;

  List<SavedNotification> _unreadNotifications = [];
  List<SavedNotification> _allNotifications = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  StreamSubscription<void>? _notificationSubscription;
  StreamSubscription<String>? _openTabSubscription;
  String _searchQuery = '';

  AppStrings get _strings => LocaleService().strings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocaleService().addListener(_onLocaleChanged);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    _checkPermissionAndLoad();
    _checkInitialTab();

    // Kuuntele reaaliaikaisia uusia ilmoituksia taustapalvelulta
    _notificationSubscription =
        _notificationService.onNewNotification.listen((_) {
      _loadNotifications();
    });

    // Kuuntele ilmoituksesta saapuvaa pyyntöä avata tietty välilehti
    _openTabSubscription = _notificationService.onOpenTab.listen((tab) {
      if (tab == 'history') {
        _tabController.animateTo(1);
      }
    });
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkInitialTab() async {
    final tab = await _notificationService.getInitialTab();
    if (tab == 'history' && mounted) {
      _tabController.animateTo(1);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocaleService().removeListener(_onLocaleChanged);
    _notificationSubscription?.cancel();
    _openTabSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndLoad();
      _checkInitialTab();
    }
  }

  Future<void> _checkPermissionAndLoad() async {
    final hasPerm = await _notificationService.isNotificationAccessGranted();
    if (mounted) {
      setState(() {
        _hasPermission = hasPerm;
      });
    }
    await _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final unread = await _notificationService.getUnreadNotifications();
    final all = await _notificationService.getAllNotifications();
    if (mounted) {
      setState(() {
        _unreadNotifications = unread;
        _allNotifications = all;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(SavedNotification item) async {
    final success = await _notificationService.markAsRead(item.id);
    if (success) {
      setState(() {
        _unreadNotifications.removeWhere((n) => n.id == item.id);
      });
      _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_strings.markedOneReadSnack(item.title.isNotEmpty ? item.title : item.appName)),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final count = await _notificationService.markAllAsRead();
    await _loadNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_strings.markedAllReadSnack(count))),
      );
    }
  }

  Future<void> _deleteNotification(SavedNotification item) async {
    await _notificationService.deleteNotification(item.id);
    await _loadNotifications();
  }

  Future<void> _clearReadHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_strings.confirmClearTitle),
        content: Text(_strings.confirmClearDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_strings.clear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notificationService.clearRead();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_strings.historyClearedSnack)),
        );
      }
    }
  }

  Future<void> _showTestNotificationDialog() async {
    final titleController = TextEditingController(text: _strings.testDefaultTitle);
    final messageController = TextEditingController(
      text: _strings.testDefaultMessage,
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_strings.testDialogTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _strings.testSection1Title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: _strings.testFieldTitleLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: messageController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: _strings.testFieldMessageLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.send, size: 16),
                  label: Text(_strings.testSendBtn),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _notificationService.sendTestNotification(
                      title: titleController.text,
                      message: messageController.text,
                    );
                  },
                ),
              ),
              const Divider(height: 24),
              Text(
                _strings.testSection2Title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                _strings.testSection2Desc,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.notification_important, color: Colors.orange, size: 18),
                  label: Text(_strings.testTriggerAlertBtn),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _notificationService.triggerHistoryAlert();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_strings.testAlertSentSnack),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_chart, size: 18),
                  label: Text(_strings.testGenerate500Btn),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final inserted = await _notificationService.insertBatchTestMessages(
                      count: 500,
                      markAsRead: true,
                    );
                    await _loadNotifications();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_strings.testBatchAddedSnack(inserted)),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                _strings.testSection3Title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.battery_charging_full, color: Colors.green, size: 18),
                  label: Text(_strings.testDisableBatteryOptBtn),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _notificationService.requestIgnoreBatteryOptimizations();
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.menu_book, color: Colors.blueGrey, size: 18),
                  label: Text(_strings.testOpenGuideBtn),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showBatteryAndUsageGuide();
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_strings.close),
          ),
        ],
      ),
    );
  }

  void _showBatteryAndUsageGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.battery_saver, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _strings.guideDialogTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideSectionHeader(_strings.guideSec1Title),
              const SizedBox(height: 6),
              Text(
                _strings.guideSec1Content,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),
              _buildGuideSectionHeader(_strings.guideSec2Title),
              const SizedBox(height: 6),
              Text(
                _strings.guideSec2Content,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),
              _buildGuideSectionHeader(_strings.guideSec3Title),
              const SizedBox(height: 6),
              Text(
                _strings.guideSec3Content,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),
              _buildGuideSectionHeader(_strings.guideQuickSettingsTitle),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.settings, size: 18),
                  label: Text(_strings.guideBtnAppInfo),
                  onPressed: () {
                    _notificationService.openAppSettings();
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.battery_charging_full, size: 18),
                  label: Text(_strings.guideBtnDisableOpt),
                  onPressed: () {
                    _notificationService.requestIgnoreBatteryOptimizations();
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_strings.close),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.blueGrey),
    );
  }

  void _showNotificationDetail(SavedNotification item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final timeStr = DateFormat('dd.MM.yyyy HH:mm:ss').format(item.postTime);
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      item.appName.isNotEmpty ? item.appName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.appName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          item.packageName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.isRead
                          ? Colors.grey.shade200
                          : Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.isRead ? _strings.badgeRead : _strings.badgeNew,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.isRead
                            ? Colors.grey.shade700
                            : Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              Text(
                _strings.arrivalTime(timeStr),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              if (item.title.isNotEmpty) ...[
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                item.text.isNotEmpty ? item.text : _strings.noTextContent,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text(_strings.delete, style: const TextStyle(color: Colors.red)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteNotification(item);
                    },
                  ),
                  const SizedBox(width: 8),
                  if (!item.isRead)
                    FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: Text(_strings.markAsRead),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _markAsRead(item);
                      },
                    )
                  else
                    FilledButton.tonal(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(_strings.close),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );

    // Jos ilmoitus oli lukematon, merkitään luetuksi kun käyttäjä on avannut sen
    if (!item.isRead) {
      _markAsRead(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadFiltered = _unreadNotifications.where((n) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return n.appName.toLowerCase().contains(q) ||
          n.title.toLowerCase().contains(q) ||
          n.text.toLowerCase().contains(q);
    }).toList();

    final readFiltered = _allNotifications.where((n) => n.isRead).where((n) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return n.appName.toLowerCase().contains(q) ||
          n.title.toLowerCase().contains(q) ||
          n.text.toLowerCase().contains(q);
    }).toList();

    final int totalHistoryCount = readFiltered.length;
    final bool hasTooManyHistory = totalHistoryCount >= 500;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings.appTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
            Text(
              _strings.appSubtitle,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<AppLanguage>(
            tooltip: _strings.tooltipLanguage,
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LocaleService().currentLanguage.flag,
                  style: const TextStyle(fontSize: 18),
                ),
                const Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
            onSelected: (AppLanguage lang) {
              LocaleService().setLanguage(lang);
            },
            itemBuilder: (context) => AppLanguage.values.map((lang) {
              final isSelected = lang == LocaleService().currentLanguage;
              return PopupMenuItem<AppLanguage>(
                value: lang,
                child: Row(
                  children: [
                    Text(lang.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Text(
                      lang.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isSelected) ...[
                      const Spacer(),
                      const Icon(Icons.check, size: 18, color: Colors.blue),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            tooltip: _strings.tooltipGuide,
            icon: const Icon(Icons.help_outline),
            onPressed: _showBatteryAndUsageGuide,
          ),
          IconButton(
            tooltip: _strings.tooltipRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
          if (_tabController.index == 0 && _unreadNotifications.isNotEmpty)
            IconButton(
              tooltip: _strings.tooltipMarkAllRead,
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
            ),
          if (_tabController.index == 1 && readFiltered.isNotEmpty)
            IconButton(
              tooltip: _strings.tooltipClearHistory,
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearReadHistory,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_strings.tabUnread),
                  if (_unreadNotifications.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_unreadNotifications.length}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_strings.tabHistory),
                  if (readFiltered.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasTooManyHistory
                            ? Colors.red.shade700
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${readFiltered.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Varoitus/ohjepalkki, jos ilmoitusten kuunteluoikeutta ei ole vielä annettu
          if (!_hasPermission)
            MaterialBanner(
              backgroundColor: Colors.amber.shade100,
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
              content: Text(
                _strings.bannerPermissionText,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13),
              ),
              actions: [
                TextButton(
                  onPressed: _showBatteryAndUsageGuide,
                  child: Text(_strings.bannerBtnGuide),
                ),
                TextButton(
                  onPressed: () async {
                    await _notificationService.openAppSettings();
                  },
                  child: Text(_strings.bannerBtnAppInfo),
                ),
                TextButton(
                  onPressed: () async {
                    await _notificationService.openNotificationAccessSettings();
                  },
                  child: Text(_strings.bannerBtnEnable, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),

          // Varoitusbanneri jos historiaviestejä on 500 tai enemmän
          if (hasTooManyHistory)
            MaterialBanner(
              backgroundColor: Colors.red.shade50,
              leading: const Icon(Icons.warning_rounded, color: Colors.red, size: 36),
              content: Text(
                _strings.bannerHistoryAlert(totalHistoryCount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
              actions: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.delete_sweep, size: 16),
                  label: Text(_strings.bannerHistoryClearBtn),
                  onPressed: _clearReadHistory,
                ),
              ],
            ),

          // Hakukenttä jos ilmoituksia on paljon
          if (_unreadNotifications.isNotEmpty || _allNotifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SearchBar(
                hintText: _strings.searchHint,
                leading: const Icon(Icons.search, size: 20),
                trailing: _searchQuery.isNotEmpty
                    ? [
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() => _searchQuery = ''),
                        ),
                      ]
                    : null,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                elevation: const WidgetStatePropertyAll(1),
              ),
            ),

          // Pääsisältö
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Välilehti 1: Lukemattomat
                      RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: _buildNotificationList(
                          notifications: unreadFiltered,
                          isUnreadTab: true,
                        ),
                      ),
                      // Välilehti 2: Historia
                      RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: _buildNotificationList(
                          notifications: readFiltered,
                          isUnreadTab: false,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTestNotificationDialog,
        icon: const Icon(Icons.notification_add),
        label: Text(_strings.testNotificationsBtn),
      ),
    );
  }

  Widget _buildNotificationList({
    required List<SavedNotification> notifications,
    required bool isUnreadTab,
  }) {
    if (notifications.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isUnreadTab ? Icons.mark_email_read_outlined : Icons.history,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  isUnreadTab
                      ? _strings.emptyUnreadTitle
                      : _strings.emptyHistoryTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isUnreadTab
                      ? _strings.emptyUnreadDesc
                      : _strings.emptyHistoryDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 88, left: 12, right: 12),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final item = notifications[index];
        final timeStr = _formatTimestamp(item.postTime);

        return Dismissible(
          key: ValueKey(item.id),
          direction: isUnreadTab
              ? DismissDirection.horizontal
              : DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isUnreadTab ? Colors.green.shade600 : Colors.red.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(isUnreadTab ? Icons.done : Icons.delete, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  isUnreadTab ? _strings.markAsRead : _strings.delete,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          secondaryBackground: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isUnreadTab ? Colors.green.shade600 : Colors.red.shade600,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  isUnreadTab ? _strings.markAsRead : _strings.delete,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(isUnreadTab ? Icons.done : Icons.delete, color: Colors.white),
              ],
            ),
          ),
          onDismissed: (direction) {
            if (isUnreadTab) {
              _markAsRead(item);
            } else {
              _deleteNotification(item);
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            elevation: isUnreadTab ? 2 : 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isUnreadTab
                  ? BorderSide(color: Theme.of(context).colorScheme.primary.withAlpha(50))
                  : BorderSide(color: Colors.grey.shade300),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showNotificationDetail(item),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ylärivi: Sovelluksen nimi & aikaleima
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            item.appName.isNotEmpty
                                ? item.appName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.appName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Otsikko
                    if (item.title.isNotEmpty) ...[
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isUnreadTab ? FontWeight.bold : FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Viestin sisältö
                    if (item.text.isNotEmpty)
                      Text(
                        item.text,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    // Alarivi: toiminnot
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isUnreadTab)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            icon: const Icon(Icons.done, size: 16),
                            label: Text(_strings.markAsRead, style: const TextStyle(fontSize: 12)),
                            onPressed: () => _markAsRead(item),
                          )
                        else
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                            label: Text(_strings.delete, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            onPressed: () => _deleteNotification(item),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(dt.year, dt.month, dt.day);

    if (notificationDate == today) {
      return DateFormat('HH:mm').format(dt);
    } else if (today.difference(notificationDate).inDays == 1) {
      return _strings.formatYesterday(DateFormat('HH:mm').format(dt));
    } else {
      return DateFormat('dd.MM. HH:mm').format(dt);
    }
  }
}
