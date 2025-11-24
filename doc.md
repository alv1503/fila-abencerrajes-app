# Documentación del Proyecto: AbenceApp (v0.1)

## 1. Visión General

**AbenceApp** es una aplicación móvil privada y exclusiva para los miembros de la Filà Abencerrajes. El objetivo es centralizar la comunicación, gestionar eventos, realizar votaciones y facilitar el acceso a la información de los miembros, reemplazando métodos de comunicación menos eficientes.

La aplicación está construida en **Flutter** y utiliza **Firebase** como backend completo (Base de datos, Autenticación y Almacenamiento).

## 2. Tecnologías Principales

* **Frontend:** Flutter
* **Backend:** Firebase
    * **Autenticación:** Firebase Auth (Email/Contraseña)
    * **Base de Datos:** Cloud Firestore
    * **Almacenamiento:** Firebase Storage (para fotos de perfil)
* **Gestión de Estado:** `StatefulWidget` (`setState`) para la mayoría de las vistas.

## 3. Estructura del Proyecto (Carpetas `lib/`)

Tras la refactorización, la estructura de las páginas es la siguiente:

* `lib/services/`: Contiene la lógica de negocio (Auth y Firestore).
* `lib/models/`: Define las estructuras de datos (Usuario, Evento, Votación).
* `lib/utils/`: Contiene "ayudantes", como el `icon_helper.dart`.
* `lib/auth/`: Gestiona el flujo de login (`AuthGate`, `LoginPage`).
* `lib/pages/`:
    * `tabs/`: Contiene las 5 pantallas principales de la barra de navegación.
    * `details/`: Contiene las pantallas que muestran detalles (ej. detalle de un evento).
    * `forms/`: Contiene las pantallas que son formularios (ej. crear un evento).

---

## 4. Funcionalidades Implementadas

### 4.1. Autenticación y Acceso

* **Login:** Los usuarios inician sesión con su email y su DNI (8 números) como contraseña. No existe un formulario de registro público; los usuarios se crean manualmente en Firebase.
* **Teclado Numérico:** El campo de contraseña en el login muestra un teclado numérico para facilitar la introducción del DNI.
* **Gestión de Sesión:** La app utiliza un `AuthGate` (`auth_gate.dart`) para dirigir automáticamente a los usuarios a la página de inicio si ya están logueados, o a la de login si no lo están.

### 4.2. Navegación Principal

La navegación se centra en una barra inferior (`BottomNavigationBar`) con 5 pestañas:

1.  **Inici**
2.  **Esdeveniments**
3.  **Membres**
4.  **Votacions**
5.  **Perfil**

### 4.3. Pestaña: Inici (`home_feed_page.dart`)

Es el "dashboard" de la app. Es una página dinámica que muestra:
* Una tarjeta de **bienvenida personalizada** (Ej: "Benvingut, [Mote]!").
* Una cuadrícula (`GridView`) de los **4 próximos eventos**.
* Una cuadrícula (`GridView`) de las **2 próximas votaciones** a cerrar.

### 4.4. Módulo: Miembros

* **Pantalla Principal (`members_page.dart`):**
    * Muestra a todos los miembros de la filà en una cuadrícula (`GridView`) de 2 columnas.
    * Cada tarjeta de miembro muestra su foto de perfil (o su inicial si no tiene) y su mote.
* **Perfil Público (`public_profile_page.dart`):**
    * Al pulsar en un miembro, se accede a su perfil público.
    * Muestra información de contacto (email, teléfono), foto, mote, nombre completo y descripción.
    * **Oculta** información sensible (DNI, tipo de cuota, etc.).

### 4.5. Módulo: Eventos

* **Pantalla Principal (`events_page.dart`):**
    * Muestra una lista (con `Card`) de todos los eventos futuros.
    * **Funcionalidad de Admin:** Si el usuario es `isAdmin == true`, ve un botón flotante (`+`) para crear nuevos eventos.
* **Creación de Eventos (`create_event_page.dart`):**
    * Un formulario para crear un evento con título, ubicación, descripción y fecha/hora.
    * Incluye un **selector de iconos** horizontal (reunión, comida, fiesta...) que se guardará con el evento.
* **Detalle de Evento (`event_detail_page.dart`):**
    * Muestra la información completa del evento.
    * Muestra la lista de "Apuntats".
    * Permite al usuario **apuntarse** ("Apuntar-me") o **borrarse** ("Esborrar-me") del evento. El botón actualiza la lista en tiempo real.

### 4.6. Módulo: Votaciones

* **Pantalla Principal (`voting_page.dart`):**
    * Muestra una lista (con `Card`) de todas las votaciones activas (que no han caducado).
    * **Funcionalidad de Admin:** Si el usuario es `isAdmin == true`, ve un botón flotante (`+`) para crear nuevas votaciones.
* **Creación de Votaciones (`add_voting_page.dart`):**
    * Un formulario para crear una votación con título, descripción y fecha de cierre.
    * Permite **añadir opciones de voto dinámicamente** (mínimo 2).
    * Incluye un **selector de iconos** (cargo, dinero, general...).
* **Detalle de Votación (`voting_detail_page.dart`):**
    * Permite al usuario **emitir su voto** (con `RadioListTile`).
    * Si el usuario ya ha votado, le muestra su voto y los **resultados actuales** (en porcentaje).
    * Si el usuario no ha votado, le oculta los resultados hasta que vote.

### 4.7. Pestaña: Perfil de Usuario

* **Pantalla Principal (`profile_page.dart`):**
    * Muestra el perfil **privado** del usuario logueado.
    * Muestra toda la información (incluida la sensible como DNI, dirección, cuota) en tarjetas de "solo lectura".
    * Permite al usuario **subir/cambiar su foto de perfil** pulsando en el avatar.
    * Tiene un botón para "Editar Perfil" y un botón para "Tancar Sessió".
* **Edición de Perfil (`edit_profile_page.dart`):**
    * Un formulario que permite al usuario actualizar los campos públicos: **mote, teléfono, dirección y descripción**.

---

¡Listo! Este es un buen resumen de todo lo que hemos construido.

Ahora, si te parece bien, podemos empezar a comentar los archivos. ¿Por qué carpeta empezamos? (Te sugiero `lib/models/`, ya que son la base de todo).