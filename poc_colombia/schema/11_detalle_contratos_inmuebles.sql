/* ============================================================================
   11. Detalle contractual e inmuebles (fuente: Informes FIC - Parametros.accdb
   + Bases_Colombia\Input\Contratos.xlsx / Inmuebles.xlsx)

   Parametros.accdb se confirmo como la fuente externa "Parametros" del
   diagrama de flujo original (conteos de fila calzan exacto con las tablas
   compartidas ya cargadas: tbl_Contratos=88.898, tbl_Inmuebles=9.158,
   tbl_Fondos=15, etc.) y trae 4 tablas con detalle nunca modelado, mas los
   Excel de Input traen aun mas detalle que no existe en ningun Access.

   Igual criterio que 02_dimensiones_historicas.sql / 05_eeff_351.sql /
   06_gastos_otros_raw.sql: sin FK donde la relacion no esta confirmada
   estructuralmente (solo indice). Estas tablas son de detalle/referencia,
   no participan (todavia) de las FKs del modelo core.
============================================================================ */

/* ============================================================
   tbl_Contratos_Detalle  (~9.037 VIGENTE desde Access "Contratos" +
   ~746 NO VIGENTE desde Contratos.xlsx hoja "Contratos no vigentes")

   Union por NOMBRE de columna de ambas hojas -- la hoja "no vigentes" trae
   68 columnas (10 menos) y una columna propia (OBSERVACIONES REVISION DE
   CONTRATO). Se carga por nombre de columna, no por posicion; lo que no
   existe en el origen queda NULL. Clave de negocio [COD ]/[COD_Nuevo] sin
   confirmar unicidad al 100% (codigos tipo '185g','257a') -> indice, no PK.
   ============================================================ */
