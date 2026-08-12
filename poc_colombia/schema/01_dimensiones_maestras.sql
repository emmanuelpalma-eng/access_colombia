/* ============================================================================
   01. Dimensiones maestras - poc_colombia

   Estas tablas existen HOY duplicadas (con distinto grado de sincronizacion)
   en varias de las 6 fuentes Access (ver diagrama "SIF Colombia - Modelo
   General"). En el modelo consolidado son UNA sola tabla, sin duplicar por
   fuente -- ese es justamente el problema que este modelo busca resolver.

   IMPORTANTE: este script define la ESTRUCTURA correcta. No asume que los
   datos reales de los 6 Access ya cumplen estas reglas (algunos NO las
   cumplen hoy -- ver conteos de filas distintos entre fuentes). La
   reconciliacion de datos es un problema de carga/ETL, no de diseño, y se
   resuelve en una fase posterior.
============================================================================ */

/* ============================================================
   tbl_Fechas  (calendario de fin de mes)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Fechas] (
    [Mes]                       DATETIME2(0)    NOT NULL,
    [Num_Mes]                   INT             NULL,
    [Mes_Reporte]               INT             NULL,
    [Mostrar_Vista_Años]        INT             NULL,
    [Mostrar_Vista_Histórica]   INT             NULL,
    [Mostrar]                   INT             NULL,
    [LTM]                       INT             NULL,
    [YTD]                       INT             NULL,
    [Nom_Mes]                   NVARCHAR(20)    NULL,
    [Año]                       INT             NULL,
    [Trimestre]                 NVARCHAR(10)    NULL,
    [Mes_12M]                   DATETIME2(0)    NULL,
    [Mes_YTD]                   DATETIME2(0)    NULL,
    [Mes_TIR]                   DATETIME2(0)    NULL,
    [Año_Seguros]               DATETIME2(0)    NULL,
    [Año_Otras cuentas]         DATETIME2(0)    NULL,
    CONSTRAINT [PK_tbl_Fechas] PRIMARY KEY CLUSTERED ([Mes])
);
GO

/* ============================================================
   tbl_Niveles  (niveles de la jerarquia de tbl_Centros: arrendatario,
   centro, ciudad, sector, grupo economico, etc.)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Niveles] (
    [Cod_Nivel]     INT             NOT NULL,
    [Nom_Nivel]     NVARCHAR(255)   NULL,
    CONSTRAINT [PK_tbl_Niveles] PRIMARY KEY CLUSTERED ([Cod_Nivel])
);
GO

/* ============================================================
   tbl_Tiempos  (tipo de periodo: Mes / Ultimos 12 meses / Acumulado año)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Tiempos] (
    [Cod_Tiempo]    INT             NOT NULL,
    [Nom_Tiempo]    NVARCHAR(255)   NULL,
    CONSTRAINT [PK_tbl_Tiempos] PRIMARY KEY CLUSTERED ([Cod_Tiempo])
);
GO

/* ============================================================
   tbl_Fondos  (fondos/vehiculos de inversion)
   COD_FONDO se tipifica INT (no DECIMAL) a proposito -- con solo ~15 fondos
   un INT es exacto y permite que sea FK-able sin friccion desde
   tbl_Centros/tbl_Inmuebles/tbl_Contratos/tbl_EEFF/tbl_Valores*.

   IMPORTANTE: se agrega manualmente una fila COD_FONDO=0 ("No aplica /
   Consolidado") ademas de las ~15 filas reales de PowerBI -- varias fuentes
   usan 0 como centinela para filas que no son especificas de un fondo (ej.
   niveles de rollup en tbl_Centros). Sin esta fila placeholder, la FK desde
   esas tablas falla en cascada. Ver SIF_Colombia_PowerBI/import_dimensiones.py.
   ============================================================ */
CREATE TABLE [dbo].[tbl_Fondos] (
    [COD_FONDO]         INT             NOT NULL,
    [COD_FONDO_FIDU]    INT             NULL,
    [ABREV_FONDO]       NVARCHAR(255)   NULL,
    [NOM_CORTO_FONDO]   NVARCHAR(255)   NULL,
    [NOM_FONDO]         NVARCHAR(500)   NULL,
    [FIDU]              NVARCHAR(255)   NULL,
    [FONDO]             NVARCHAR(255)   NULL,
    CONSTRAINT [PK_tbl_Fondos] PRIMARY KEY CLUSTERED ([COD_FONDO])
);
GO

