-- Marca el partido como finalizado automáticamente cuando se ingresan resultados
CREATE OR REPLACE FUNCTION set_estado_finalizado()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.goles_local IS NOT NULL AND NEW.goles_visita IS NOT NULL THEN
    NEW.estado := 'finalizado';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_finalizado_elim
  BEFORE UPDATE ON partidos_elim
  FOR EACH ROW EXECUTE FUNCTION set_estado_finalizado();

-- partidos_g no existe en este proyecto (solo fase de grupos no aplica)
