# Admin Search UX Improvement Specification

## 1. Overview
When administrators search for users (customers), vendors, or products in the LocalTrade Admin Dashboard, there are UX issues:
1. In `AdminUsersTab`, a copy-paste bug causes empty search results to always display "No customers registered yet." without indicating what query was searched or showing any search empty state.
2. In all three tabs (`AdminUsersTab`, `AdminVendorsTab`, `AdminProductsTab`), when 0 results match a search query, the `EmptyState` widget is shown without an action button (`actionLabel` / `onAction`), leaving the admin with no obvious button to clear the search.
3. When searching with results returned, there is no active search pill / banner showing what search term is applied and how many matches were found.
4. **State Loss on Navigation**: When switching between tabs in `TabBarView` or navigating to Profile / detail screens, tab state was destroyed because `AutomaticKeepAliveClientMixin` was missing on tab states and `AdminShell` was destroying `AdminDashboard` via `AnimatedSwitcher` instead of preserving it with `IndexedStack`. This resulted in `_searchController` resetting to `""` while `AdminProvider` retained filtered/empty data, showing an unexpected "No items registered/listed yet" empty state upon returning.

## 2. Goals
- Provide clear visual indicators whenever a search query is active in Users, Vendors, and Products tabs.
- Provide multiple one-tap ways to clear / reset active searches:
  - Inside the search text field via suffix clear `(X)` icon.
  - In an active search pill banner above the list with result count and quick-clear chip.
  - In the empty state via a primary `Clear search` button.
- Fix all logic errors and copy-paste bugs in `admin_dashboard.dart`.
- Preserve tab state, search queries, and scroll positions across navigation by:
  - Adding `AutomaticKeepAliveClientMixin` to all `AdminDashboard` tab states (`_AdminUsersTabState`, `_AdminVendorsTabState`, `_AdminProductsTabState`, `_AdminOrdersTabState`).
  - Using `IndexedStack` in `AdminShell` to prevent rebuilding and discarding `AdminDashboard` state when visiting Profile.
- Maintain strict compliance with LocalTrade Design System guidelines (Inter font, 400/500 weights, Cream `#FBF5EA`, Coral `#FF6F52`, Ink `#2B2620`, Muted `#6E6557`).

## 3. Detailed Component & Tab Specifications

### 3.1 AdminUsersTab (`_AdminUsersTabState`)
- **KeepAlive**: Mix in `AutomaticKeepAliveClientMixin`, implement `wantKeepAlive => true`, call `super.build(context)`.
- **Fix Empty / List Condition**:
  - Replace the current broken `if (provider.users.isEmpty)` and nested `provider.products.isEmpty` logic with a proper state check:
    - If `provider.users.isEmpty && _searchController.text.isNotEmpty`:
      - Show `EmptyState` with:
        - `icon: Icons.search_off_rounded`
        - `title: 'No customers found'`
        - `message: 'No customers match "${_searchController.text}". Check your spelling or try another term.'`
        - `actionLabel: 'Clear search'`
        - `onAction: () => _clearSearch(provider)`
    - Else if `provider.users.isEmpty`:
      - Show `EmptyState` with:
        - `icon: Icons.people_outline_rounded`
        - `title: 'No customers'`
        - `message: 'No customers registered yet.'`
        - `actionLabel: 'Refresh'`
        - `onAction: () => provider.fetchUsers()`
    - Else:
      - Render active search banner if query is active, followed by the user list.
- **Active Search Indicator**:
  - When `_searchController.text.trim().isNotEmpty` and `provider.users.isNotEmpty`:
    - Show an active search query banner above the list:
      - Text: `Searching for "${_searchController.text}" • ${provider.users.length} found`
      - Trailing chip / button: `Clear` with `Icons.close_rounded`
- **Search Actions**:
  - `_clearSearch(AdminProvider provider)`:
    - `_debounce?.cancel();`
    - `_searchController.clear();`
    - `FocusScope.of(context).unfocus();`
    - `provider.fetchUsers();`

