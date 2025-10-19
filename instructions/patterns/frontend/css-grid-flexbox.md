# CSS Grid & Flexbox Advanced Layout Guide

## CSS Grid Complete Implementation

### Advanced Grid Template Areas
```css
/* Complex dashboard layout with named areas */
.dashboard {
  display: grid;
  grid-template-areas:
    "header header header header"
    "sidebar main main widgets"
    "sidebar main main widgets"
    "sidebar footer footer footer";
  grid-template-columns: 250px 1fr 1fr 300px;
  grid-template-rows: 80px 1fr 1fr 60px;
  gap: 1rem;
  height: 100vh;
}

.header {
  grid-area: header;
  background: #2c3e50;
  color: white;
  display: flex;
  align-items: center;
  padding: 0 2rem;
}

.sidebar {
  grid-area: sidebar;
  background: #34495e;
  color: white;
  overflow-y: auto;
}

.main {
  grid-area: main;
  background: white;
  overflow-y: auto;
  padding: 2rem;
}

.widgets {
  grid-area: widgets;
  background: #ecf0f1;
  overflow-y: auto;
  padding: 1rem;
}

.footer {
  grid-area: footer;
  background: #2c3e50;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Responsive grid areas */
@media (max-width: 1200px) {
  .dashboard {
    grid-template-areas:
      "header header header"
      "sidebar main main"
      "sidebar main main"
      "widgets widgets widgets"
      "footer footer footer";
    grid-template-columns: 200px 1fr 1fr;
    grid-template-rows: 80px 1fr 1fr auto 60px;
  }
}

@media (max-width: 768px) {
  .dashboard {
    grid-template-areas:
      "header"
      "main"
      "widgets"
      "sidebar"
      "footer";
    grid-template-columns: 1fr;
    grid-template-rows: 80px 1fr auto auto 60px;
  }
}
```

### CSS Subgrid Implementation
```css
/* Subgrid for aligned nested content */
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
}

.card {
  display: grid;
  grid-template-rows: subgrid;
  grid-row: span 3;
  border: 1px solid #ddd;
  border-radius: 8px;
  overflow: hidden;
}

.card-header {
  grid-row: 1;
  padding: 1rem;
  background: #f5f5f5;
}

.card-body {
  grid-row: 2;
  padding: 1rem;
  flex: 1;
}

.card-footer {
  grid-row: 3;
  padding: 1rem;
  background: #f5f5f5;
  border-top: 1px solid #ddd;
}

/* Alternative: container subgrid */
.form-grid {
  display: grid;
  grid-template-columns: max-content 1fr;
  gap: 1rem;
}

.form-section {
  display: grid;
  grid-column: 1 / -1;
  grid-template-columns: subgrid;
  gap: inherit;
}

.form-label {
  grid-column: 1;
  text-align: right;
  padding-right: 1rem;
}

.form-input {
  grid-column: 2;
}
```

### Masonry Layout with Grid
```css
/* Pure CSS Masonry (Firefox only with grid-template-rows: masonry) */
.masonry-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  grid-template-rows: masonry; /* Firefox only */
  gap: 1rem;
}

/* Fallback: Dense packing algorithm */
.masonry-fallback {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  grid-auto-rows: 20px;
  gap: 1rem;
}

.masonry-item {
  background: white;
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 1rem;
}

.masonry-item:nth-child(odd) {
  grid-row-end: span 10;
}

.masonry-item:nth-child(even) {
  grid-row-end: span 15;
}

.masonry-item:nth-child(3n) {
  grid-row-end: span 12;
}

/* JavaScript-enhanced masonry */
.js-masonry {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  grid-auto-rows: 10px;
  gap: 1rem;
}

.js-masonry-item {
  grid-row-end: span var(--rows);
}
```

### Complex Grid Patterns
```css
/* Magazine-style layout */
.magazine-layout {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  grid-auto-rows: minmax(100px, auto);
  gap: 1.5rem;
}

.feature-article {
  grid-column: 1 / 9;
  grid-row: 1 / 4;
  display: grid;
  grid-template-rows: 1fr auto;
}

.side-article {
  grid-column: 9 / 13;
  grid-row: 1 / 2;
}

.small-article {
  grid-column: span 4;
  grid-row: span 2;
}

.horizontal-article {
  grid-column: span 8;
  grid-row: span 1;
}

/* Bento grid layout */
.bento-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  grid-auto-rows: 120px;
  gap: 1rem;
  padding: 1rem;
}

.bento-item-large {
  grid-column: span 2;
  grid-row: span 2;
}

.bento-item-tall {
  grid-column: span 1;
  grid-row: span 2;
}

.bento-item-wide {
  grid-column: span 2;
  grid-row: span 1;
}

.bento-item-small {
  grid-column: span 1;
  grid-row: span 1;
}
```

