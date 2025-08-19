import 'package:flutter/material.dart';
import 'listing_tab.dart';
import 'management_tab.dart';
import 'yearly_screener_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const ListingTab(),
    const ManagementTab(),
    const YearlyScreenerTab(),
  ];

  final List<_TabInfo> _tabInfo = [
    const _TabInfo(
      icon: Icons.trending_up_rounded,
      activeIcon: Icons.trending_up_rounded,
      label: 'Listing',
      tooltip: 'View IPO Listings',
    ),
    const _TabInfo(
      icon: Icons.dashboard_customize_outlined,
      activeIcon: Icons.dashboard_customize_rounded,
      label: 'Management',
      tooltip: 'Manage IPOs',
    ),
    const _TabInfo(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics_rounded,
      label: 'Screener',
      tooltip: 'Yearly Analysis',
    ),
  ];

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(context, colorScheme),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: _tabs,
          ),
        ),
      ),
      bottomNavigationBar:
          _buildModernBottomNavigationBar(context, colorScheme),
    );
  }

  PreferredSizeWidget _buildModernAppBar(
      BuildContext context, ColorScheme colorScheme) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _tabInfo[_currentIndex].activeIcon,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'IPO Edge Admin Panel',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
              ),
              Text(
                _tabInfo[_currentIndex].label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernBottomNavigationBar(
      BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurfaceVariant,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: _tabInfo.asMap().entries.map((entry) {
            final index = entry.key;
            final tabInfo = entry.value;
            final isSelected = index == _currentIndex;

            return BottomNavigationBarItem(
              icon: Icon(
                isSelected ? tabInfo.activeIcon : tabInfo.icon,
              ),
              label: tabInfo.label,
              tooltip: tabInfo.tooltip,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TabInfo {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String tooltip;

  const _TabInfo({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.tooltip,
  });
}
