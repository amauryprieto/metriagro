-- Minimal cacao KB for development/testing

BEGIN TRANSACTION;

-- Documents (chunks)
CREATE TABLE IF NOT EXISTS documents (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  section_path TEXT,
  category TEXT NOT NULL,
  crop TEXT NOT NULL,
  content TEXT NOT NULL,
  tokens_count INTEGER,
  embedding BLOB,
  embedding_norm REAL,
  updated_at INTEGER NOT NULL
);

-- FTS mirror (optional for test file; app may recreate virtual table)
-- For tests, we keep plain table only; the app can create FTS virtual table transiently if needed.

CREATE TABLE IF NOT EXISTS diseases (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  symptoms TEXT,
  causal_agent TEXT,
  management_summary TEXT
);

CREATE TABLE IF NOT EXISTS treatments (
  id TEXT PRIMARY KEY,
  target_type TEXT NOT NULL,
  target_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  steps_json TEXT,
  products_json TEXT,
  dosage TEXT,
  safety_notes TEXT,
  references TEXT
);

CREATE TABLE IF NOT EXISTS practices (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  objective TEXT,
  steps_json TEXT,
  notes TEXT
);

-- Seed minimal content
INSERT OR REPLACE INTO diseases(id, name, symptoms, causal_agent, management_summary) VALUES
 ('monilia_cacao','Moniliasis del cacao','Lesiones blanquecinas, momificación, caída de frutos','Moniliophthora roreri','Cosecha sanitaria, manejo de sombra, podas'),
 ('escoba_bruja','Escoba de bruja','Brotes hipertrofiados, escobas, deformaciones','Moniliophthora perniciosa','Poda sanitaria, eliminación de escobas, manejo de sombra');

INSERT OR REPLACE INTO practices(id, name, objective, steps_json, notes) VALUES
 ('cosecha_sanitaria','Cosecha sanitaria','Reducir inóculo',
  '["Recolectar frutos enfermos","Disponer residuos de forma segura","Evitar dispersión"]','Coordinar con manejo de sombra'),
 ('poda_ventilacion','Poda de ventilación','Mejorar aireación',
  '["Eliminar ramas sombreadoras","Mantener estructura del árbol","Retirar material infectado"]','Realizar en época seca');

INSERT OR REPLACE INTO treatments(id, target_type, target_id, title, description, steps_json, products_json, dosage, safety_notes, references) VALUES
 ('t_monilia_integrado','disease','monilia_cacao','Manejo integrado de moniliasis','Cosecha sanitaria y manejo de sombra; cobres preventivos',
  '["Remover frutos con síntomas","Podas para ventilación","Aplicaciones preventivas"]','["Cobre"]','Según etiqueta','Usar EPP','ICA cacao'),
 ('t_escoba_integrado','disease','escoba_bruja','Manejo integrado de escoba','Poda de escobas y manejo de sombra',
  '["Eliminar escobas","Desinfectar herramientas","Manejo de sombra"]','[]','N/A','Usar EPP','ICA cacao');

INSERT OR REPLACE INTO documents(id, title, section_path, category, crop, content, tokens_count, embedding, embedding_norm, updated_at) VALUES
 ('doc_monilia_1','Moniliasis - síntomas y manejo','Enfermedades > Moniliasis','enfermedad','cacao','Lesiones blanquecinas, momificación. Cosecha sanitaria y manejo de sombra son claves.',24,NULL,NULL,strftime('%s','now')*1000),
 ('doc_escoba_1','Escoba de bruja - síntomas y manejo','Enfermedades > Escoba de bruja','enfermedad','cacao','Escobas y deformaciones. Poda sanitaria y manejo de sombra reducen incidencia.',22,NULL,NULL,strftime('%s','now')*1000);

COMMIT;
