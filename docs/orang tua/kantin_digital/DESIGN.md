---
name: Kantin Digital
colors:
  surface: '#fbf9f8'
  surface-dim: '#dcd9d9'
  surface-bright: '#fbf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f2'
  surface-container: '#f0eded'
  surface-container-high: '#eae8e7'
  surface-container-highest: '#e4e2e1'
  on-surface: '#1b1c1c'
  on-surface-variant: '#3d4949'
  inverse-surface: '#303030'
  inverse-on-surface: '#f3f0f0'
  outline: '#6d7979'
  outline-variant: '#bdc9c8'
  surface-tint: '#006a6a'
  primary: '#006767'
  on-primary: '#ffffff'
  primary-container: '#008282'
  on-primary-container: '#f3fffe'
  inverse-primary: '#72d6d6'
  secondary: '#904d00'
  on-secondary: '#ffffff'
  secondary-container: '#ffa454'
  on-secondary-container: '#713b00'
  tertiary: '#006a35'
  on-tertiary: '#ffffff'
  tertiary-container: '#008645'
  on-tertiary-container: '#f6fff4'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#8ff3f2'
  primary-fixed-dim: '#72d6d6'
  on-primary-fixed: '#002020'
  on-primary-fixed-variant: '#004f50'
  secondary-fixed: '#ffdcc3'
  secondary-fixed-dim: '#ffb77d'
  on-secondary-fixed: '#2f1500'
  on-secondary-fixed-variant: '#6e3900'
  tertiary-fixed: '#7efba4'
  tertiary-fixed-dim: '#61de8a'
  on-tertiary-fixed: '#00210c'
  on-tertiary-fixed-variant: '#005228'
  background: '#fbf9f8'
  on-background: '#1b1c1c'
  surface-variant: '#e4e2e1'
typography:
  headline-xl:
    fontFamily: Be Vietnam Pro
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Be Vietnam Pro
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
  headline-md:
    fontFamily: Be Vietnam Pro
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-md:
    fontFamily: Be Vietnam Pro
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Be Vietnam Pro
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  label-md:
    fontFamily: Be Vietnam Pro
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
  button:
    fontFamily: Be Vietnam Pro
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 40px
  container-max: 1200px
  gutter: 24px
---

## Brand & Style
The design system is anchored in trust, efficiency, and approachability, specifically tailored for the "Kantin Digital" school ecosystem. The brand personality balances the warmth of a school environment with the rigor of a financial platform. It serves a dual audience: parents who need a reliable, high-integrity interface for managing funds, and students who require a fast, intuitive experience for daily transactions.

The design style is **Corporate Modern with a Soft Edge**. It utilizes clean, systematic layouts and professional proportions, but softens the industrial feel through generous whitespace and a "friendly-utility" aesthetic. The emotional response should be one of confidence and calm—ensuring parents feel their children's nutrition and finances are in safe, organized hands.

## Colors
This design system uses a palette that signals both health and financial security. 

- **Primary (Teal):** Used for core navigation, primary actions, and brand headers. It represents stability and health.
- **Accent (Orange):** Reserved specifically for high-value financial actions, such as "Top-up" or "Recharge Balance," to ensure high visibility without overwhelming the professional tone.
- **Success (Green):** Integrated for confirmed transactions and balanced funding states.
- **Neutral (Deep Charcoal):** Applied to all primary text to ensure maximum legibility and contrast against the light gray background.
- **Surface:** A very light gray background is used to reduce eye strain and provide a soft canvas for pure white cards.

## Typography
The system utilizes **Be Vietnam Pro** (selected as the closest high-quality match for the requested friendly, contemporary feel) to maintain a modern and highly readable experience. 

- **Hierarchy:** Bold weights are reserved for page titles and critical financial figures (like balance amounts). Medium weights are used for sub-headers and labels to maintain a structured information density.
- **Scalability:** Headline sizes are aggressively reduced for mobile to ensure "Card" layouts remain the focal point without being pushed off-screen by large text.
- **Readability:** Line heights are set generously (1.5x - 1.6x) for body text to assist parents in quickly scanning transaction logs and canteen menus.

## Layout & Spacing
The layout follows a **Fixed Grid** model on desktop to keep financial data centered and focused, transitioning to a **Fluid Grid** on mobile devices.

- **Grid System:** A 12-column grid is used for desktop (1200px max-width). For child profile dashboards, a 3-column card layout is standard.
- **Mobile Adaptivity:** On mobile, margins reduce to 16px. Cards stack vertically, and horizontal scrolling is permitted only for "Quick Action" chips or secondary navigation categories.
- **Spacing Rhythm:** An 8px linear scale is used. Generous internal padding (24px) is applied to all container cards to reinforce the "friendly and airy" brand promise.

## Elevation & Depth
Depth is created through **Tonal Layering and Soft Ambient Shadows**. The background stays flat at `#F8F9FA`, while interactive elements and content containers are raised.

- **Level 0 (Flat):** Main background and inactive input fields.
- **Level 1 (Low Rise):** Main content cards. These use a very soft, diffused shadow (0px 4px 20px, 5% opacity black) and a 1px subtle border (#E9ECEF) to define edges without adding visual noise.
- **Level 2 (Hover/Active):** Floating Action Buttons (FABs) or hovered cards. The shadow becomes more pronounced (0px 8px 30px, 10% opacity) to signify interactivity.
- **Depth Masking:** When modals are triggered for "Top-up" confirmations, a soft 40% opacity charcoal overlay is used to focus the user on the transaction.

## Shapes
The shape language is defined by **Rounded (0.5rem / 8px base)** geometry. This specific radius communicates modern software standards while feeling more "human" and less rigid than sharp corners.

- **Large Components:** Main dashboard cards and profile containers utilize `rounded-xl` (1.5rem / 24px) to create a friendly, approachable frame.
- **Interactive Elements:** Buttons and input fields use `rounded-lg` (1rem / 16px) to provide a "pill-like" comfort, making the touch targets feel inviting.
- **Icons:** Should be housed in circular or soft-square backgrounds to maintain the theme.

## Components
- **Buttons:**
    - **Primary:** Solid Teal with white text for main flow (e.g., "Confirm Order").
    - **Accent:** Solid Orange for "Top-up" actions only.
    - **Secondary:** Outlined Teal for "View Details" or "Download Receipt."
- **Input Fields:** Pure white background with a 1px stroke (#CED4DA). Labels are placed outside the field in `label-md` (SemiBold). Focus states use a Teal 2px border.
- **Cards (Child Profiles):** Pure white background. Includes a circular avatar, the student’s name in `title-md`, and a prominent balance display using the Accent color.
- **Transaction Tables:** Minimalist design with no vertical lines. Only horizontal dividers (#E9ECEF). The header row uses a light Teal tint (5% opacity) to distinguish it from the data.
- **Success States:** Full-screen or modal-based. Features a large Green checkmark icon within a circular container, followed by a Teal primary button to "Return to Dashboard."
- **Chips:** Used for filtering transaction types (e.g., "Food," "Drinks," "Top-up"). Active chips use a solid Teal background; inactive chips use a Light Gray background.