// ============================================
// CONTROLADOR DE DASHBOARD
// ============================================

const Subject = require('../models/Subject');
const Task = require('../models/Task');
const Note = require('../models/Note');
const Pomodoro = require('../models/Pomodoro');
const Calendar = require('../models/Calendar');

// Dashboard principal con resumen general
const getDashboard = async (req, res) => {
  try {
    const id_estudiante = req.user.id;

    // Obtener todas las estadísticas en paralelo
    const [
      subjectStats,
      taskStats,
      noteStats,
      pomodoroStatsWeek,
      pomodoroStatsToday,
      calendarStats,
      upcomingTasks,
      todayEvents,
      pomodoroBySubject
    ] = await Promise.all([
      Subject.getStats(id_estudiante),
      Task.getStats(id_estudiante),
      Note.getStats(id_estudiante),
      Pomodoro.getStats(id_estudiante, 'week'),
      Pomodoro.getStats(id_estudiante, 'today'),
      Calendar.getStats(id_estudiante),
      Task.getUpcoming(id_estudiante),
      Calendar.getToday(id_estudiante),
      Pomodoro.getBySubject(id_estudiante)
    ]);

    // Calcular porcentaje de productividad
    const productividadSemanal = taskStats.total_tareas > 0 
      ? Math.round((taskStats.completadas / taskStats.total_tareas) * 100)
      : 0;

    res.json({
      success: true,
      data: {
        resumen: {
          materias: subjectStats,
          tareas: taskStats,
          notas: noteStats,
          calendario: calendarStats,
          productividad_semanal: productividadSemanal
        },
        pomodoro: {
          hoy: pomodoroStatsToday,
          semana: pomodoroStatsWeek,
          por_materia: pomodoroBySubject
        },
        proximas_actividades: {
          tareas: upcomingTasks,
          eventos_hoy: todayEvents
        }
      }
    });

  } catch (error) {
    console.error('Error en getDashboard:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener dashboard',
      error: error.message
    });
  }
};

// Resumen de actividad semanal
const getWeeklySummary = async (req, res) => {
  try {
    const id_estudiante = req.user.id;

    const [
      pomodoroByDay,
      weekEvents,
      upcomingTasks
    ] = await Promise.all([
      Pomodoro.getByDay(id_estudiante),
      Calendar.getWeek(id_estudiante),
      Task.getUpcoming(id_estudiante)
    ]);

    res.json({
      success: true,
      data: {
        estudio_por_dia: pomodoroByDay,
        eventos_semana: weekEvents,
        tareas_proximas: upcomingTasks
      }
    });

  } catch (error) {
    console.error('Error en getWeeklySummary:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener resumen semanal',
      error: error.message
    });
  }
};

// Resumen de hoy
const getTodaySummary = async (req, res) => {
  try {
    const id_estudiante = req.user.id;

    const [
      todaySessions,
      todayEvents,
      pendingTasks
    ] = await Promise.all([
      Pomodoro.getToday(id_estudiante),
      Calendar.getToday(id_estudiante),
      Task.findByStudent(id_estudiante, { estado: 'pendiente' })
    ]);

    // Calcular minutos estudiados hoy
    const minutosHoy = todaySessions.reduce((total, session) => 
      total + (session.tiempo_total_estudio || 0), 0
    );

    res.json({
      success: true,
      data: {
        minutos_estudiados: minutosHoy,
        sesiones_pomodoro: todaySessions.length,
        eventos: todayEvents,
        tareas_pendientes: pendingTasks.filter(t => 
          new Date(t.fecha_entrega).toDateString() === new Date().toDateString()
        )
      }
    });

  } catch (error) {
    console.error('Error en getTodaySummary:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener resumen de hoy',
      error: error.message
    });
  }
};

module.exports = {
  getDashboard,
  getWeeklySummary,
  getTodaySummary
};