## Flexbox Advanced Patterns

### Holy Grail Layout with Flexbox
```css
/* Classic holy grail layout */
.holy-grail {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.holy-grail-header {
  flex: 0 0 auto;
  background: #333;
  color: white;
  padding: 1rem;
}

.holy-grail-body {
  flex: 1 0 auto;
  display: flex;
}

.holy-grail-content {
  flex: 1;
  padding: 2rem;
  order: 2;
}

.holy-grail-nav {
  flex: 0 0 200px;
  order: 1;
  background: #f5f5f5;
  padding: 1rem;
}

.holy-grail-aside {
  flex: 0 0 200px;
  order: 3;
  background: #f5f5f5;
  padding: 1rem;
}

.holy-grail-footer {
  flex: 0 0 auto;
  background: #333;
  color: white;
  padding: 1rem;
}

/* Mobile responsive */
@media (max-width: 768px) {
  .holy-grail-body {
    flex-direction: column;
  }
  
  .holy-grail-nav,
  .holy-grail-aside {
    flex: 1 0 auto;
    order: initial;
  }
}
```

### Advanced Flexbox Alignment
```css
/* Equal height cards with flexbox */
.card-container {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.flex-card {
  flex: 1 1 300px;
  display: flex;
  flex-direction: column;
  border: 1px solid #ddd;
  border-radius: 8px;
  overflow: hidden;
}

.flex-card-header {
  padding: 1rem;
  background: #f5f5f5;
}

.flex-card-body {
  flex: 1;
  padding: 1rem;
}

.flex-card-footer {
  padding: 1rem;
  background: #f5f5f5;
  margin-top: auto; /* Push to bottom */
}

/* Center anything pattern */
.flex-center {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
}

/* Sidebar with flex */
.flex-layout {
  display: flex;
  min-height: 100vh;
}

.flex-sidebar {
  flex: 0 0 250px;
  background: #2c3e50;
  color: white;
  padding: 1rem;
  
  /* Sticky sidebar */
  position: sticky;
  top: 0;
  height: 100vh;
  overflow-y: auto;
}

.flex-main {
  flex: 1;
  padding: 2rem;
  min-width: 0; /* Prevent overflow */
}

/* Flex wrap with consistent spacing */
.flex-grid {
  display: flex;
  flex-wrap: wrap;
  margin: -0.5rem;
}

.flex-grid-item {
  flex: 0 0 calc(33.333% - 1rem);
  margin: 0.5rem;
}

@media (max-width: 768px) {
  .flex-grid-item {
    flex: 0 0 calc(50% - 1rem);
  }
}

@media (max-width: 480px) {
  .flex-grid-item {
    flex: 0 0 calc(100% - 1rem);
  }
}
```

### Flexbox Navigation Patterns
```css
/* Responsive navigation with flexbox */
.nav-flex {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: #333;
}

.nav-brand {
  font-size: 1.5rem;
  font-weight: bold;
  color: white;
}

.nav-menu {
  display: flex;
  gap: 2rem;
  list-style: none;
  margin: 0;
  padding: 0;
}

.nav-item {
  color: white;
  text-decoration: none;
  position: relative;
}

.nav-item:hover::after {
  content: '';
  position: absolute;
  bottom: -5px;
  left: 0;
  right: 0;
  height: 2px;
  background: #007bff;
}

.nav-actions {
  display: flex;
  gap: 1rem;
}

/* Mobile menu */
@media (max-width: 768px) {
  .nav-menu {
    position: fixed;
    top: 60px;
    left: -100%;
    width: 100%;
    height: calc(100vh - 60px);
    background: #333;
    flex-direction: column;
    padding: 2rem;
    transition: left 0.3s ease;
  }
  
  .nav-menu.active {
    left: 0;
  }
}
```

## Grid vs Flexbox Decision Matrix

