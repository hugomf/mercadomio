# Análisis de Conformidad: Stitch Mocks vs Flutter UI

**Proyecto:** Mercadomio  
**Fecha:** 21 de agosto de 2026  
**Objetivo:** Identificar diferencias entre los mocks de Stitch y las pantallas actuales de Flutter.

---

## 1. Paleta de Colores

### Estado actual
- Los tokens de color en `theme.dart` coinciden **exactamente** con los del Stitch metadata.json.
- **Primary:** `#006B1B` ✓
- **Secondary:** `#446741` ✓
- **Surface:** `#F6FBF0` ✓
- **Tertiary:** `#A0335D` ✓

### Observaciones
- El tema Flutter ya extrae correctamente los tokens del diseño. No se requieren cambios.

---

## 2. Login Screen

### Stitch Mock (Mobile + Desktop)
- **Brand header centrado:** Logo centrado + texto "¡Hola!" + subtítulo
- **Form card:** `bg-surface-container-lowest`, padding 6, borderRadius 2xl, borde `outline-variant/30`, sombra
- **Accent bar:** barra degradada `from-primary to-secondary` en top-0
- **Password field:** ícono de ojo `visibility` para toggle
- **Forgot password:** alineado a la derecha, estilo texto con underline
- **Primary CTA:** botón `bg-primary`, `text-on-primary`, `rounded-xl`, con efecto hover `scale-95`
- **Divider:** "o" centrado con líneas a ambos lados
- **Secondary CTA:** "Crear cuenta nueva" con borde, bg `surface-container-low`
- **Footer:** presente en mobile con links (Privacidad, Términos, Preguntas Frecuentes, Contacto) y logo

### Flutter Actual (`login_screen.dart`)
- ❌ **Brand header:** No hay logo centrado ni "¡Hola!" — usa un icono de bolsa y texto "Mercadomio" (desktop) / solo icono (mobile)
- ❌ **Form card:** No tiene el estilo de `surface-container-lowest` con borde y sombra — usa InputDecorationTheme por defecto
- ❌ **Password visibility:** Mobile no tiene toggle de ojo (solo desktop sí)
- ❌ **Forgot password:** En mobile está como `TextButton` genérico sin estilo de underline
- ❌ **Primary CTA:** Texto dice "Ingresar" en mobile, "Iniciar sesión" en desktop — Stitch usa "Iniciar sesión"
- ❌ **Footer:** No existe footer con links legales
- ❌ **Divider "o":** El estilo es menos refinado (usa Divider() simple)
- ❌ **Secondary CTA:** "Crear cuenta nueva" no usa `surface-container-low` como bg
- ❌ **Subtítulo:** No dice "Inicia sesión para continuar comprando tus productos frescos."

### Prioridad: 🔴 ALTA

---

## 3. Storefront (Home)

### Stitch Mock (Mobile)
- **TopAppBar:** sticky, `bg-surface`, con logo "Mercadomio" + íconos de búsqueda y carrito
- **Location chip:** "Enviar a: Polanco, CDMX" con ícono de location_on
- **Search bar primaria:** dentro de main content, full width mobile
- **Hero banner:** `primary-container` con gradiente, overlay de imagen, texto "20% de descuento", CTA "Ver ofertas"
- **Categories:** scroll horizontal, círculos con íconos, labels debajo
- **Ofertas:** grid cols-2 mobile, 4 desktop — con porcentaje de descuento badge
- **Bottom nav:** 5 tabs (Home activo, Categories, Cart, Orders, Profile)

### Stitch Mock (Desktop)
- **TopNavBar:** doble fila — primera fila: logo + search + location + actions; segunda fila: nav links (Inicio, Categorías, Pedidos, Perfil)
- **Hero:** con imagen de fondo + botón CTA
- **Categories:** grid 4-7 cols
- **Ofertas:** grid 4 cols con badges de descuento

### Flutter Actual (`storefront_widget.dart` + `main.dart`)
- ✅ Desktop header: tiene logo, search, location chip, nav links, carrito, account — alineado con mock
- ✅ Hero banner: tiene gradiente, badge "OFERTA ESPECIAL", texto "20% de descuento", CTA "Ver ofertas"
- ✅ Categories: scroll horizontal con círculos e íconos
- ✅ Ofertas section: "Ofertas de la semana" con header
- ⚠️ **Falta el Mobile TopAppBar:** el storefront mobile actual no tiene el header sticky con logo + carrito
- ⚠️ **El BottomNavBar del mobile:** tiene 5 tabs pero el orden es "Home, Categories, Cart, Orders, Profile" — Stitch usa "Home, Categories, Cart, Orders, Profile" (coincide!). Pero los labels son "Inicio/Categories/Cart/Orders/Profile" vs Stitch "Inicio/Categorías/Carrito/Pedidos/Perfil"

