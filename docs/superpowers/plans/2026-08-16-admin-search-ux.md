# Admin Search UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix Admin search UX for Users, Vendors, and Products tabs by adding clear search options, active search indicator banners with result count, interactive empty states with "Clear search" action buttons, and state preservation across tab switches and navigation.

**Architecture:** Use `AutomaticKeepAliveClientMixin` on tab states in `AdminDashboard` and `IndexedStack` in `AdminShell` to maintain search query state across navigation. Implement a shared `_buildActiveSearchBanner` component and wire consistent `_clearSearch` handlers in `_AdminUsersTabState`, `_AdminVendorsTabState`, and `_AdminProductsTabState`.

**Tech Stack:** Flutter (Dart), Provider (`AdminProvider`), Material Design with LocalTrade design tokens (`AppColors`, `AppTextStyles`, `EmptyState`).

## Global Constraints

- Design language: No emojis in code, Cream `#FBF5EA`, Coral `#FF6F52`, Ink `#2B2620`, Muted `#6E6557`.
- Typography: Inter/Noto Sans, 400/500 weights only.
- Touch targets: 44px minimum for touchable actions.
- Linting: `flutter analyze` must pass with 0 errors and 0 warnings.
- Conventional commits: `fix(admin): ...`

---

### Task 1: Tab State Preservation in Admin Shell & Admin Dashboard

**Files:**
- Modify: `frontend/localtrade_app/lib/features/admin/admin_shell.dart:40-56`
- Modify: `frontend/localtrade_app/lib/features/admin/admin_dashboard.dart:1221-1255, 1550-1586, 2057-2092, 2394-2405`

**Interfaces:**
- Consumes: Flutter's `AutomaticKeepAliveClientMixin`, `IndexedStack`
- Produces: Persistent tab states in `TabBarView` and `AdminShell`

- [ ] **Step 1: Update AdminShell body to IndexedStack**

In `frontend/localtrade_app/lib/features/admin/admin_shell.dart`, replace `AnimatedSwitcher` with `IndexedStack`:
```dart
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                AdminDashboard(
                  key: _dashboardKey,
                  onTabChanged: (tabIndex) {
                    setState(() {
                      _selectedIndex = 0;
                      _activeNavIndex = tabIndex;
                    });
                  },
                ),
                const AdminProfileScreen(key: ValueKey('admin_profile')),
              ],
            ),
          ),
```

- [ ] **Step 2: Add AutomaticKeepAliveClientMixin to tab states in admin_dashboard.dart**

Add `with AutomaticKeepAliveClientMixin` to:
1. `_AdminUsersTabState`
2. `_AdminVendorsTabState`
3. `_AdminProductsTabState`
4. `_AdminOrdersTabState`

For each, implement:
```dart
  @override
  bool get wantKeepAlive => true;
```
and call `super.build(context);` as the first line of `build()`.

- [ ] **Step 3: Run flutter analyze to verify syntax**

Run: `cd frontend/localtrade_app && flutter analyze`
Expected: 0 errors

- [ ] **Step 4: Commit**

```bash
git add frontend/localtrade_app/lib/features/admin/admin_shell.dart frontend/localtrade_app/lib/features/admin/admin_dashboard.dart
git commit -m "fix(admin): preserve tab states and search inputs across navigation"
```

---

### Task 2: Active Search Indicator & Users Tab Search Fix

**Files:**
- Modify: `frontend/localtrade_app/lib/features/admin/admin_dashboard.dart:1221-1370`

**Interfaces:**
- Consumes: `AdminProvider`, `AppColors`, `AppTextStyles`, `EmptyState`
- Produces: `_buildActiveSearchBanner`, working `_clearSearch` and search empty states in `AdminUsersTab`

- [ ] **Step 1: Add reusable `_buildActiveSearchBanner` helper widget**

In `admin_dashboard.dart`, add:
```dart
Widget _buildActiveSearchBanner({
  required String query,
  required int count,
  required VoidCallback onClear,
}) {
  return Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.divider),
    ),
    child: Row(
      children: [
        const Icon(Icons.search_rounded, size: 16, color: AppColors.coral),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Results for "$query" • $count found',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onClear,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.coralLight,
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close_rounded, size: 12, color: AppColors.coralDark),
                SizedBox(width: 4),
                Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.coralDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Implement `_clearSearch` and fix empty states in `_AdminUsersTabState`**

In `_AdminUsersTabState`:
```dart
  void _clearSearch(AdminProvider provider) {
    _debounce?.cancel();
    _searchController.clear();
    FocusScope.of(context).unfocus();
    provider.fetchUsers();
  }
