# LocalTrade design system (revised)

This is the design direction I'd actually ship: the original cream/coral/blue palette, corrected for accessibility, with role-aware tone and a more deliberate component system. Use this as the standing reference for every screen built for LocalTrade.

## Project context
LocalTrade is a Flutter-based community marketplace connecting Nepal's micro and small vendors with local customers across Android, iOS, and web. The model is browse-and-reserve, not full checkout. Three roles: customer (discovery), vendor (operations), super admin (governance). The explicit audience includes non-technical and elderly users, so legibility and contrast are requirements, not nice-to-haves.

## What changed from the first draft and why
- White text on coral buttons measured 2.75:1 contrast, fails WCAG AA even for large text. Fixed by using dark ink text on coral fills instead.
- Muted secondary text measured 3.4-3.7:1, fails for body-size text. Darkened from `#8C8478` to `#6E6557`.
- Status badges previously relied on solid color fills. Switched every badge to a light-fill plus dark-text pairing (the same pattern already used for the coral banner), which passes contrast with a wide safety margin instead of sitting right at the edge.
- Added a dedicated danger color, separate from coral, so "delete" doesn't visually compete with or get confused with the primary action color.
- Split tone and layout density by role instead of applying one energetic voice everywhere, admin and vendor screens are workspaces, not a motivational feed.

## Color system

| Role | Hex | Usage | Verified contrast |
|---|---|---|---|
| Background (cream) | `#FBF5EA` | Screen background only | - |
| Card surface | `#FFFFFF` | Card backgrounds | - |
| Ink (primary text) | `#2B2620` | Body text, headings, button text on coral | 13.8:1 on cream, 15:1 on white |
| Muted (secondary text) | `#6E6557` | Labels, captions, timestamps | 4.6:1 on cream, 4.9:1 on white |
| Coral (primary action fill) | `#FF6F52` | Button fills only, pair with ink text, never as standalone text/icon color on cream | 5.5:1 with ink text |
| Coral light | `#FCE0D6` | Badge/chip/banner fills | - |
| Coral dark | `#9A3318` | Text on coral-light | 5.9:1 |
| Electric blue | `#2F6FED` | Charts and data visuals only, not buttons or badges | - |
| Blue light | `#DEE9FE` | Badge/chip fills for info/confirmed states | - |
| Blue dark | `#1A3E8C` | Text on blue-light | passes by construction |
| Success green | `#3B8C5A` | Reserved for delivered/confirmed icons | - |
| Success light / dark | `#E0F2E6` / `#1F5C38` | Delivered status badge fill/text | passes by construction |
| Warning amber | `#D9A441` | Reserved for pending icons | - |
| Warning light / dark | `#FBEEDA` / `#8A5F18` | Pending status badge fill/text | passes by construction |
| Danger red | `#D32F2F` | Delete/irreversible actions only, white text | 5.0:1 with white text |
| Divider | `#F1E9DA` | Hairline separators | - |

Rules:
- Coral fills always pair with ink text, never white. This is the single most important fix from the first draft.
- Never use coral as standalone text or an icon color directly on cream, it fails contrast outright. Coral lives inside fills, badges, and tinted circles, not as bare text.
- All badges, chips, and tags use the light-fill plus dark-text pattern, never a saturated fill with white text. This makes contrast a non-issue by construction instead of something to check per-instance.
- Danger red is reserved for genuinely destructive, hard-to-undo actions (permanent delete). Reversible admin actions like suspend or reject use a neutral outline button (ink border, ink text), not red, so red keeps its meaning as "this can't be undone."

## Typography
- Use a humanist sans rather than a strictly geometric one, Inter or Noto Sans both work well. Noto Sans is worth considering specifically because it has full Devanagari support, useful if Nepali-language UI is ever added for vendors who are more comfortable reading Nepali than English.
- Two weights only: regular (400) body, medium (500) headings and values.
- Sentence case throughout.
- Scale: screen titles 19-22px, product/vendor names 15-16px, prices 18-20px medium, body 13-14px, labels/captions 12px minimum, never smaller, given the elderly-user requirement.

## Layout and spacing
- Rounded cards, 16px radius standard, 24px for hero/feature cards.
- Soft shadows only: `0 2px 10px rgba(43,38,32,0.05)`.
- Minimum 44x44px touch targets everywhere, larger (52px) for primary actions like "reserve" or "approve."
- Card padding 12-18px, gaps 10-14px.

## Tone and voice by role
- **Customer**: warm, present tense, community-oriented. "Discover what's fresh near you today." Bottom tab navigation, larger imagery, more visual warmth.
- **Vendor**: clear and supportive, practical rather than cheerful. "Your orders for today" rather than exclamation-heavy copy. Side nav or top tabs, data presented plainly.
- **Admin**: neutral and precise, operational. "3 vendors awaiting approval." No motivational banners, no playful copy, this is a governance workspace.

## Component patterns

**Primary button**: coral fill, ink text, 16px radius, 52px height for key actions (reserve, approve).
**Secondary button**: white fill, ink border, ink text.
**Destructive button**: red fill, white text, used only for permanent delete.
**Reversible negative action** (suspend, reject): outline button, ink border and text, no red.

**Status badge**: light-tint fill, dark-tint text from the same ramp, plus an icon, never color alone.
- Pending: warning-light fill, warning-dark text, clock icon.
- Confirmed: blue-light fill, blue-dark text, check icon.
- Delivered: success-light fill, success-dark text, checkmark-circle icon.

**Product card**: image, product name (ink), vendor name (muted), price (ink, medium), coral reserve button with ink text.
**Vendor card**: photo or initials, name, category chip (coral-light fill, coral-dark text), location in muted text.
**Dashboard stat card** (vendor/admin): tinted icon circle, value in ink, label in muted, no motivational framing, just the number.
**Analytics chart**: electric blue, white card background, current period only highlighted if relevant, no decorative color beyond that.
**Approval row** (admin): name, status badge, coral approve button, outline reject button (not red).

## Accessibility checklist
- Every text/background pairing in this document has been checked against WCAG AA (4.5:1 normal text, 3:1 large text and icons).
- Status is always communicated by color, icon, and label together, never color alone, for colorblind users.
- Minimum touch target 44x44px, 52px for primary actions.
- Caption/label text never goes below 12px.
- If Nepali localization is added, verify the chosen typeface renders Devanagari cleanly at the same size scale before shipping.