### Prioridad: 🟡 MEDIA (mobile storefront falta TopAppBar)

---

## 4. Product Listing

### Stitch Mock (Mobile)
- **TopAppBar:** sticky, location chip + search + carrito
- **Category chips:** pills con selected state (primary-container)
- **Promo banner:** secondary-container con ícono
- **Grid:** cols-2, cards con imagen, nombre, precio, botón add
- **Bottom nav:** 5 tabs

### Stitch Mock (Desktop)
- **TopNavBar:** desktop header completo
- **Breadcrumbs:** Inicio > Categorías > nombre
- **Title + subtitle + search**
- **Category nav:** pills con underline active
- **Filters sidebar:** Categorías (checkboxes), Precio (range slider)
- **Product grid:** cols-4, cards con badge de descuento, ícono favorite hover
- **Applied filters tags**
- **Pagination**

### Flutter Actual (`product_listing_widget.dart`)
- ❌ **Desktop:** No hay top navbar (depende del MainScreen)
- ❌ **Desktop:** No hay breadcrumbs
- ❌ **Desktop:** No hay filtros sidebar (Categorías, Rango de Precio)
- ❌ **Desktop:** No hay search en la page
- ❌ **Desktop:** No hay pagination
- ⚠️ Cards usan `IconButton.filledTonal` en lugar de `bg-primary-container` con ícono add
- ❌ **Mobile:** No hay TopAppBar con location/search/cart
- ❌ **Mobile:** No hay category selector pills
- ❌ **Mobile:** No hay promo banner
- ❌ **Mobile:** No hay bottom nav (viene del MainScreen)

### Prioridad: 🔴 ALTA (especialmente filters y pagination desktop)

---

## 5. Product Detail

### Stitch Mock (Desktop)
- **TopAppBar:** con back button, share, favorite
- **Breadcrumbs:** Inicio > category > name
- **Image gallery:** imagen principal + thumbnails
- **Product info:** organic badge, category uppercase, nombre, rating, precio con descuento tachado
- **Quick info:** Origen, Entrega hoy, Calidad Premium
- **Quantity selector:** rounded pill con +/- botones
- **Add to cart:** botón full width "Agregar al carrito"
- **Accordions:** Descripción, Información Nutrimental, Consejos de Conservación
- **Related products:** grid con cards (imagen, nombre, precio, add button)

### Stitch Mock (Mobile)
- **App bar:** back, share, favorite
- **Hero image:** full width, aspect square
- **Discount badge**
- **Product info:** vendor, nombre, rating, precio, unit
- **Chips:** Pieza aprox. 120g, Origen: Local
- **Quantity selector:** rounded pill
- **Accordions:** Descripción, Información Nutrimental, Envío
- **Related products:** horizontal scroll cards
- **Sticky footer:** total + "Agregar al carrito" button

### Flutter Actual (`product_detail_screen.dart`)
- ✅ Desktop breadcrumb: existe
- ✅ Desktop image gallery: existe
- ✅ Desktop product info: existe (category, nombre, rating, precio)
- ✅ Desktop quick info: existe (Origen, Entrega hoy, Calidad Premium)
- ✅ Desktop quantity stepper: existe
- ✅ Desktop accordions: existe (Descripción, Información Nutrimental, Envío)
- ✅ Desktop related products: existe
- ✅ Desktop add to cart button: existe
- ❌ **Desktop:** organic badge usa secondaryContainer en lugar de secondaryContainer/tertiaryContainer del mock
- ❌ **Mobile:** El app bar usa SliverAppBar con imagen de fondo (no hay sticky footer con botón de add to cart)
- ❌ **Mobile:** No hay chips de "Pieza aprox." / "Origen"
- ❌ **Mobile:** No hay sticky footer con botón "Agregar al carrito"
- ❌ **Mobile:** No hay discount badge en la imagen hero
- ⚠️ **Related products:** mock usa aspect-[4/3], Flutter usa aspect-[4/3] también (coincide)

### Prioridad: 🔴 ALTA (mobile sticky footer y desktop badge styling)

