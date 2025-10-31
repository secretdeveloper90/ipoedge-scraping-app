import 'package:flutter/material.dart';
import 'mainboard_current_tab.dart';
import 'mainboard_upcoming_tab.dart';
import 'mainboard_listed_tab.dart';

class MainboardIpoScreen extends StatefulWidget {
  const MainboardIpoScreen({super.key});

  @override
  State<MainboardIpoScreen> createState() => _MainboardIpoScreenState();
}

class _MainboardIpoScreenState extends State<MainboardIpoScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  final List<Widget> _tabs = [
    const MainboardCurrentTab(),
    const MainboardUpcomingTab(),
    const MainboardListedTab(),
  ];

  final List<_TabInfo> _tabInfo = [
    const _TabInfo(
      icon: Icons.access_time_rounded,
      label: 'Current',
      tooltip: 'Current Mainboard IPOs',
    ),
    const _TabInfo(
      icon: Icons.schedule_rounded,
      label: 'Upcoming',
      tooltip: 'Upcoming Mainboard IPOs',
    ),
    const _TabInfo(
      icon: Icons.check_circle_rounded,
      label: 'Listed',
      tooltip: 'Listed Mainboard IPOs',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          // Tab index changed
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorColor: Theme.of(context).primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: _tabInfo
            .map((tabInfo) => Tab(
                  icon: Icon(
                    tabInfo.icon,
                    size: 20,
                  ),
                  text: tabInfo.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabInfo {
  final IconData icon;
  final String label;
  final String tooltip;

  const _TabInfo({
    required this.icon,
    required this.label,
    required this.tooltip,
  });
}

