-- Add covering indexes for image-job foreign keys flagged by Supabase performance advisor.
CREATE INDEX IF NOT EXISTS idx_jib_ai_manager_image_jobs_product_id
  ON public.jib_ai_manager_image_jobs (product_id);

CREATE INDEX IF NOT EXISTS idx_jib_ai_manager_image_jobs_requested_by
  ON public.jib_ai_manager_image_jobs (requested_by);

CREATE INDEX IF NOT EXISTS idx_jib_ai_manager_image_jobs_reviewed_by
  ON public.jib_ai_manager_image_jobs (reviewed_by);
