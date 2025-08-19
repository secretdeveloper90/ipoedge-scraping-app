import 'package:flutter/material.dart';
import 'listing_tab.dart';
import 'management_tab.dart';
import 'yearly_screener_tab.dart';

class IpoScreen extends StatefulWidget {
  const IpoScreen({super.key});

  @override
  State<IpoScreen> createState() => _IpoScreenState();
}

class _IpoScreenState extends State<IpoScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  final List<Widget> _tabs = [
    const ListingTab(),
    const ManagementTab(),
    const YearlyScreenerTab(),
  ];

  final List<_TabInfo> _tabInfo = [
    const _TabInfo(
      icon: Icons.trending_up_rounded,
      label: 'Listing',
      tooltip: 'View IPO Listings',
    ),
    const _TabInfo(
      icon: Icons.dashboard_customize_rounded,
      label: 'Management',
      tooltip: 'Manage IPOs',
    ),
    const _TabInfo(
      icon: Icons.analytics_rounded,
      label: 'Screener',
      tooltip: 'Yearly Analysis',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
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
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
