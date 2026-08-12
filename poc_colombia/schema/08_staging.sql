/* ============================================================================
   08. Tablas de staging (esquema stg) - poc_colombia

   Mismo layout de columnas que su tabla destino en dbo, pero SIN PK/FK/
   CHECK/IDENTITY -- el proceso de carga (Python) hace TRUNCATE + bulk insert
   aqui sin preocuparse de validaciones, y etl.usp_ReemplazarDimension /
   etl.usp_CargarFactoParticionado (09_sp_etl.sql) se encargan de mover los
   datos a dbo con las validaciones correspondientes.

   stg.tbl_Centros omite [Id] (es IDENTITY en dbo, se genera al insertar).
============================================================================ */

CREATE TABLE [stg].[tbl_Fechas] (
    [Mes] DATETIME2(0) NULL, [Num_Mes] INT NULL, [Mes_Reporte] INT NULL,
    [Mostrar_Vista_Años] INT NULL, [Mostrar_Vista_Histórica] INT NULL, [Mostrar] INT NULL,
    [LTM] INT NULL, [YTD] INT NULL, [Nom_Mes] NVARCHAR(20) NULL, [Año] INT NULL,
    [Trimestre] NVARCHAR(10) NULL, [Mes_12M] DATETIME2(0) NULL, [Mes_YTD] DATETIME2(0) NULL,
    [Mes_TIR] DATETIME2(0) NULL, [Año_Seguros] DATETIME2(0) NULL, [Año_Otras cuentas] DATETIME2(0) NULL
);
GO
CREATE TABLE [stg].[tbl_Niveles] ([Cod_Nivel] INT NULL, [Nom_Nivel] NVARCHAR(255) NULL);
GO
CREATE TABLE [stg].[tbl_Tiempos] ([Cod_Tiempo] INT NULL, [Nom_Tiempo] NVARCHAR(255) NULL);
GO
CREATE TABLE [stg].[tbl_Fondos] (
    [COD_FONDO] INT NULL, [COD_FONDO_FIDU] INT NULL, [ABREV_FONDO] NVARCHAR(255) NULL,
    [NOM_CORTO_FONDO] NVARCHAR(255) NULL, [NOM_FONDO] NVARCHAR(500) NULL,
    [FIDU] NVARCHAR(255) NULL, [FONDO] NVARCHAR(255) NULL
);
GO
CREATE TABLE [stg].[tbl_Arrendatarios] (
    [NIT] NVARCHAR(20) NULL, [Nom_Arrend] NVARCHAR(255) NULL, [NomCorto_Arrend] NVARCHAR(255) NULL,
    [GRUPO_ECON] NVARCHAR(255) NULL, [Sector_Arrend] NVARCHAR(255) NULL,
    [Calif_Arrend] NVARCHAR(255) NULL, [Contacto_Arrend] NVARCHAR(255) NULL
);
GO
CREATE TABLE [stg].[tbl_Cuentas] (
    [Cod_Cuenta] INT NULL, [Cuenta] NVARCHAR(255) NULL, [Signo] INT NULL,
    [Agrupación] NVARCHAR(255) NULL, [Agrup_Gastos] INT NULL, [Cálculo] INT NULL,
    [Por inmueble] INT NULL, [Divisor] FLOAT NULL, [Suma] INT NULL,
    [Unidades] INT NULL, [Ranking_Inm] INT NULL, [Mostrar_pie] INT NULL,
    [Dispers_EjeX] INT NULL, [Dispers_EjeY] INT NULL, [Dispers_Burb] INT NULL
);
GO
CREATE TABLE [stg].[tbl_Totales] (
    [Cod_Nivel] INT NULL, [Cod_Total] NVARCHAR(10) NULL, [Nom_Total] NVARCHAR(255) NULL,
    [Cruce1] NVARCHAR(255) NULL, [Cruce2] NVARCHAR(255) NULL
);
GO
CREATE TABLE [stg].[tbl_Centros] (
    [Cod_Nivel] INT NULL, [Cod_Fondo] INT NULL, [Cod_Centro] NVARCHAR(20) NULL,
    [Nombre] NVARCHAR(255) NULL, [Tipologia] NVARCHAR(255) NULL, [Subtipologia] NVARCHAR(255) NULL,
    [Ubicacion] NVARCHAR(255) NULL, [Inmueble] NVARCHAR(255) NULL, [Arrendatario] NVARCHAR(255) NULL,
    [GRUPO_ECON] NVARCHAR(255) NULL, [Sector_Arrend] NVARCHAR(255) NULL, [Riesgo] NVARCHAR(255) NULL,
    [VENC_YR] INT NULL
);
GO
CREATE TABLE [stg].[tbl_Inmuebles] (
    [Fecha] DATETIME2(0) NULL, [Cod_Fondo] INT NULL, [Cod_Inm] DECIMAL(18,0) NULL,
    [Cod_Inm_Nue] DECIMAL(18,0) NULL, [Cod_Inm1] DECIMAL(18,0) NULL, [Cod_Inm1_Nue] DECIMAL(18,0) NULL,
    [Cod_Inm_TXT] NVARCHAR(255) NULL, [Nom_Inm] NVARCHAR(255) NULL, [Ubicacion] NVARCHAR(255) NULL,
    [Ubic_Pol_Inv] NVARCHAR(255) NULL, [Direccion] NVARCHAR(255) NULL, [Tipologia] NVARCHAR(255) NULL,
    [Tipologia_Cons] NVARCHAR(255) NULL, [Subtipologia] NVARCHAR(255) NULL, [Estado] NVARCHAR(255) NULL,
    [Tipo_Riesgo] NVARCHAR(255) NULL, [Georef] NVARCHAR(255) NULL, [Coordenadas] NVARCHAR(255) NULL,
    [Latitud] FLOAT NULL, [Longitud] FLOAT NULL, [Titularidad] NVARCHAR(255) NULL,
    [Subtipologia3] NVARCHAR(255) NULL, [Certificacion] NVARCHAR(255) NULL,
    [Año_de_contruccion] NVARCHAR(255) NULL, [Conteo] NVARCHAR(255) NULL
);
GO
CREATE TABLE [stg].[tbl_Contratos] (
    [FECHA] DATETIME2(0) NULL, [COD_FONDO] INT NULL, [ESTADO] NVARCHAR(30) NULL,
    [COD_CTR] NVARCHAR(20) NULL, [NIT] NVARCHAR(20) NULL, [NOM_ARREND] NVARCHAR(255) NULL,
    [COD_INM] DECIMAL(18,0) NULL, [DET_INM] NVARCHAR(255) NULL, [GLA] FLOAT NULL,
    [Tipologia] NVARCHAR(255) NULL, [Fec_Inicio] DATETIME2(0) NULL, [Fec_Fin] DATETIME2(0) NULL,
    [IncremCanon] NVARCHAR(255) NULL
);
GO