```css
/* Use Grid when you need: */
/* 1. Two-dimensional layouts */
.grid-2d {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  grid-template-rows: repeat(3, 100px);
}

/* 2. Precise placement */
.grid-placement {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
}

.item {
  grid-column: 2 / 10;
  grid-row: 1 / 3;
}

/* 3. Overlapping elements */
.grid-overlap {
  display: grid;
}

.background {
  grid-area: 1 / 1 / 2 / 2;
  z-index: 1;
}

.foreground {
  grid-area: 1 / 1 / 2 / 2;
  z-index: 2;
}

/* Use Flexbox when you need: */
/* 1. One-dimensional layouts */
.flex-1d {
  display: flex;
  justify-content: space-between;
}

/* 2. Content-based sizing */
.flex-content {
  display: flex;
}

.flex-item {
  flex: 0 1 auto; /* Shrink but don't grow */
}

/* 3. Alignment along one axis */
.flex-align {
  display: flex;
  align-items: center;
  justify-content: center;
}
```

## Container Queries with Grid/Flexbox

```css
/* Container query with grid */
.card-container {
  container-type: inline-size;
  container-name: card;
}

.card-grid {
  display: grid;
  gap: 1rem;
}

@container card (min-width: 700px) {
  .card-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@container card (min-width: 1000px) {
  .card-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

/* Container query with flexbox */
.flex-container {
  container-type: inline-size;
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
}

.flex-item {
  flex: 1 1 100%;
}

@container (min-width: 500px) {
  .flex-item {
    flex: 1 1 calc(50% - 0.5rem);
  }
}

@container (min-width: 800px) {
  .flex-item {
    flex: 1 1 calc(33.333% - 0.667rem);
  }
}
```

## Performance Optimization

```css
/* Optimize grid/flex performance */
.optimized-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 1rem;
  
  /* Contain layout for performance */
  contain: layout style;
  
  /* Will-change for animations */
  will-change: transform;
}

.optimized-flex {
  display: flex;
  flex-wrap: wrap;
  
  /* Avoid layout thrashing */
  contain: layout;
  
  /* Hardware acceleration */
  transform: translateZ(0);
}

/* Reduce reflows */
.stable-layout {
  /* Define explicit dimensions */
  width: 100%;
  max-width: 1200px;
  height: 600px;
  
  /* Prevent content shift */
  aspect-ratio: 16 / 9;
  
  /* Isolate layout calculations */
  contain: size layout;
}
```

## Production Examples

```typescript
// React component with CSS Grid
function GridGallery({ items }: { items: GalleryItem[] }) {
  return (
    <div className="gallery-grid">
      {items.map((item, index) => (
        <div
          key={item.id}
          className={`gallery-item ${item.featured ? 'featured' : ''}`}
          style={{
            gridColumn: item.featured ? 'span 2' : 'span 1',
            gridRow: item.featured ? 'span 2' : 'span 1'
          }}
        >
          <img src={item.image} alt={item.title} />
          <div className="gallery-overlay">
            <h3>{item.title}</h3>
            <p>{item.description}</p>
          </div>
        </div>
      ))}
    </div>
  );
}

// CSS for the gallery
const galleryStyles = `
.gallery-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  grid-auto-rows: 200px;
  gap: 1rem;
  padding: 1rem;
}

.gallery-item {
  position: relative;
  overflow: hidden;
  border-radius: 8px;
}

.gallery-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}

.gallery-item:hover img {
  transform: scale(1.1);
}

.gallery-overlay {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: linear-gradient(to top, rgba(0,0,0,0.8), transparent);
  color: white;
  padding: 1rem;
  transform: translateY(100%);
  transition: transform 0.3s ease;
}

.gallery-item:hover .gallery-overlay {
  transform: translateY(0);
}

@supports (grid-template-rows: masonry) {
  .gallery-grid {
    grid-template-rows: masonry;
  }
}
`;
```

## Production Checklist
- [ ] Grid template areas defined for complex layouts
- [ ] Subgrid used for aligned content
- [ ] Fallbacks for unsupported features
- [ ] Responsive breakpoints configured
- [ ] Container queries implemented where beneficial
- [ ] Performance optimizations applied
- [ ] Layout containment for reflow prevention
- [ ] Flexbox used for one-dimensional layouts
- [ ] Grid used for two-dimensional layouts
- [ ] Browser compatibility verified