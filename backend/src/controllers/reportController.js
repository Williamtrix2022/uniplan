// ============================================
// CONTROLADOR DE REPORTES (PROBLEMAS Y SUGERENCIAS)
// ============================================

const Report = require('../models/Report');

// Crear nuevo reporte
const createReport = async (req, res) => {
  try {
    const { modulo, mensaje } = req.body;
    const id_estudiante = req.user.id;

    const reportId = await Report.create({ id_estudiante, modulo, mensaje });
    const report = await Report.findById(reportId);

    res.status(201).json({
      success: true,
      message: 'Reporte enviado',
      data: report
    });

  } catch (error) {
    console.error('Error en createReport:', error);
    res.status(500).json({
      success: false,
      message: 'Error al enviar el reporte'
    });
  }
};

// Obtener los reportes del estudiante autenticado
const getMyReports = async (req, res) => {
  try {
    const id_estudiante = req.user.id;
    const { modulo } = req.query;
    const reports = await Report.findByStudent(id_estudiante, modulo ? { modulo } : {});

    res.json({
      success: true,
      count: reports.length,
      data: reports
    });

  } catch (error) {
    console.error('Error en getMyReports:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener los reportes'
    });
  }
};

module.exports = { createReport, getMyReports };