/* ============================================================
   tbl_Arrendatarios  (catalogo de arrendatarios/inquilinos)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Arrendatarios] (
    [NIT]               NVARCHAR(20)    NOT NULL,
    [Nom_Arrend]        NVARCHAR(255)   NULL,
    [NomCorto_Arrend]   NVARCHAR(255)   NULL,
    [GRUPO_ECON]        NVARCHAR(255)   NULL,
    [Sector_Arrend]     NVARCHAR(255)   NULL,
    [Calif_Arrend]      NVARCHAR(255)   NULL,
    [Contacto_Arrend]   NVARCHAR(255)   NULL,
    CONSTRAINT [PK_tbl_Arrendatarios] PRIMARY KEY CLUSTERED ([NIT])
);
GO

/* ============================================================
   tbl_Cuentas  (catalogo de cuentas de GESTION DE PORTAFOLIO -- distinto
   del catalogo contable EEFF de la fuente 351, ver 05_eeff_351.sql)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Cuentas] (
    [Cod_Cuenta]        INT             NOT NULL,
    [Cuenta]            NVARCHAR(255)   NULL,
    [Signo]             INT             NULL,
    [Agrupación]        NVARCHAR(255)   NULL,
    [Agrup_Gastos]      INT             NULL,
    [Cálculo]           INT             NULL,
    [Por inmueble]      INT             NULL,
    [Divisor]           DECIMAL(12,2)   NULL CONSTRAINT CK_tbl_Cuentas_Divisor CHECK ([Divisor] BETWEEN 0.01 AND 1000000),
    [Suma]              INT             NULL,
    [Unidades]          INT             NULL,
    [Ranking_Inm]       INT             NULL,
    [Mostrar_pie]       INT             NULL,
    [Dispers_EjeX]      INT             NULL,
    [Dispers_EjeY]      INT             NULL,
    [Dispers_Burb]      INT             NULL,
    CONSTRAINT [PK_tbl_Cuentas] PRIMARY KEY CLUSTERED ([Cod_Cuenta])
);
GO

/* ============================================================
   tbl_Totales  (definicion de subtotales/rollups por nivel)
   ============================================================ */
CREATE TABLE [dbo].[tbl_Totales] (
    [Cod_Nivel]     INT             NOT NULL,
    [Cod_Total]     NVARCHAR(10)    NOT NULL,
    [Nom_Total]     NVARCHAR(255)   NULL,
    [Cruce1]        NVARCHAR(255)   NULL,
    [Cruce2]        NVARCHAR(255)   NULL,
    CONSTRAINT [PK_tbl_Totales] PRIMARY KEY CLUSTERED ([Cod_Nivel], [Cod_Total]),
    CONSTRAINT [FK_tbl_Totales_tbl_Niveles]
        FOREIGN KEY ([Cod_Nivel]) REFERENCES [dbo].[tbl_Niveles]([Cod_Nivel])
);
GO

/* ============================================================
   tbl_Centros  (jerarquia/rollup de centros -- el mismo Cod_Centro se
   reutiliza en cada Cod_Nivel: arrendatario, centro comercial, ciudad,
   sector, grupo economico son "niveles" distintos que comparten el mismo
   codigo de centro). NO tiene llave natural 100% unica por diseño del
   negocio (un mismo Cod_Nivel+Cod_Centro puede tener una fila de
   arrendatario real y una fila "VACANTE" simultaneas) -- se usa un PK
   subrogado IDENTITY, mismo criterio ya validado en Info Portafolio.
   ============================================================ */
CREATE TABLE [dbo].[tbl_Centros] (
    [Id]                INT             IDENTITY(1,1) NOT NULL,
    [Cod_Nivel]         INT             NOT NULL,
    [Cod_Fondo]         INT             NULL,
    [Cod_Centro]        NVARCHAR(20)    NOT NULL,
    [Nombre]            NVARCHAR(255)   NULL,
    [Tipologia]         NVARCHAR(255)   NULL,
    [Subtipologia]      NVARCHAR(255)   NULL,
    [Ubicacion]         NVARCHAR(255)   NULL,
    [Inmueble]          NVARCHAR(255)   NULL,
    [Arrendatario]      NVARCHAR(255)   NULL,
    [GRUPO_ECON]        NVARCHAR(255)   NULL,
    [Sector_Arrend]     NVARCHAR(255)   NULL,
    [Riesgo]            NVARCHAR(255)   NULL,
    [VENC_YR]           INT             NULL,
    CONSTRAINT [PK_tbl_Centros] PRIMARY KEY CLUSTERED ([Id]),
    CONSTRAINT [FK_tbl_Centros_tbl_Niveles]
        FOREIGN KEY ([Cod_Nivel]) REFERENCES [dbo].[tbl_Niveles]([Cod_Nivel]),
    CONSTRAINT [FK_tbl_Centros_tbl_Fondos]
        FOREIGN KEY ([Cod_Fondo]) REFERENCES [dbo].[tbl_Fondos]([COD_FONDO])
);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Centros_Cod_Nivel_Cod_Centro] ON [dbo].[tbl_Centros]([Cod_Nivel], [Cod_Centro]);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Centros_Arrendatario] ON [dbo].[tbl_Centros]([Arrendatario]);
GO
