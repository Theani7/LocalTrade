# LocalTrade Design Language

## Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#FBF5EA` | Cream screen background |
| `surface` | `#FFFFFF` | Card backgrounds |
| `ink` | `#2B2620` | Primary text, icon on coral buttons |
| `muted` | `#6E6557` | Secondary text, inactive icons |
| `mutedLight` | `#F1E9DA` | Light backgrounds, badges |
| `coral` | `#FF6F52` | Button fills, active accents |
| `coralLight` | `#FCE0D6` | Chip/badge fills |
| `coralDark` | `#9A3318` | Active nav icons, text on coral-light |
| `blue` | `#2F6FED` | Charts, data |
| `blueLight` | `#DEE9FE` | Blue chip fills |
| `blueDark` | `#1A3E8C` | Text on blue-light |
| `success` | `#3B8C5A` | Success states |
| `successLight` | `#E0F2E6` | Success chip fills |
| `successDark` | `#1F5C38` | Text on success-light |
| `warning` | `#D9A441` | Warning states |
| `warningLight` | `#FBEEDA` | Warning chip fills |
| `warningDark` | `#8A5F18` | Text on warning-light |
| `danger` | `#D32F2F` | Permanent delete only |
| `dangerLight` | `#FCE0D6` | Danger chip fills |
| `dangerDark` | `#9A3318` | Text on danger-light |
| `divider` | `#F1E9DA` | Borders, dividers |

## Typography
- **Screen title**: `AppTextStyles.screenTitle` — 18px, medium (w500), ink
- **Card title**: `AppTextStyles.cardTitle` — 14-15px, medium (w500), ink
- **Section heading**: `AppTextStyles.sectionHeading` — 16px, medium (w500), ink
- **Body**: `AppTextStyles.body` — 14px, regular (w400), ink
- **Body muted**: `AppTextStyles.bodyMuted` — 14px, regular (w400), muted
- **Label**: `AppTextStyles.label` — 12px, medium (w500), ink
- **Caption**: `AppTextStyles.caption` — 12px, regular (w400), muted
- **Price**: `AppTextStyles.price` — 16px, medium (w500), coral
- **Never bold (w700)** — only regular and medium weights
- **Sentence case** — never title case

## Spacing
- Screen horizontal padding: `16px`
- Card padding: `14-18px`
- Gap between sections: `24px`
- Gap between cards: `12px`
- Touch target minimum: `44px`
- Button height: `48-52px`
- Border radius: `8px` (sm), `12px` (md), `16px` (lg), `24px` (hero)

## Cards
- White background, `16px` radius
- Soft shadow: `0 2px 10px rgba(43,38,32,0.08)`
- No hard borders, only `divider` color when needed

## Buttons
- **Primary**: coral fill, ink text, 14px radius, full width, 14px vertical padding
- **Secondary/outline**: white fill, ink text, divider border
- **Destructive**: danger fill, white text (only for permanent delete)

## Headers
- Title: `AppTextStyles.screenTitle` (18px medium)
- Subtitle: `AppTextStyles.caption` (12px muted)
- Padding: `EdgeInsets.fromLTRB(16, 12, 16, 14)`
- Optional action buttons: 36px white containers with icon

## Status Badges
- Light fill + dark text pattern (never saturated fill with white text)
- Pending: warningLight/warningDark
- Confirmed: blueLight/blueDark
- Delivered: successLight/successDark
- Cancelled: coralLight/coralDark

## Bottom Navigation
- Active: coralDark icon (#9A3318) + 4px dot indicator + coralDark medium label
- Inactive: #B9AF9A icon + muted label
- Labels: 10px
- Cart badge: coral fill circle with ink text count

## Empty States
- Icon in white card or coral-light circle
- Title: 18px ink medium, centered
- Subtext: 13-14px muted, line-height 1.5
- CTA: coral fill button below

## Animations
- Micro: 150-250ms
- Page transitions: 250-300ms easeInOut
- Loading/feedback: 300-400ms
- Never >400ms
- Respect `MediaQuery.disableAnimations`

## Rules
- No emojis in UI code — use Material Icons
- Coral button text is always ink (dark), never white
- Danger red only for permanent delete
- Reversible negative actions use outline buttons
- High contrast for elderly/non-technical users
- All text uses `AppTextStyles` tokens, never raw `TextStyle`
- All colors use `AppColors` tokens, never raw hex values