CREATE TABLE [dbo].[tbl_Contratos_Detalle] (
    [Id]                                                    INT IDENTITY(1,1) NOT NULL,
    [Origen_Hoja]                                           NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_tbl_Contratos_Detalle_Origen CHECK ([Origen_Hoja] IN (N'VIGENTE', N'NO VIGENTE')),
    [FECHA]                                                 DATETIME2(0)  NULL,
    [COD]                                                   NVARCHAR(20)  NULL,
    [COD_Nuevo]                                             DECIMAL(18,0) NULL,
    [ARRENDATARIO]                                          NVARCHAR(255) NULL,
    [CIUDAD DEL PREDIO]                                     NVARCHAR(255) NULL,
    [TIPOLOGÍA INMUEBLE]                                    NVARCHAR(255) NULL,
    [DESCRIPCIÓN]                                           NVARCHAR(255) NULL,
    [TIPO DE CONTRATO]                                      NVARCHAR(MAX) NULL,
    [ÁREA RENTABLE CONTRATO ARRENDAMIENTO]                  DECIMAL(18,4) NULL,
    [ÚLTIMO CANON]                                          DECIMAL(18,4) NULL,
    [CANON M2]                                              DECIMAL(18,4) NULL,
    [FECHA INICIO CONTRATO]                                 DATETIME2(0)  NULL,
    [FECHA INICIO COBRO CANON]                              DATETIME2(0)  NULL,
    [DURACIÓN AÑOS ARRENDAMIENTO]                           DECIMAL(10,2) NULL,
    [FECHA FINALIZACIÓN CONTRATO INICIAL]                   DATETIME2(0)  NULL,
    [FECHA FIN CONTRATO (incluye prórrogas/renovaciones)]   DATETIME2(0)  NULL,
    [MES DE AJUSTE ANUAL]                                   INT           NULL,
    [INCREMENTO ANUAL SOBRE IPC]                            NVARCHAR(MAX) NULL,
    [INCREMENTO ANUAL COMO VECES IPC]                       DECIMAL(10,4) NULL,
    [DETALLE INCREMENTO]                                    NVARCHAR(MAX) NULL,
    [CANON VARIABLE]                                        NVARCHAR(255) NULL,
    [CLÁUSULA INCREMENTO DE CANON]                          NVARCHAR(MAX) NULL,
    [PREAVISO EN MESES TÉRMINO INICIAL]                     DECIMAL(10,2) NULL,
    [PREAVISO PRÓRROGA / RENOVACIÓN]                        DECIMAL(10,2) NULL,
    [PRÓRROGAS / RENOVACIONES]                              NVARCHAR(MAX) NULL,
    [CLÁUSULA CONDICIONES PRÓRROGAS / RENOVACIONES]         NVARCHAR(MAX) NULL,
    [AÑOS POR PRÓRROGA/RENOVACIÓN]                          DECIMAL(10,2) NULL,
    [NÚMERO DE PRÓRRGAS / RENOVACIONES]                     NVARCHAR(255) NULL,
    [FECHA PRÓRROGA / RENOVACIÓN]                           NVARCHAR(255) NULL,
    [FECHA PREAVISO]                                        DECIMAL(18,4) NULL,
    [CLÁUSULA SALIDA ANTICIPADA]                            NVARCHAR(MAX) NULL,
    [FECHA POSIBLE DE TERMINACIÓN ANTICIPADA]               NVARCHAR(255) NULL,
    [CLÁUSULA REVISIÓN CONDICIONES ECONÓMICAS]              NVARCHAR(MAX) NULL,
    [PISO / TECHO RENEGOCIACIÓN CANON]                      NVARCHAR(MAX) NULL,
    [REVISIÓN CANON TÉRMINO INICIAL (AÑOS)]                 DECIMAL(10,2) NULL,
    [REVISIÓN CANON PRORROGA / RENOVACIÓN (AÑOS)]           DECIMAL(10,2) NULL,
    [PRÓXIMA FECHA REVISIÓN DE CONDICIONES ECONÓMICAS]      DECIMAL(18,4) NULL,
    [MESES PARA REVISIÓN DE CONDICIONES ECONÓMICAS]         DECIMAL(10,2) NULL,
    [ACTIVACIÓN FECHA REVISIÓN DE CONDICIONES ECONÓMICAS]   DECIMAL(18,4) NULL,
    [CONDICIONES ESPECIALES DE CANON]                       NVARCHAR(MAX) NULL,
    [CONDICIONES DE FACTURACIÓN]                            NVARCHAR(MAX) NULL,
    [DIA DE INCREMENTO]                                     NVARCHAR(255) NULL,
    [DIAS DE VENCIMIENTO DE FACTURA]                        NVARCHAR(255) NULL,
    [DIAS DE VENCIMIENTO DE FACTURA (HÁBIL O CALENDARIO)]   NVARCHAR(255) NULL,
    [BASE DE FACTURACIÓN]                                   NVARCHAR(MAX) NULL,
    [PERIODICIDAD DE LA FACTURACION]                        NVARCHAR(MAX) NULL,
    [FORMULA DE INCREMENTO]                                 NVARCHAR(MAX) NULL,
    [TIPO DE IPC INCREMENTO]                                NVARCHAR(255) NULL,
    [CANON MOBILIARIO (SI APLICA)]                          NVARCHAR(MAX) NULL,
    [CANON AVISO (SI APLICA)]                               NVARCHAR(MAX) NULL,
    [REPARACIONES NECESARIAS]                               NVARCHAR(MAX) NULL,
    [REPARACIONES LOCATIVAS]                                NVARCHAR(MAX) NULL,
    [MANTENIMIENTO DEL INMUEBLE]                            NVARCHAR(MAX) NULL,
    [REPOSICIONES MUEBLES Y EQUIPOS]                        NVARCHAR(MAX) NULL,
    [CUOTAS DE ADMINISTRACIÓN ORDINARIAS]                   NVARCHAR(MAX) NULL,
    [CUOTAS DE ADMINISTRACIÓN EXTRAORDINARIAS]              NVARCHAR(MAX) NULL,
    [SERVICIOS PÚBLICOS]                                    NVARCHAR(MAX) NULL,
    [SEGUROS INMUEBLE]                                      NVARCHAR(MAX) NULL,
    [GARANTÍAS]                                             NVARCHAR(MAX) NULL,
    [DETALLE GARANTÍAS]                                     NVARCHAR(MAX) NULL,
    [COVENANTS]                                             NVARCHAR(MAX) NULL,
    [OTROSÍES]                                               DECIMAL(10,2) NULL,
    [FECHA OTROSÍ]                                           DECIMAL(18,4) NULL,
    [TIPO DE PERSONA]                                       NVARCHAR(255) NULL,
    [NIT ARRENDATARIO]                                      NVARCHAR(20)  NULL,
    [COD INMUEBLE]                                          DECIMAL(18,0) NULL,
    [COD_INMUEBLE_Nuevo]                                    DECIMAL(18,0) NULL,
    [INMUEBLE CONSOLIDADO]                                  NVARCHAR(255) NULL,
    [ENTIDAD ESTATAL]                                       NVARCHAR(255) NULL,
    [SE FACTURA CON IVA O NO]                               NVARCHAR(255) NULL,
    [OBSERVACIONES]                                         NVARCHAR(MAX) NULL,
    [ESTANDARIZAR ARCHIVOS DIGITALES]                       NVARCHAR(MAX) NULL,
    [MOBILIARIO Y OBRA BLANCA]                              NVARCHAR(MAX) NULL,
    [CANON DE MERCADO]                                      NVARCHAR(MAX) NULL,
    [SECTOR ECONÓMICO]                                      NVARCHAR(255) NULL,
    [VALIDACIÓN ÁREA DE CONTRATO ARRENDAMIENTO]             NVARCHAR(MAX) NULL,
    [DESCRIPCIÓN ANTIGUA]                                   NVARCHAR(255) NULL,
    [DIRECCIÓN]                                             NVARCHAR(255) NULL,
    [OBSERVACIONES REVISIÓN DE CONTRATO]                    NVARCHAR(MAX) NULL,
    CONSTRAINT [PK_tbl_Contratos_Detalle] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Contratos_Detalle_COD] ON [dbo].[tbl_Contratos_Detalle]([COD]);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Contratos_Detalle_NIT] ON [dbo].[tbl_Contratos_Detalle]([NIT ARRENDATARIO]);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Contratos_Detalle_COD_INM] ON [dbo].[tbl_Contratos_Detalle]([COD INMUEBLE]);