---

## 6. Cart

### Stitch Mock (Mobile)
- **TopAppBar:** back, "Mi Carrito", subtitle "5 artículos"
- **Cart items:** card con imagen, nombre, precio, qty stepper (-/+), delete button
- **Coupon section:** dashed border, ícono loyalty, input + botón "Aplicar" (secondary)
- **Summary:** Subtotal, Envío gratis, Descuentos, Total
- **Savings alert:** "¡Ahorras $45.00 en esta compra!"
- **Checkout bar:** fixed bottom, "Finalizar Compra" button

### Stitch Mock (Desktop)
- **TopNavBar:** desktop header
- **Breadcrumb:** Inicio > Mi Carrito
- **Title:** "Mi Carrito" + "(5 artículos)" + "Seguir comprando" link
- **Cart table:** grid-cols-12, headers (Producto, Cantidad, Subtotal)
- **Summary sidebar:** Resumen de compra, Subtotal/Envío/Descuentos/Total, Savings alert, Coupon input, Checkout CTA, Lock note

### Flutter Actual (`cart_screen.dart`)
- ✅ Desktop header: breadcrumb + title + items count
- ✅ Desktop: "Seguir comprando" link
- ✅ Desktop cart table: grid con headers
- ✅ Desktop summary: Resumen de compra, subtotal/envío/descuentos/total
- ✅ Desktop: savings alert
- ✅ Desktop: coupon input
- ✅ Desktop: checkout button + lock note
- ❌ **Mobile:** Usa AppBar con título pero falta el subtitle "5 artículos"
- ❌ **Mobile:** Cart items no usan qty stepper rounded pill — usan un diseño más simple
- ❌ **Mobile:** No hay coupon section con dashed border
- ❌ **Mobile:** No hay savings alert
- ❌ **Mobile:** Checkout bar no es fixed bottom — está en el final del scroll

### Prioridad: 🟡 MEDIA (mobile cart bar y coupon)

---

## 7. Checkout

### Stitch Mock (Mobile)
- **Header:** simple, bg `surface-container-lowest`, back button, title "Finalizar Compra", cart icon
- **Delivery address section:** con dirección pre-llenada, "Editar" link, "Agregar nueva dirección" botón dashed
- **Order summary:** items con imagen, nombre, precio, qty
- **Payment method:** radio buttons (Tarjeta, Efectivo, OXXO Pay)
- **Notes section:** textarea
- **Reassurance:** "Pago 100% seguro" lock icon
- **Checkout bar:** fixed bottom con total + "Confirmar pedido"

### Stitch Mock (Desktop)
- **Header:** simple con logo + "Pago Seguro"
- **Breadcrumb:** Inicio > Carrito > Finalizar Compra
- **Title:** "Finalizar Compra" + itemCount
- **Two column layout:**
  - Left: Delivery section (con dirección + "Añadir nueva dirección"), Payment section (radio options + notes), Security badge
  - Right (sticky): Order summary (items + totals + checkout button)
- **Mobile bottom bar:** total + "Confirmar pedido"

### Flutter Actual (`checkout_screen.dart`)
- ❌ **Mobile:** AppBar genérica con title "Finalizar Pago" (debe ser "Finalizar Compra")
- ❌ **Mobile:** No tiene header simple con cart icon
- ❌ **Mobile:** Usa formulario largo con todos los campos de dirección en vez de dirección pre-llenada + "Editar"
- ❌ **Mobile:** No tiene order summary en la izquierda (viene después del formulario)
- ❌ **Mobile:** No tiene checkout bar fixed bottom
- ✅ **Desktop:** Tiene breadcrumb + title + itemCount
- ✅ **Desktop:** Tiene delivery section
- ✅ **Desktop:** Tiene payment method
- ✅ **Desktop:** Tiene notes
- ✅ **Desktop:** Tiene security badge
- ✅ **Desktop:** Tiene order summary sticky
- ❌ **Desktop:** Order summary usa botón "Finalizar Compra" pero no tiene el estilo del mock (no full width, etc.)
- ❌ **Desktop:** No hay radio button styling con check_circle como en mock
- ❌ **General:** La estructura del formulario es diferente — Stitch usa dirección pre-llenada con "Editar", Flutter usa formulario largo

### Prioridad: 🔴 ALTA (especialmente mobile checkout)

---

## 8. Order History

