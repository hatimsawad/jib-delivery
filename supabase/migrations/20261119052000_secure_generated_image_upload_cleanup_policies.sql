-- Permit cleanup of failed generated uploads without widening access to other stores.
-- Admins may upload/delete product images when handling an authorized support workflow.
DROP POLICY IF EXISTS "JIB merchants upload product images for their own stores" ON storage.objects;
CREATE POLICY "JIB merchants and admins upload product images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'product-images'
  AND (
    (SELECT public.is_jib_admin())
    OR EXISTS (
      SELECT 1
      FROM public.stores s
      WHERE s.owner_id = auth.uid()
        AND s.id::text = split_part(objects.name, '/', 1)
    )
  )
);

CREATE POLICY "JIB merchants and admins delete product images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'product-images'
  AND (
    (SELECT public.is_jib_admin())
    OR EXISTS (
      SELECT 1
      FROM public.stores s
      WHERE s.owner_id = auth.uid()
        AND s.id::text = split_part(objects.name, '/', 1)
    )
  )
);

CREATE POLICY "JIB admins delete article images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'article-images'
  AND (SELECT public.is_jib_admin())
);