```

Update list building:
```dart
            // Active search banner
            if (_searchController.text.trim().isNotEmpty && provider.users.isNotEmpty)
              _buildActiveSearchBanner(
                query: _searchController.text.trim(),
                count: provider.users.length,
                onClear: () => _clearSearch(provider),
              ),

            // List
            if (provider.users.isEmpty)
              Expanded(
                child: _searchController.text.isNotEmpty
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No customers found',
                        message: 'No customers match "${_searchController.text}". Check your spelling or try another term.',
                        actionLabel: 'Clear search',
                        onAction: () => _clearSearch(provider),
                      )
                    : EmptyState(
                        icon: Icons.people_outline_rounded,
                        title: 'No customers',
                        message: 'No customers registered yet.',
                        actionLabel: 'Refresh',
                        onAction: () => provider.fetchUsers(),
                      ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.fetchUsers,
                  color: AppColors.coral,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 80),
                    itemCount: provider.users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 56, endIndent: 14),
                    itemBuilder: (context, index) {
                      ...
```

- [ ] **Step 3: Run flutter analyze to verify syntax**

Run: `cd frontend/localtrade_app && flutter analyze`
Expected: 0 errors

- [ ] **Step 4: Commit**

```bash
git add frontend/localtrade_app/lib/features/admin/admin_dashboard.dart
git commit -m "fix(admin): fix users search empty state and add active query indicator"
```

---

### Task 3: Vendors Tab Search UX & Empty State

**Files:**
- Modify: `frontend/localtrade_app/lib/features/admin/admin_dashboard.dart:1550-1740`

**Interfaces:**
- Consumes: `_buildActiveSearchBanner`, `AdminProvider`
- Produces: `_clearSearch` and search empty states in `AdminVendorsTab`

- [ ] **Step 1: Implement `_clearSearch` and active search banner in `_AdminVendorsTabState`**

In `_AdminVendorsTabState`:
```dart
  void _clearSearch(AdminProvider provider) {
    _debounce?.cancel();
    _searchController.clear();
    FocusScope.of(context).unfocus();
    provider.fetchVendors(
      status: _selectedStatus == 'All' ? null : _selectedStatus,
    );
  }
```

Update list building and empty state in `_AdminVendorsTabState`:
```dart
            // Active search banner
            if (_searchController.text.trim().isNotEmpty && (filteredList.isNotEmpty || pendingVendors.isNotEmpty))
              _buildActiveSearchBanner(
                query: _searchController.text.trim(),
                count: filteredList.length + (_selectedStatus == 'All' || _selectedStatus == 'Pending' ? pendingVendors.length : 0),
                onClear: () => _clearSearch(provider),
              ),

            // List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchVendors(
                  search: _searchController.text.isEmpty ? null : _searchController.text,
                  status: _selectedStatus == 'All' ? null : _selectedStatus,
                ),
                color: AppColors.coral,
                child: filteredList.isEmpty && (_selectedStatus == 'All' ? pendingVendors.isEmpty : true)
                    ? (_searchController.text.isNotEmpty
                        ? EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No vendors found',
                            message: 'No vendors match "${_searchController.text}". Check your spelling or try another term.',
                            actionLabel: 'Clear search',
                            onAction: () => _clearSearch(provider),
                          )
                        : EmptyState(
                            icon: Icons.storefront_outlined,
                            title: 'No vendors',
                            message: 'No ${_selectedStatus == 'All' ? '' : '$_selectedStatus '}vendors found.',
                            actionLabel: 'Refresh',
                            onAction: () => provider.fetchVendors(status: _selectedStatus == 'All' ? null : _selectedStatus),
                          ))
                    : _buildVendorListView(pendingVendors, filteredList, context, provider),
              ),
            ),
```

- [ ] **Step 2: Run flutter analyze to verify syntax**

Run: `cd frontend/localtrade_app && flutter analyze`
Expected: 0 errors

- [ ] **Step 3: Commit**

```bash
git add frontend/localtrade_app/lib/features/admin/admin_dashboard.dart
git commit -m "fix(admin): improve vendor search empty state and query banner"
```

---

### Task 4: Products Tab Search UX & Empty State

**Files:**
- Modify: `frontend/localtrade_app/lib/features/admin/admin_dashboard.dart:2057-2200`

**Interfaces:**
- Consumes: `_buildActiveSearchBanner`, `AdminProvider`
- Produces: `_clearSearch` and search empty states in `AdminProductsTab`

- [ ] **Step 1: Implement `_clearSearch` and active search banner in `_AdminProductsTabState`**

In `_AdminProductsTabState`:
```dart
  void _clearSearch(AdminProvider provider) {
    _debounce?.cancel();
    _searchController.clear();
    FocusScope.of(context).unfocus();
    provider.fetchProducts();
  }
```

Update list building and empty state in `_AdminProductsTabState`:
```dart
            // Active search banner
            if (_searchController.text.trim().isNotEmpty && provider.products.isNotEmpty)
              _buildActiveSearchBanner(
                query: _searchController.text.trim(),
                count: provider.products.length,
                onClear: () => _clearSearch(provider),
              ),

            // List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchProducts(
                  search: _searchController.text.isEmpty ? null : _searchController.text,
                ),
                color: AppColors.coral,
                child: provider.products.isEmpty
                    ? (_searchController.text.isNotEmpty
                        ? EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No products found',
                            message: 'No products match "${_searchController.text}". Check your spelling or try another term.',
                            actionLabel: 'Clear search',
                            onAction: () => _clearSearch(provider),
                          )
                        : ListView(
                            children: [
                              EmptyState(
                                icon: Icons.inventory_2_outlined,
                                title: 'No products',
                                message: 'No products listed yet.',
                                actionLabel: 'Refresh',
                                onAction: () => provider.fetchProducts(),
                              ),
                            ],
                          ))
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 80),
                        itemCount: provider.products.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 68, endIndent: 14),
                        itemBuilder: (context, index) {
                          ...
```

- [ ] **Step 2: Run flutter analyze to verify syntax**

Run: `cd frontend/localtrade_app && flutter analyze`
Expected: 0 errors

- [ ] **Step 3: Commit**

```bash
git add frontend/localtrade_app/lib/features/admin/admin_dashboard.dart
git commit -m "fix(admin): improve product search empty state and query banner"
```

---

### Task 5: Verification & Full Analysis

**Files:**
- Test all modifications across `frontend/localtrade_app`

- [ ] **Step 1: Run flutter analyze**

Run: `cd frontend/localtrade_app && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: Run flutter tests if available**

Run: `cd frontend/localtrade_app && flutter test`
Expected: All tests pass

- [ ] **Step 3: Run backend tests to ensure no regressions**

Run: `cd backend && npm test`
Expected: All 16 backend tests pass