### 3.2 AdminVendorsTab (`_AdminVendorsTabState`)
- **KeepAlive**: Mix in `AutomaticKeepAliveClientMixin`, implement `wantKeepAlive => true`, call `super.build(context)`.
- **Fix Empty / List Condition**:
  - When `filteredList.isEmpty && (_selectedStatus == 'All' ? pendingVendors.isEmpty : true)`:
    - If `_searchController.text.isNotEmpty`:
      - Show `EmptyState` with:
        - `icon: Icons.search_off_rounded`
        - `title: 'No vendors found'`
        - `message: 'No vendors match "${_searchController.text}". Check your spelling or try another term.'`
        - `actionLabel: 'Clear search'`
        - `onAction: () => _clearSearch(provider)`
    - Else:
      - Show `EmptyState` with:
        - `icon: Icons.storefront_outlined`
        - `title: 'No vendors'`
        - `message: 'No ${_selectedStatus == 'All' ? '' : '$_selectedStatus '}vendors found.'`
        - `actionLabel: 'Refresh'`
        - `onAction: () => provider.fetchVendors(status: _selectedStatus == 'All' ? null : _selectedStatus)`
- **Active Search Indicator**:
  - When `_searchController.text.trim().isNotEmpty` and list is not empty:
    - Show active query banner: `Searching for "${_searchController.text}" • ${totalCount} found` with a `Clear` button.
- **Search Actions**:
  - `_clearSearch(AdminProvider provider)`:
    - `_debounce?.cancel();`
    - `_searchController.clear();`
    - `FocusScope.of(context).unfocus();`
    - `provider.fetchVendors(status: _selectedStatus == 'All' ? null : _selectedStatus);`

### 3.3 AdminProductsTab (`_AdminProductsTabState`)
- **KeepAlive**: Mix in `AutomaticKeepAliveClientMixin`, implement `wantKeepAlive => true`, call `super.build(context)`.
- **Fix Empty / List Condition**:
  - When `provider.products.isEmpty`:
    - If `_searchController.text.isNotEmpty`:
      - Show `EmptyState` with:
        - `icon: Icons.search_off_rounded`
        - `title: 'No products found'`
        - `message: 'No products match "${_searchController.text}". Check your spelling or try another term.'`
        - `actionLabel: 'Clear search'`
        - `onAction: () => _clearSearch(provider)`
    - Else:
      - Show `EmptyState` with:
        - `icon: Icons.inventory_2_outlined`
        - `title: 'No products'`
        - `message: 'No products listed yet.'`
        - `actionLabel: 'Refresh'`
        - `onAction: () => provider.fetchProducts()`
- **Active Search Indicator**:
  - When `_searchController.text.trim().isNotEmpty` and `provider.products.isNotEmpty`:
    - Show active query banner: `Searching for "${_searchController.text}" • ${provider.products.length} found` with a `Clear` button.
- **Search Actions**:
  - `_clearSearch(AdminProvider provider)`:
    - `_debounce?.cancel();`
    - `_searchController.clear();`
    - `FocusScope.of(context).unfocus();`
    - `provider.fetchProducts();`

### 3.4 AdminShell & Tab State Preservation
- In `AdminShell`, use `IndexedStack` instead of destroying `AdminDashboard` when toggling between Dashboard and Profile tabs.
- Ensure all 4 stateful tabs (`AdminUsersTab`, `AdminVendorsTab`, `AdminProductsTab`, `AdminOrdersTab`) mix in `AutomaticKeepAliveClientMixin` with `wantKeepAlive => true` so that scrolling and search inputs are not discarded when switching between tabs in the `TabBarView`.

### 3.5 Reusable Active Search Banner Widget
Create a compact helper widget in `admin_dashboard.dart`:
```dart
Widget _buildActiveSearchBanner({
  required String query,
  required int count,
  required VoidCallback onClear,
})
```
Features:
- Soft background (`AppColors.surface`), rounded corners (10px), subtle border (`AppColors.divider`).
- Left: `Icons.search_rounded` (16px, `AppColors.coral`), query text with ellipsis, dot separator, count label.
- Right: Tappable clear button / chip (44px min touch target) with `Icons.close_rounded` (14px).

## 4. Verification Plan
1. **Static Analysis**:
   - Run `flutter analyze` inside `frontend/localtrade_app` and verify 0 errors / 0 warnings.
2. **Tab Verification**:
   - Search for "abc" in Vendors tab (0 results -> shows empty state with query + `Clear search` button).
   - Switch to Products tab or Profile tab and switch back -> state is preserved, `_searchController.text` is still "abc" and not cleared/corrupted.
   - Tap `Clear search` -> resets search query and reloads all vendors.
   - Repeat for Users tab and Products tab.