GO

/* ============================================================
   tbl_Contratos_Otros_Fondos  (~133 filas, fuente CONTRATOS_OTROS)

   Mismo shape resumido que tbl_Contratos, pero para contratos VIGENTE de
   OTROS FONDOS (no 351) -- verificado: ESTADO es siempre 'VIGENTE', el
   nombre de la tabla origen se refiere a otros fondos, no a otro estado.
   Tabla de referencia, sin FK (mismo criterio que 06_gastos_otros_raw.sql).
   ============================================================ */
CREATE TABLE [dbo].[tbl_Contratos_Otros_Fondos] (
    [Id]            INT IDENTITY(1,1) NOT NULL,
    [ESTADO]        NVARCHAR(30)  NULL,
    [COD_CTR]       NVARCHAR(20)  NULL,
    [NIT]           NVARCHAR(20)  NULL,
    [Nom_Arrend]    NVARCHAR(255) NULL,
    [Cod_Inm]       INT           NULL,
    [Nom_Inm]       NVARCHAR(255) NULL,
    [Det_Inm]       NVARCHAR(255) NULL,
    [GLA]           DECIMAL(18,2) NULL,
    [Tipologia]     NVARCHAR(255) NULL,
    [Fec_Inicio]    DATETIME2(0)  NULL,
    [Fec_Fin]       DATETIME2(0)  NULL,
    [IncremCanon]   NVARCHAR(255) NULL,
    CONSTRAINT [PK_tbl_Contratos_Otros_Fondos] PRIMARY KEY CLUSTERED ([Id])
);
GO

/* ============================================================
   tbl_Contratos_Restituidos_OtrosFondos  (~94 filas, fuente CONTRATOS_RESTITUIDOS)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Contratos_Restituidos_OtrosFondos] (
    [Id]            INT IDENTITY(1,1) NOT NULL,
    [FECHA]         DATETIME2(0)  NULL,
    [COD_CTR]       NVARCHAR(20)  NULL,
    [NIT]           NVARCHAR(20)  NULL,
    [Nom_Arrend]    NVARCHAR(255) NULL,
    [Cod_Inm]       INT           NULL,
    [Nom_Inm]       NVARCHAR(255) NULL,
    [Det_Inm]       NVARCHAR(255) NULL,
    [GLA]           DECIMAL(18,2) NULL,
    [Tipologia]     NVARCHAR(255) NULL,
    [UBICACION]     NVARCHAR(255) NULL,
    [Fec_Inicio]    DATETIME2(0)  NULL,
    [Fec_Fin]       DATETIME2(0)  NULL,
    [IncremCanon]   NVARCHAR(255) NULL,
    CONSTRAINT [PK_tbl_Contratos_Restituidos_OtrosFondos] PRIMARY KEY CLUSTERED ([Id])
);
GO

/* ============================================================
   tbl_Inmuebles_Estrategia  (~281 filas, fuente Inmuebles.xlsx hoja "Inm")

   Datos ESTRATEGICOS por inmueble (no historizados por fecha, a diferencia
   de tbl_Inmuebles). Sin FK a tbl_Inmuebles: alla la PK es compuesta
   (Fecha, Cod_Inm) historizada, aqui Cod_Inm es llave unica no historizada
   -- mismo tipo de brecha estructural ya documentado para tbl_Contratos.
   ============================================================ */