### Stitch Mock (Desktop)
- **TopNavBar:** desktop header
- **Breadcrumb:** Inicio > Historial de Pedidos
- **Title + search:** "Historial de Pedidos" + search field
- **Filter tabs:** underline style (Todos/Activos/En camino/Entregados/Cancelados)
- **Active order banner:** tarjeta con stepper (4 steps), "Rastrear pedido" button
- **Order cards:** con status badge, fecha, items preview, total, ver detalles + volver a pedir
- **Support block:** centrado

### Stitch Mock (Mobile)
- **TopNavBar:** simple con back, title, search icon
- **Filter tabs:** rounded pills (Todos/Activos/En camino/Entregados/Cancelados)
- **Active order banner:** con status badge y stepper
- **Order cards:** título + status badge + fecha + items + total
- **Support links:** al final

### Flutter Actual (`order_history_screen.dart`)
- ✅ Desktop: breadcrumb + title + search
- ✅ Desktop: filter tabs con underline style
- ✅ Desktop: active order banner
- ✅ Desktop: order cards con status badges
- ✅ Desktop: support block
- ❌ **Desktop:** Active order banner no tiene stepper visual
- ❌ **Desktop:** No tiene "Volver a pedir" button en order cards
- ❌ **Mobile:** Usa AppBar con título + filter icon (no search)
- ❌ **Mobile:** No tiene filter tabs/pills
- ❌ **Mobile:** No tiene order cards con items preview
- ❌ **Mobile:** Tiene FAB flotante (no está en ningún mock)
- ❌ **Mobile:** No tiene bottom nav visible (depende del MainScreen)

### Prioridad: 🟡 MEDIA (mobile order history y desktop stepper)

---

## 9. Navigation / Layout General

### Stitch Mock (Desktop)
- **NavBar superior:** doble fila — logo/search/location/actions + nav links
- **Footer:** centrado con columns (legal, soporte, copyright)
- **No sidebar:** Stitch no usa sidebar navigation

### Stitch Mock (Mobile)
- **Bottom nav:** 5 tabs (Inicio, Categorías, Carrito, Pedidos, Perfil)
- **Footer:** centrado con links

### Flutter Actual (`main.dart`)
- ✅ Desktop header: doble fila con logo + search + location + actions + nav links
- ✅ Desktop: constraint maxWidth 1280
- ⚠️ Desktop: no tiene footer visible en el HomeScreen
- ✅ Mobile bottom nav: 5 tabs (pero labels en español correcto)
- ❌ **Mobile bottom nav:** El orden es (Inicio, Carrito, Pedidos) — solo 3 tabs, no 5 como en Stitch
- ❌ **Mobile bottom nav:** Faltan "Categorías" y "Perfil" tabs
- ❌ **Mobile:** No muestra el search en el topAppBar (solo un botón de search icon)
- ❌ **Mobile:** No hay footer con links legales
- ❌ **Mobile checkout/cart:** No están presentes el bottom nav

### Prioridad: 🟡 MEDIA (mobile nav incompleta)

---

## 10. Componentes compartidos (faltantes)

1. **Location chip** — Existe en Flutter desktop header pero no en mobile
2. **BottomNavBar** — Mobile tiene 3 tabs, debe tener 5
3. **Footer** — No existe en ninguna pantalla de Flutter
4. **Promo banner** — Solo en storefront desktop, no en mobile
5. **Security badge** — Solo en checkout, no en otras pantallas

---

## Resumen de prioridades

| Prioridad | Pantalla | Issue principal |
|-----------|----------|-----------------|
| 🔴 ALTA | Login | No hay brand header, footer, password toggle (mobile), estilos de form card |
| 🔴 ALTA | Product Listing | No hay filtros desktop, pagination, breadcrumbs, category pills mobile |
| 🔴 ALTA | Product Detail | Mobile no tiene sticky footer, chips, discount badge, fav button en mobile |
| 🔴 ALTA | Checkout | Mobile usa formulario largo en vez de dirección pre-llenada, falta mobile checkout bar |
| 🟡 MEDIA | Storefront | Mobile no tiene TopAppBar con search + cart |
| 🟡 MEDIA | Cart | Mobile falta coupon section, savings alert, fixed checkout bar |
| 🟡 MEDIA | Order History | Mobile falta filter tabs, order cards con previews. Desktop falta stepper |
| 🟡 MEDIA | Navigation | Mobile bottom nav tiene 3 tabs en vez de 5, falta footer |