/* -- Facts "Valores" (mismo layout, ver 04_facts_valores.sql) -- */
CREATE TABLE [stg].[tbl_Valores] (
    [Fecha] DATETIME2(0) NULL, [Cod_Tiempo] INT NULL, [Cod_Fondo] INT NULL,
    [Cod_Nivel] INT NULL, [Cod_Centro] NVARCHAR(20) NULL, [Cod_Cuenta] INT NULL, [Valor] FLOAT NULL
);
GO
CREATE TABLE [stg].[tbl_Valores_Valor_Libros] (
    [Fecha] DATETIME2(0) NULL, [Cod_Tiempo] INT NULL, [Cod_Nivel] INT NULL,
    [Cod_Centro] NVARCHAR(20) NULL, [Cod_Cuenta] INT NULL, [Valor] FLOAT NULL
);
GO
CREATE TABLE [stg].[tbl_Valores_Gastos_Otros] (
    [Fecha] DATETIME2(0) NULL, [Cod_Tiempo] INT NULL, [Cod_Fondo] INT NULL, [Cod_Nivel] INT NULL,
    [Cod_Centro] NVARCHAR(20) NULL, [Cod_Cuenta] INT NULL, [Valor] FLOAT NULL
);
GO
CREATE TABLE [stg].[tbl_Valores_Gastos] (
    [Fecha] DATETIME2(0) NULL, [Cod_Tiempo] INT NULL, [Cod_Nivel] INT NULL,
    [Cod_Centro] NVARCHAR(20) NULL, [Cod_Cuenta] INT NULL, [Valor] FLOAT NULL
);
GO
CREATE TABLE [stg].[tbl_Valores_Avaluos] (
    [Fecha] DATETIME2(0) NULL, [Cod_Tiempo] INT NULL, [Cod_Nivel] INT NULL,
    [Cod_Centro] NVARCHAR(20) NULL, [Cod_Cuenta] INT NULL, [Valor] FLOAT NULL
);
GO
CREATE TABLE [stg].[tbl_Valores_Ingresos] (
    [Fecha] DATETIME2(0) NULL, [Cod_Tiempo] INT NULL, [Cod_Nivel] INT NULL,
    [Cod_Centro] NVARCHAR(20) NULL, [Cod_Cuenta] INT NULL, [Valor] FLOAT NULL
);
GO
CREATE TABLE [stg].[tbl_Valores_Nexus] (
    [Fecha] DATETIME2(0) NULL, [Cod_Tiempo] INT NULL, [Cod_Fondo] INT NULL, [Cod_Nivel] INT NULL,
    [Cod_Centro] NVARCHAR(20) NULL, [Cod_Cuenta] INT NULL, [Valor] FLOAT NULL
);
GO
CREATE TABLE [stg].[tbl_Valores_Viva_Malls] (
    [Fecha] DATETIME2(0) NULL, [Cod_Tiempo] INT NULL, [Cod_Nivel] INT NULL,
    [Cod_Centro] NVARCHAR(20) NULL, [Cod_Cuenta] INT NULL, [Valor] FLOAT NULL
);
GO
CREATE TABLE [stg].[tbl_Valores_GLA_2008_2023] (
    [Fecha] DATETIME2(0) NULL, [Cod_Tiempo] INT NULL, [Cod_Nivel] INT NULL,
    [Cod_Centro] NVARCHAR(20) NULL, [Cod_Cuenta] INT NULL, [Valor] FLOAT NULL
);
GO
CREATE TABLE [stg].[tbl_Valores_2011_2023_PYG] (
    [Fecha] DATETIME2(0) NULL, [Cod_Tiempo] INT NULL, [Cod_Nivel] INT NULL,
    [Cod_Centro] NVARCHAR(20) NULL, [Cod_Cuenta] INT NULL, [Valor] FLOAT NULL
);
GO
CREATE TABLE [stg].[tbl_Valores_2011_2023_VlrLibros] (
    [Fecha] DATETIME2(0) NULL, [Cod_Tiempo] INT NULL, [Cod_Nivel] INT NULL,
    [Cod_Centro] NVARCHAR(20) NULL, [Cod_Cuenta] INT NULL, [Valor] FLOAT NULL
);
GO
CREATE TABLE [stg].[tbl_Pagos_Inmuebles] (
    [Fecha] DATETIME2(0) NULL, [Fecha_TRN] DATETIME2(0) NULL, [Cod_Inm] DECIMAL(18,0) NULL,
    [Cod_Cuenta] INT NULL, [Valor] FLOAT NULL
);
GO

