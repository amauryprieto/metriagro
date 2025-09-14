# Metriagro - Flutter App

Aplicación móvil para análisis agrícola con Machine Learning integrado.

## Stack Técnico

- **Frontend**: Flutter con arquitectura BLoC
- **Backend**: Firebase + Google Cloud Functions
- **ML**: TensorFlow Lite (on-device) + Cloud ML APIs
- **Base de datos**: Firestore + Cloud Storage
- **Autenticación**: Firebase Auth
- **Analytics**: Firebase Analytics + Mixpanel
- **Testing**: Unit, Widget e Integration tests
- **Lenguaje Android**: Kotlin

## Configuración del Proyecto

### 1. Dependencias

```bash
flutter pub get
```

### 2. Firebase Setup

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Instala Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```
3. Instala FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
4. Configura Firebase:
   ```bash
   flutterfire configure
   ```
5. Actualiza `lib/core/firebase/firebase_options.dart` con las credenciales generadas

### 3. Configuración de Mixpanel

1. Crea una cuenta en [Mixpanel](https://mixpanel.com/)
2. Obtén tu Project Token
3. Actualiza el token en `lib/core/di/injection_container.dart`

### 4. Configuración de Android

El proyecto ya está configurado para usar Kotlin. Asegúrate de tener:

- Android SDK 21+ (minSdk)
- Kotlin 1.9.0+
- Gradle 8.0+

### 5. Modelos de ML

1. Coloca tus modelos TensorFlow Lite en `assets/models/`
2. Actualiza las rutas en `lib/core/constants/app_constants.dart`

## Estructura del Proyecto

```
lib/
├── core/                    # Funcionalidades centrales
│   ├── constants/           # Constantes de la app
│   ├── di/                 # Inyección de dependencias
│   ├── errors/             # Manejo de errores
│   ├── firebase/           # Configuración de Firebase
│   ├── network/            # Configuración de red
│   ├── theme/              # Temas de la app
│   └── utils/              # Utilidades generales
├── features/               # Características de la app
│   ├── auth/               # Autenticación
│   │   ├── data/           # Capa de datos
│   │   ├── domain/         # Lógica de negocio
│   │   └── presentation/   # UI y BLoC
│   ├── home/               # Pantalla principal
│   ├── profile/            # Perfil de usuario
│   └── settings/           # Configuraciones
└── shared/                 # Componentes compartidos
    ├── models/             # Modelos compartidos
    ├── services/           # Servicios compartidos
    └── widgets/            # Widgets reutilizables
```

## Comandos Útiles

### Desarrollo
```bash
# Ejecutar en modo debug
flutter run

# Ejecutar tests
flutter test

# Ejecutar tests de integración
flutter test integration_test/

# Generar código (Freezed, JSON, etc.)
flutter packages pub run build_runner build

# Limpiar y regenerar
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Build
```bash
# Build APK
flutter build apk

# Build APK release
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

## Testing

El proyecto incluye tres tipos de testing:

1. **Unit Tests**: `test/unit/` - Pruebas de lógica de negocio
2. **Widget Tests**: `test/widget/` - Pruebas de UI
3. **Integration Tests**: `test/integration/` - Pruebas end-to-end

## Arquitectura BLoC

El proyecto sigue el patrón BLoC (Business Logic Component):

- **Events**: Eventos que disparan cambios de estado
- **States**: Estados de la aplicación
- **Bloc**: Lógica de negocio que procesa eventos y emite estados
- **Repository**: Interfaz para acceso a datos
- **Use Cases**: Casos de uso específicos

## Próximos Pasos

1. Implementar repositorios de Firebase
2. Configurar modelos de datos
3. Implementar casos de uso
4. Crear pantallas adicionales
5. Integrar TensorFlow Lite
6. Configurar analytics
7. Implementar tests de integración

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request
