/* ============================================================================
   00. Esquemas y tablas de control - poc_colombia

   Crea los 4 esquemas SQL usados en todo el modelo:
     - dbo: tablas de negocio (dimensiones, hechos).
     - stg: tablas de staging, mismo layout que su destino en dbo pero sin
       PK/FK/indices, usadas por el proceso de carga (ver 09_sp_etl.sql).
     - etl: procedimientos de carga masiva + bitacora de ejecucion.
     - app: procedimientos CRUD de dimensiones, pensados para que la futura
       API/front en React llame a estos SPs en vez de tocar las tablas
       directamente (permite aplicar reglas de negocio y auditoria en un
       solo lugar).
============================================================================ */

CREATE SCHEMA stg;
GO
CREATE SCHEMA etl;
GO
CREATE SCHEMA app;
GO

/* Bitacora de cada corrida de carga (ETL). Se llena desde etl.usp_RegistrarCarga. */
CREATE TABLE etl.tbl_Etl_Log (
    [Id]              INT             IDENTITY(1,1) NOT NULL,
    [TablaDestino]    SYSNAME         NOT NULL,
    [FechaEjecucion]  DATETIME2(0)    NOT NULL CONSTRAINT DF_tbl_Etl_Log_Fecha DEFAULT SYSDATETIME(),
    [FilasCargadas]   INT             NULL,
    [Resultado]       NVARCHAR(20)    NOT NULL, -- 'OK' / 'ERROR'
    [Mensaje]         NVARCHAR(MAX)   NULL,
    [Usuario]         NVARCHAR(128)   NOT NULL CONSTRAINT DF_tbl_Etl_Log_Usuario DEFAULT SUSER_SNAME(),
    CONSTRAINT [PK_etl_tbl_Etl_Log] PRIMARY KEY CLUSTERED ([Id])
);
GO

/* Auditoria generica de cambios hechos via los SPs de app.*. No usa triggers
   a proposito -- cada SP inserta explicitamente su propia fila, asi el costo
   de auditar es visible y controlado. */
CREATE TABLE dbo.tbl_Auditoria_Cambios (
    [Id]          BIGINT          IDENTITY(1,1) NOT NULL,
    [Tabla]       NVARCHAR(128)   NOT NULL,
    [Operacion]   CHAR(1)         NOT NULL CONSTRAINT CK_tbl_Auditoria_Operacion CHECK ([Operacion] IN ('I','U','D')),
    [PK_Valor]    NVARCHAR(400)   NULL,
    [Usuario]     NVARCHAR(128)   NOT NULL CONSTRAINT DF_tbl_Auditoria_Usuario DEFAULT SUSER_SNAME(),
    [Fecha]       DATETIME2(0)    NOT NULL CONSTRAINT DF_tbl_Auditoria_Fecha DEFAULT SYSDATETIME(),
    [Detalle]     NVARCHAR(MAX)   NULL,
    CONSTRAINT [PK_tbl_Auditoria_Cambios] PRIMARY KEY CLUSTERED ([Id])
);
GO
CREATE NONCLUSTERED INDEX [IX_tbl_Auditoria_Cambios_Tabla_Fecha] ON [dbo].[tbl_Auditoria_Cambios]([Tabla], [Fecha]);
GO
