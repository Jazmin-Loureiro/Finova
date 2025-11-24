# Finova — Plataforma Móvil de Gestión Financiera Personal

Finova es una plataforma móvil de gestión financiera desarrollada en Flutter y potenciada por un backend robusto en Laravel.
Su misión es transformar la manera en que las personas administran su dinero, ofreciendo una experiencia clara, intuitiva y altamente visual, respaldada por herramientas modernas y datos precisos.

Finova combina tecnología de vanguardia con funciones financieras avanzadas: soporte multi-moneda, registro inteligente de ingresos y gastos, analíticas detalladas, metas financieras dinámicas, conversor de divisas en tiempo real y módulos de simulación de préstamos basados en información oficial del Banco Central.
También incorpora simuladores de inversión —tanto tradicionales (plazo fijo) como digitales (crypto)— y la posibilidad de exportar reportes personalizados.

La experiencia se complementa con un sistema de desafíos financieros que fomenta el hábito del ahorro y una interfaz gamificada protagonizada por la Casa Finova, una representación visual que evoluciona según tu progreso económico y tus logros dentro de la app.

## 📘 Tabla de Contenidos
- [Características Principales](#características-principales)
- [Tecnologias Utilizadas](#tecnologias-utilizadas)
- [APIs Externas Utilizadas](#apis-externas-utilizadas)
- [Sistema de Actualización Automática](#sistema-de-actualización-automática)
- [Sistema de Envío de Correos](#sistema-de-envío-de-correos-mailing)
- [Autoras](#autoras)


## Características Principales
### Fuentes de Dinero
- Múltiples tipos: billeteras, cuentas bancarias, efectivo, tarjetas, etc.
- Balance independiente con su propia moneda.
- Balance convertido a moneda base en tiempo real.

### Registros
- Carga rápida de ingresos y gastos.
- Conversión automática si difiere la moneda.
- Filtros avanzados por categoría, fecha, tipo, fuente y búsqueda.
- Agrupación por día y totales instantáneos.

### Metas Financieras
- Creación de metas con monto objetivo.
- Reserva automática al vincular una meta.
- Avance visual en tiempo real.
  
### Objetivos gamificados

Finova incluye un sistema de objetivos automáticos que funcionan como misiones o desafíos que incentivan el uso de la app y la mejora de los hábitos financieros.

- El sistema genera objetivos periódicos para ayudar a mejorar tus finanzas.
- Cada objetivo otorga **puntos de experiencia (XP)** al ser completado.  
- Al acumular XP, el usuario **sube de nivel**, lo que desbloquea recompensas dentro de la app.  
- Según el nivel, las recompensas incluyen elementos visuales y mejoras dentro de la **Casa Finova**.  
- Los objetivos se renuevan con el tiempo, manteniendo la experiencia dinámica y motivadora.  
- Los usuarios pueden ver su progreso, objetivos activos y recompensas obtenidas.  

### Estadísticas Inteligentes
- Totales mensuales.
- Ingresos vs gastos.
- Distribución por categoría.
- Balance global convertido a la moneda base.
- Gráficos dinámicos con fl_chart.

### Casa Gamificada
- Representación visual del progreso financiero.
- Cielos dinámicos: día, atardecer, noche.
- Evolución de la casa según tu progreso.
- Desbloqueos y animaciones Lottie.

### Conversor de Divisas
- Actualización automática por OpenExchangeRates.
- Conversiones precisas con formateo por locale.
- Más de 160 monedas compatibles.

### Autenticación y Seguridad
- Registro con avatar generado o ícono personalizado.
- Login seguro con Laravel Sanctum.
- Restablecimiento de contraseña por deep-link nativo.
- Tokens protegidos y manejo de UTC/local.

## Tecnologias Utilizadas

<p align="center">
  <a><img src="https://img.shields.io/badge/Flutter-3.35.3-blue?logo=flutter" alt="Flutter"></a>
  <a><img src="https://img.shields.io/badge/Dart-3.9.2-blue?logo=dart" alt="Dart"></a>
  <a><img src="https://img.shields.io/badge/Laravel-9.52-red?logo=laravel" alt="Laravel"></a>
  <a><img src="https://img.shields.io/badge/MySQL-Database-blue?logo=mysql" alt="MySQL"></a>
</p>


### **Frontend — Flutter**

- **Flutter 3.35.3**
- **Dart 3.9.2**
- Provider (estado)
- fl_chart (gráficos)
- flutter_svg (vectores)
- Lottie (animaciones)
- Animaciones personalizadas y transiciones fluidas

---

### **Backend — Laravel**

- **Laravel Framework 9.52.20**
- Laravel Sanctum (autenticación segura)
- Base de datos **MySQL**
- Jobs & Commands para actualización de DataAPI
- Validaciones robustas (Requests)
- Conversión automática de monedas
- Manejo consistente de timestamps **UTC → Local**



## APIs Externas Utilizadas

Finova integra múltiples fuentes de datos externas para brindar información financiera precisa, actualizada y confiable.

### 💱 1. OpenExchangeRates
Servicio utilizado para:
- Obtener tasas de cambio en tiempo real.
- Actualizar automáticamente la Base de Divisas.
- Conversión entre más de 160 monedas.

### 🏦 2. Banco Central (BCRA) — DataAPI
Utilizado para:
- Obtener tasas oficiales para cálculos y simulaciones.
- Alimentar el módulo de préstamos y plazos fijos con datos reales.
- Actualizaciones periódicas mediante comandos automáticos.

### 📈 3. CoinGecko API
Utilizado para:
- Consultar precios de criptomonedas.
- Simular inversiones digitales en tiempo real.
- Obtener históricos de precios.

### 📉 4. TwelveData API
Utilizado para:
- Obtener datos actualizadosde acciones y bonos.
- Complementar modelo de simulación de inversiones.

### 🌍 5. World Bank PPP API
Utilizado para:
- Consultar el índice PPP (Purchasing Power Parity).
- Alimentar la lógica de “Casa Finova” y sus visualizaciones.
- Comparar poder adquisitivo entre países.

### 📧 6. Brevo (SMTP)
Utilizado para:
- Enviar correos de recuperación de contraseña.
- Comunicaciones del sistema.

 ## Sistema de Actualización Automática

Finova cuenta con un sistema de tareas automáticas que mantiene los datos siempre actualizados.
Estas tareas se ejecutan mediante el Scheduler de Laravel y se organizan en tres grupos:

- Frecuencias
* Diarias (daily)
  Actualización de indicadores económicos clave y tasas oficiales del BCRA.

* Frecuentes (frequent)
  Actualización de:
  Precios de criptomonedas (CoinGecko)
  Tasas de cambio (OpenExchangeRates)
  Datos financieros de TwelveData

* Semanales (weekly)
Actualización de datos macroeconómicos de bajo cambio (ej. PPP del Banco Mundial).

## Sistema de Envío de Correos (Mailing)

Finova utiliza Brevo SMTP como proveedor de correo para enviar notificaciones internas y correos de recuperación de contraseña.

* Emails implementados
* Recuperación de contraseña mediante enlace seguro (deep-link nativo).
* Comunicaciones automáticas del sistema.
* Soporte al usuario.


## Autoras

Finova es un proyecto desarrollado en equipo por:

### 🌟 Agustina Flores  
**Rol:** Desarrollo Mobile & Backend — Flutter • Laravel • Diseño UI/UX • Integraciones • Documentación  
**Especialidades:** Desarrollo Full Stack • Arquitectura de Aplicaciones • APIs REST • Base de Datos • Animaciones • Testing  
**Contacto y Redes:**  
- 🐙 GitHub: https://github.com/AilenFlores
- 💼 LinkedIn: https://www.linkedin.com
- 📧 Email: agustinaafff@gmail.com

---

### 🌟 Jazmín Loureiro  
**Rol:** Desarrollo Mobile & Backend — Flutter • Laravel • Diseño UI/UX • Integraciones • Documentación  
**Especialidades:** Desarrollo Full Stack • Arquitectura de Aplicaciones • APIs REST • Base de Datos • Validaciones • Testing  
**Contacto y Redes:**  
- 🐙 GitHub: https://[github.com/Jazmin-Loureiro](https://github.com/Jazmin-Loureiro)
- 💼 LinkedIn: https://[www.linkedin.com](https://www.linkedin.com/in/jazmin-loureiro/)
- 📧 Email: jazmin.loureiro25@gmail.com
