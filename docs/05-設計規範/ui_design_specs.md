# UI/UX Design System: "Together" App

## 1. Design Philosophy
- **Style Reference**: Similar to **GoShare** or **Uber**.
- **Core Concept**: "Map as Home". No traditional list view as the landing page.
- **Visuals**: Clean, Minimalist, Rounded corners (20px+).

## 2. Color Palette
- **Primary**: `Color(0xFF00D0DD)` (Cyan/Teal) - Used for primary buttons, active states, and user location.
- **Surface**: `Colors.white` - Used for bottom sheets and markers.
- **Text**: `Color(0xFF2D3436)` (Dark Grey).
- **Marker**:
  - Available: White background with Primary color border.
  - Full: Grey background.

## 3. Key Components
### A. Custom Map Marker (The "Capsule")
- **Shape**: Stadium/Capsule shape (not a standard pin).
- **Content**:
  - Left: Icon (Category or Generic).
  - Center: Activity Title (Truncated if too long).
  - Right: Participant Count (e.g., "1/6").
- **Implementation Note**: Must use `widget_to_marker` to render a Flutter Widget into a BitmapDescriptor for Google Maps.

### B. Home Screen (Map)
- Full-screen Google Map.
- Top Layer: Floating search bar (Pill shape) with Profile Avatar.
- Bottom Layer:
  - "My Location" FAB.
  - "Create Activity" FAB (Large, Primary Color).

### C. Activity Detail (Bottom Sheet)
- **Behavior**: Clicking a marker opens a **Sliding Up Panel** (DraggableScrollableSheet or sliding_up_panel).
- **Content**: Title, Time, Host Info, "Join" Button (Sticky at bottom).