CREATE TABLE [dbo].[tbl_Inmuebles_Estrategia] (
    [Cod_Inm]           INT             NOT NULL,
    [Nom_Inm]           NVARCHAR(255)   NULL,
    [Desc_Inm]          NVARCHAR(255)   NULL,
    [Ubicacion]         NVARCHAR(255)   NULL,
    [Ubic_Pol_Inv]      NVARCHAR(255)   NULL,
    [Direccion]         NVARCHAR(255)   NULL,
    [Tipologia]         NVARCHAR(255)   NULL,
    [GLA]               DECIMAL(18,2)   NULL,
    [Estado]            NVARCHAR(255)   NULL,
    [Origen]            NVARCHAR(255)   NULL,
    [FechaVenta]        DATETIME2(0)    NULL,
    [ValorVenta]        DECIMAL(24,4)   NULL,
    [Georef]            NVARCHAR(500)   NULL,
    [Coordenadas]       NVARCHAR(255)   NULL,
    [Latitud]           FLOAT           NULL,
    [Longitud]          FLOAT           NULL,
    [En_PA]             NVARCHAR(10)    NULL,
    [Certificacion]     NVARCHAR(255)   NULL,
    [Estrategia]        NVARCHAR(255)   NULL,
    [Subtipologia]      NVARCHAR(255)   NULL,
    [Destinacion]       NVARCHAR(255)   NULL,
    [Operacion]         NVARCHAR(255)   NULL,
    [PlanCortoPlazo]    NVARCHAR(255)   NULL,
    [Riesgo]            NVARCHAR(255)   NULL,
    [Accion]            NVARCHAR(255)   NULL,
    CONSTRAINT [PK_tbl_Inmuebles_Estrategia] PRIMARY KEY CLUSTERED ([Cod_Inm])
);
GO

/* ============================================================
   tbl_Inmuebles_Compras  (~326 filas, fuente Inmuebles.xlsx hoja "Compras")

   Historial de compra -- un mismo inmueble puede tener varias filas
   (tranches de compra), de ahi el Id surrogate en vez de Cod_Inm como PK.
   ============================================================ */
CREATE TABLE [dbo].[tbl_Inmuebles_Compras] (
    [Id]                INT IDENTITY(1,1) NOT NULL,
    [Cod_Inm]           NVARCHAR(20)    NULL,
    [Cod_Inm_Nuevo]     INT             NULL,
    [Nom_Inm]           NVARCHAR(255)   NULL,
    [Tipologia]         NVARCHAR(255)   NULL,
    [FechaCompra]       DATETIME2(0)    NULL,
    [ValorCompra]       DECIMAL(24,4)   NULL,
    CONSTRAINT [PK_tbl_Inmuebles_Compras] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Inmuebles_Compras_Cod_Inm] ON [dbo].[tbl_Inmuebles_Compras]([Cod_Inm]);
GO

/* ============================================================
   tbl_MI  -- YA EXISTE (creada en 06_gastos_otros_raw.sql como tabla cruda
   sin PK/FK). Este archivo NO la recrea -- solo se agrega el indice que le
   faltaba, porque ahora tambien la puebla SIF_Colombia_Parametros (fuente:
   Parametros.accdb tbl_MI, version autoritativa/simple; la hoja "MI" de
   Inmuebles.xlsx es redundante y mas rica pero no se usa como fuente).
   ============================================================ */
CREATE NONCLUSTERED INDEX [IX_tbl_MI_COD_INM] ON [dbo].[tbl_MI]([COD_INM]);
GO

/* ============================================================
   tbl_Inmuebles_MI_Contratos  (~2.245 filas, fuente Inmuebles.xlsx hoja
   "MI Contratos")

   Cruce matricula <-> contrato <-> arrendatario por inmueble.
   ============================================================ */
CREATE TABLE [dbo].[tbl_Inmuebles_MI_Contratos] (
    [Id]                INT IDENTITY(1,1) NOT NULL,
    [Cod_Inm]           INT             NULL,
    [Cod_Contrato]      NVARCHAR(20)    NULL,
    [Arrendatario]      NVARCHAR(255)   NULL,
    [Matricula]         NVARCHAR(50)    NULL,
    [Descripcion]       NVARCHAR(255)   NULL,
    CONSTRAINT [PK_tbl_Inmuebles_MI_Contratos] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Inmuebles_MI_Contratos_Cod_Inm] ON [dbo].[tbl_Inmuebles_MI_Contratos]([Cod_Inm]);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Inmuebles_MI_Contratos_Cod_Contrato] ON [dbo].[tbl_Inmuebles_MI_Contratos]([Cod_Contrato]);
GO

/* ============================================================
   tbl_Inmuebles_Otros  (~19 filas, fuente Parametros.accdb tbl_Inmuebles_Otros)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Inmuebles_Otros] (
    [Cod_Inm]       INT             NOT NULL,
    [Nom_Inm]       NVARCHAR(255)   NULL,
    [Tipologia]     NVARCHAR(255)   NULL,
    CONSTRAINT [PK_tbl_Inmuebles_Otros] PRIMARY KEY CLUSTERED ([Cod_Inm])
);
GO