/* -- Submodelo EEFF 351 (ver 05_eeff_351.sql) -- */
CREATE TABLE [stg].[tbl_Cuentas_EEFF] (
    [COD_CTA] DECIMAL(18,0) NULL, [NOM_CTA] NVARCHAR(255) NULL, [SIGNO_CTA] INT NULL,
    [SIGNO_REPORTE] INT NULL, [TIPO_CTA] INT NULL, [SUMA] INT NULL, [Clasif_Contable] NVARCHAR(255) NULL,
    [COD_AGRUP] NVARCHAR(50) NULL, [NOM_AGRUP] NVARCHAR(255) NULL,
    [Cod_Nivel1] NVARCHAR(50) NULL, [Nom_Nivel1] NVARCHAR(255) NULL,
    [Cod_Nivel2] NVARCHAR(50) NULL, [Nom_Nivel2] NVARCHAR(255) NULL,
    [Cod_Nivel3] NVARCHAR(50) NULL, [Nom_Nivel3] NVARCHAR(255) NULL,
    [Cod_Nivel4] NVARCHAR(50) NULL, [Nom_Nivel4] NVARCHAR(255) NULL,
    [Cod_Nivel5] NVARCHAR(50) NULL, [Nom_Nivel5] NVARCHAR(255) NULL,
    [Cod_Nivel3A] NVARCHAR(50) NULL, [Nom_Nivel3A] NVARCHAR(255) NULL,
    [Cod_Nivel4A] NVARCHAR(50) NULL, [Nom_Nivel4A] NVARCHAR(255) NULL,
    [Cod_Nivel5A] NVARCHAR(50) NULL, [Nom_Nivel5A] NVARCHAR(255) NULL
);
GO
CREATE TABLE [stg].[tbl_EEFF] (
    [FECHA] DATETIME2(0) NULL, [COD_FONDO] INT NULL, [COD_CTA] DECIMAL(18,0) NULL,
    [NIT_TERCERO] DECIMAL(18,0) NULL, [SALDO] FLOAT NULL
);
GO
CREATE TABLE [stg].[F351] (
    [FECHA] DATETIME2(0) NULL, [INMUEBLE] NVARCHAR(255) NULL, [matrícula] NVARCHAR(50) NULL,
    [Unidad de Captura] FLOAT NULL, [No asignado por la entidad] FLOAT NULL,
    [Fecha emisión] FLOAT NULL, [Valor nominal] FLOAT NULL,
    [Valor de compra moneda original] FLOAT NULL, [Valor de compra en pesos] FLOAT NULL,
    [Vr mercado o valor presente en $] FLOAT NULL, [Campo11] NVARCHAR(255) NULL,
    [Campo12] FLOAT NULL, [Campo13] FLOAT NULL, [Campo14] FLOAT NULL, [F15] FLOAT NULL
);
GO
CREATE TABLE [stg].[VL_CentralPoint] (
    [FECHA] DATETIME2(0) NULL, [VLR_FINAL_E1] FLOAT NULL, [VLR_FINAL_E2] FLOAT NULL,
    [VLR_E1] FLOAT NULL, [VLR_E2] FLOAT NULL, [MVA] FLOAT NULL,
    [TOTAL_ACTIVOS_PA] FLOAT NULL, [PASIVO_PA] FLOAT NULL, [ANT_DF] FLOAT NULL,
    [TOTAL] FLOAT NULL, [351] FLOAT NULL, [DIF] FLOAT NULL,
    [UVR_E1] FLOAT NULL, [UVR_E2] FLOAT NULL, [UVR_E1_#2] FLOAT NULL,
    [UVR_E2_#2] FLOAT NULL, [AVAL_E1] FLOAT NULL, [AVAL_E2] FLOAT NULL,
    [VLR_AVAL_E1] FLOAT NULL, [VLR_AVAL_E2] FLOAT NULL
);
GO
CREATE TABLE [stg].[VL_Disp_xa_Venta] (
    [FECHA] DATETIME2(0) NULL, [COD_INM] DECIMAL(18,0) NULL, [DESCR_INM] NVARCHAR(255) NULL,
    [VALOR] FLOAT NULL
);
GO
CREATE TABLE [stg].[tbl_ValorLibros_xInmueble] (
    [DESCR] NVARCHAR(255) NULL, [FECHA] DATETIME2(0) NULL, [Cod_Inm] DECIMAL(18,0) NULL,
    [COD_CTA] DECIMAL(18,0) NULL, [VALOR] FLOAT NULL
);
GO
CREATE TABLE [stg].[tbl_Cruce_SIF] (
    [Cod_Cta] DECIMAL(18,0) NULL, [Nom_Cta] NVARCHAR(255) NULL, [Grupo_Cuenta] NVARCHAR(100) NULL,
    [NIT_Tercero] DECIMAL(18,0) NULL, [Nom_Tercero] NVARCHAR(255) NULL,
    [Cod_SIF] NVARCHAR(50) NULL, [Nom_SIF] NVARCHAR(255) NULL
);
GO
CREATE TABLE [stg].[tbl_Cruce351] (
    [COD_ASIGN_FIDU] DECIMAL(18,0) NULL, [Descripción351] NVARCHAR(100) NULL, [Cod_Inm] DECIMAL(18,0) NULL
);
GO
CREATE TABLE [stg].[tbl_Usuarios] ([Usuario] NVARCHAR(100) NULL);
GO
