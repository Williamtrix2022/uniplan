#!/usr/bin/env node
/**
 * cleanup-old-tasks.js
 * --------------------
 * Utilitario CLI one-off para hacer soft-delete de tareas antiguas completadas.
 *
 * Por qué existe:
 *   El backend corre en hosting serverless (Vercel) que NO sostiene un worker/cron
 *   entre requests, así que el job `cleanupOldTasks` del MVP no puede ejecutarse
 *   automáticamente. Este script permite invocarlo a demanda desde la línea de
 *   comandos (cron externo, GitHub Actions, trigger manual, etc.).
 *
 * Uso:
 *   node backend/scripts/cleanup-old-tasks.js                         # default = 90 días, dry-run = false
 *   node backend/scripts/cleanup-old-tasks.js --days 30              # tareas con fecha_entrega de hace ≥ 30 días
 *   node backend/scripts/cleanup-old-tasks.js --days 90 --dry-run    # sólo reporte, sin tocar la DB
 *   node backend/scripts/cleanup-old-tasks.js --help
 *
 * Reglas del modelo (Task.cleanupOld):
 *   - Solo tareas con `completada = TRUE` son elegibles (no tocamos pendientes).
 *   - Soft-delete únicamente (activo = FALSE); jamás hard-delete.
 *   - La transacción la hace el cliente del pool (sin necesidad de BEGIN/COMMIT para una sola UPDATE).
 */

'use strict';

require('dotenv').config();
const Task = require('../src/models/Task');

function parseArgs(argv) {
  const args = { days: 90, dryRun: false };

  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--help' || arg === '-h') {
      args.help = true;
    } else if (arg === '--dry-run') {
      args.dryRun = true;
    } else if (arg === '--days' && i + 1 < argv.length) {
      const value = argv[++i];
      const parsed = Number.parseInt(value, 10);
      if (!Number.isFinite(parsed) || parsed <= 0) {
        args.error = `--days debe ser un entero positivo (recibido: '${value}')`;
      } else {
        args.days = parsed;
      }
    } else {
      args.error = `Argumento no reconocido: '${arg}'`;
    }
  }

  return args;
}

function printHelp() {
  console.log(`
cleanup-old-tasks.js — soft-delete de tareas completadas con fecha_entrega antigua

Uso:
  node backend/scripts/cleanup-old-tasks.js [--days N] [--dry-run]

Opciones:
  --days N      antigüedad mínima en días respecto a fecha_entrega. Default: 90
  --dry-run     reporta candidatas sin modificar la base
  -h, --help    muestra esta ayuda

Ejemplos:
  node backend/scripts/cleanup-old-tasks.js --days 30
  node backend/scripts/cleanup-old-tasks.js --days 90 --dry-run
`.trim());
}

async function main() {
  const args = parseArgs(process.argv);

  if (args.help) {
    printHelp();
    process.exit(0);
  }
  if (args.error) {
    console.error(`❌ ${args.error}`);
    printHelp();
    process.exit(2);
  }

  console.log(`\n🔧 Limpieza de tareas antiguas`);
  console.log(`   Referencia: tareas con completada = TRUE y fecha_entrega ≤ hoy − ${args.days} días`);
  console.log(`   Modo: ${args.dryRun ? 'DRY-RUN (sin mutaciones)' : 'REAL (soft-delete)'}\n`);

  try {
    const result = await Task.cleanupOld({ daysOld: args.days, dryRun: args.dryRun });

    console.log('📊 Resultado:');
    console.log(`   Candidatas encontradas : ${result.candidates}`);
    console.log(`   Soft-deleted aplicadas  : ${result.softDeleted}`);
    console.log(`   Modo                    : ${result.dryRun ? 'dry-run' : 'real'}`);
    console.log(`   daysOld                 : ${result.daysOld}\n`);

    if (result.candidates > 0 && !result.dryRun) {
      console.log('✅ Limpieza ejecutada correctamente.\n');
    } else if (result.candidates === 0) {
      console.log('ℹ️  No había tareas que cumplieran el criterio. Nada que limpiar.\n');
    } else {
      console.log('ℹ️  Dry-run completado. Vuelve a ejecutar sin --dry-run para aplicar.\n');
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error ejecutando cleanup-old-tasks.js:', error.message);
    process.exit(1);
  }
}

main();
