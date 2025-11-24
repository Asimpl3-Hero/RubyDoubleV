# 🧠 Lógica de Negocio - FactuMarket

Este documento detalla las reglas de negocio, validaciones y flujos lógicos implementados en el sistema de facturación electrónica **FactuMarket**.

---

## 📋 Tabla de Contenidos

- [Entidades Principales](#-entidades-principales)
  - [Cliente](#1-cliente)
  - [Factura](#2-factura)
  - [Evento de Auditoría](#3-evento-de-auditoría)
- [Flujos de Negocio](#-flujos-de-negocio)
  - [Creación de Clientes](#1-creación-de-clientes)
  - [Emisión de Facturas](#2-emisión-de-facturas)
  - [Auditoría del Sistema](#3-auditoría-del-sistema)
- [Validaciones Transversales](#-validaciones-transversales)

---

## 🏢 Entidades Principales

### 1. Cliente
Representa a la persona natural o jurídica que recibe los servicios.

**Ubicación:** `clientes-service/app/domain/entities/cliente.rb`

**Atributos:**
- `nombre`: Razón social o nombre completo.
- `identificacion`: NIT, Cédula o ID único.
- `correo`: Email de contacto.
- `direccion`: Ubicación física.

**Reglas de Validación:**
| Atributo | Regla | Mensaje de Error |
|----------|-------|------------------|
| `nombre` | Obligatorio | "Nombre es requerido" |
| `identificacion` | Obligatorio | "Identificación es requerida" |
| `correo` | Obligatorio | "Correo es requerido" |
| `correo` | Formato Email | "Formato de correo inválido" |
| `direccion` | Obligatorio | "Dirección es requerida" |

---

### 2. Factura
Documento legal que soporta la transacción comercial.

**Ubicación:** `facturas-service/app/domain/entities/factura.rb`

**Atributos:**
- `cliente_id`: Referencia al cliente.
- `numero_factura`: Código único generado automáticamente.
- `fecha_emision`: Fecha de la factura.
- `monto`: Valor total.
- `estado`: Estado actual (ej. 'EMITIDA').
- `items`: Lista de productos/servicios.

**Reglas de Validación:**
| Atributo | Regla | Mensaje de Error |
|----------|-------|------------------|
| `cliente_id` | Obligatorio | "Cliente ID es requerido" |
| `fecha_emision` | Obligatorio | "Fecha de emisión es requerida" |
| `fecha_emision` | <= Hoy | "Fecha de emisión inválida" |
| `monto` | > 0 | "Monto debe ser mayor a 0" |

**Generación de Número de Factura:**
Formato: `F-YYYYMMDD-HEXCODE`
- `YYYYMMDD`: Fecha actual.
- `HEXCODE`: 4 bytes aleatorios en hexadecimal (8 caracteres).
- *Ejemplo:* `F-20250113-A1B2C3D4`

---

### 3. Evento de Auditoría
Registro inmutable de acciones realizadas en el sistema.

**Ubicación:** `auditoria-service/app/domain/entities/audit_event.rb`

**Atributos:**
- `entity_type`: Tipo de entidad afectada (Cliente, Factura).
- `entity_id`: ID de la entidad.
- `action`: Acción realizada (CREATE, UPDATE, etc.).
- `details`: JSON con detalles del evento.
- `status`: Resultado de la operación (SUCCESS, ERROR).

**Reglas de Validación:**
- `status` debe ser estrictamente "SUCCESS" o "ERROR".
- Todos los campos principales son obligatorios.

---

## 🔄 Flujos de Negocio

### 1. Creación de Clientes
El proceso de registro de un nuevo cliente en el sistema.

1. **Recepción de Datos:** Se reciben los datos básicos (nombre, ID, correo, dirección).
2. **Validación de Dominio:** Se aplican las reglas de validación de la entidad `Cliente`.
3. **Persistencia:** Se guarda el cliente en la base de datos SQLite del servicio de Clientes.
4. **Auditoría:** Se envía un evento asíncrono al servicio de Auditoría (`action: "CREATE_CLIENTE"`).

### 2. Emisión de Facturas
El proceso más crítico que involucra coordinación entre microservicios.

1. **Validación de Datos Básicos:** Se verifica que la factura tenga fecha válida y monto positivo.
2. **Validación de Existencia de Cliente (Síncrono):**
   - El servicio de Facturas hace una petición HTTP GET al servicio de Clientes (`/clientes/:id`).
   - Si el cliente no existe o el servicio no responde, la operación falla.
   - *Clase responsable:* `Domain::Services::ClienteValidator`.
3. **Generación de Identificador:** Se crea el `numero_factura` único.
4. **Persistencia:** Se guarda la factura en la base de datos SQLite del servicio de Facturas.
5. **Auditoría:** Se envía un evento asíncrono al servicio de Auditoría (`action: "CREATE_FACTURA"`).

### 3. Auditoría del Sistema
Mecanismo para garantizar la trazabilidad sin afectar el rendimiento.

- **Patrón Fire-and-Forget:** Los servicios de Clientes y Facturas envían eventos a Auditoría sin esperar respuesta.
- **Almacenamiento NoSQL:** Se usa MongoDB para permitir alta velocidad de escritura y flexibilidad en el esquema de los detalles (`details`).
- **Consultas:** Permite rastrear todo el historial de acciones por cliente o por factura específica.

---

## 🛡️ Validaciones Transversales

### Unicidad
- **Clientes:** Aunque la validación de unicidad de `identificacion` suele delegarse a la base de datos (índice único), el dominio debe estar preparado para manejar errores de duplicidad.
- **Facturas:** El `numero_factura` se diseña para ser estadísticamente único mediante el uso de timestamp + entropía aleatoria.

### Integridad Referencial Distribuida
Dado que es un sistema de microservicios, no existen claves foráneas (Foreign Keys) entre Facturas y Clientes a nivel de base de datos.
- **Solución:** La integridad se garantiza mediante la validación síncrona (`ClienteValidator`) en el momento de la creación.

### Resiliencia
- Si el servicio de Auditoría cae, la creación de clientes y facturas **NO** se detiene. El fallo en el envío del evento de auditoría se captura y loguea, pero no aborta la transacción principal.
