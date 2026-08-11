/* Correr ANTES de 03_particiones.sql para confirmar que el servidor soporta
   particionamiento nativo (columna Fecha / RANGE RIGHT). */

SELECT
    SERVERPROPERTY('ProductVersion') AS Version,
    SERVERPROPERTY('ProductLevel')   AS ServicePack,
    SERVERPROPERTY('Edition')        AS Edition,
    SERVERPROPERTY('EngineEdition')  AS EngineEdition;

/* Como leer el resultado:
   - Version empieza en "14." o mas alto (SQL Server 2017+): particionamiento
     disponible en cualquier edicion (Standard, Web, Express incluidas). OK.
   - Version empieza en "13." (SQL Server 2016): se necesita ServicePack
     distinto de "RTM" (o sea SP1 o superior). Si dice "RTM", hay que aplicar
     el Service Pack antes de correr 03_particiones.sql, o usar el plan B
     documentado en README.md (vistas particionadas manuales con UNION ALL +
     CHECK constraints por año).
   - Version menor a "13.": particionamiento nativo no disponible en ninguna
     edicion -- usar el plan B del README.md. */
